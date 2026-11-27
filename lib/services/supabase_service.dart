import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  bool _initialized = false;
  bool get isInitialized => _initialized;

  SupabaseClient? _mockClient;
  @visibleForTesting
  set mockClient(SupabaseClient? client) => _mockClient = client;

  @visibleForTesting
  set initializedForTesting(bool val) => _initialized = val;

  User? _mockCurrentUser;
  @visibleForTesting
  set mockCurrentUser(User? user) => _mockCurrentUser = user;

  @visibleForTesting
  Future<void> Function()? signOutHandler;

  bool get _hasSupabaseInstance {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get client {
    if (_mockClient != null) return _mockClient!;
    if (!_initialized) {
      throw StateError('Supabase has not been initialized. Please provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    return Supabase.instance.client;
  }

  User? get currentUser {
    if (_mockCurrentUser != null) return _mockCurrentUser;
    if (!_initialized || (!_hasSupabaseInstance && _mockClient == null)) return null;
    return client.auth.currentUser;
  }
  bool get isAuthenticated => currentUser != null;

  static Future<void> initialize({String? url, String? anonKey}) async {
    final effectiveUrl = url ?? supabaseUrl;
    final effectiveKey = anonKey ?? supabaseAnonKey;

    if (effectiveUrl.isEmpty || effectiveKey.isEmpty) {
      debugPrint('Supabase credentials not supplied via --dart-define or .env. Running in offline/unconfigured mode.');
      return;
    }

    var cleanUrl = effectiveUrl.trim();
    cleanUrl = cleanUrl.replaceAll(RegExp(r'/rest/v1/?$'), '');
    cleanUrl = cleanUrl.replaceAll(RegExp(r'/+$'), '');

    try {
      await Supabase.initialize(
        url: cleanUrl,
        anonKey: effectiveKey.trim(),
      );
      instance._initialized = true;
      debugPrint('Supabase initialized successfully with $cleanUrl');
    } catch (e) {
      debugPrint('Failed to initialize Supabase: $e');
    }
  }

  /// Register with full name, email, and password.
  /// Creates a Supabase Auth user AND a row in the public.profiles table.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );

    final user = response.user;
    if (user != null) {
      try {
        await createProfile(
          userId: user.id,
          displayName: displayName.trim(),
        );
      } catch (e) {
        debugPrint('Direct profile creation note (handled by trigger/policy): $e');
      }
    }

    return response;
  }

  /// Creates a profile row for the newly registered student.
  Future<void> createProfile({
    required String userId,
    required String displayName,
    List<String>? subjects,
    int level = 1,
  }) async {
    final initials = _extractInitials(displayName);
    await client.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'subjects': subjects ?? ['Calculus', 'Biology'],
      'level': level,
      'avatar_initials': initials,
    });
  }

  /// Fetch profile for a given user id.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  /// Log in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Update profile row for a given user id.
  ///
  /// Honest limitation:
  /// The public.profiles SELECT RLS policy is broad (using (true) - any
  /// authenticated user can read profile rows). Setting hidden_from_search to
  /// true hides the user from Find Users SEARCH RESULTS only; it does not make
  /// the row unreadable by direct ID lookup.
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    List<String>? subjects,
    bool? hiddenFromSearch,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['display_name'] = displayName.trim();
      data['avatar_initials'] = _extractInitials(displayName);
    }
    if (subjects != null) {
      data['subjects'] = subjects;
    }
    if (hiddenFromSearch != null) {
      data['hidden_from_search'] = hiddenFromSearch;
    }
    if (data.isNotEmpty) {
      await client.from('profiles').update(data).eq('id', userId);
    }
  }

  /// Change password for currently authenticated user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email != null) {
      // Verify current password by signing in
      await client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    }
    // Update to new password
    await client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Optional hook for testing Edge Function invocations without network calls.
  @visibleForTesting
  Future<FunctionResponse> Function(String functionName, {Map<String, dynamic>? body})? functionsInvoker;

  /// Delete account data for a given user id.
  /// Cleans up public schema tables before invoking the delete-account
  /// Edge Function to delete the auth.users identity, and finally signs out.
  Future<void> deleteAccount(String userId) async {
    if (_initialized) {
      if (_mockClient != null || _hasSupabaseInstance) {
        try {
          await client.from('quiz_scores').delete().eq('user_id', userId);
        } catch (_) {}
        try {
          await client.from('group_members').delete().eq('user_id', userId);
        } catch (_) {}
        try {
          await client.from('group_messages').delete().eq('sender_id', userId);
        } catch (_) {}
        try {
          await client.from('group_invites').delete().eq('invitee_id', userId);
        } catch (_) {}
        try {
          await client.from('group_invites').delete().eq('inviter_id', userId);
        } catch (_) {}
        try {
          await client.from('profiles').delete().eq('id', userId);
        } catch (_) {}
      }

      // Call the delete-account Supabase Edge Function to delete auth.users identity
      final response = functionsInvoker != null
          ? await functionsInvoker!('delete-account', body: {'userId': userId})
          : await client.functions.invoke(
              'delete-account',
              body: {'userId': userId},
            );

      if (response.status < 200 || response.status >= 300) {
        throw Exception(
          'Failed to delete user identity in auth.users via delete-account function: status ${response.status}',
        );
      }
    }
    await signOut();
  }

  /// Send password reset link to user email.
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email.trim());
  }

  /// Sign out current user.
  Future<void> signOut() async {
    if (signOutHandler != null) {
      await signOutHandler!();
      return;
    }
    if (_initialized && currentUser != null && (_mockClient != null || _hasSupabaseInstance)) {
      await client.auth.signOut();
    }
  }

  static String _extractInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'SN';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
