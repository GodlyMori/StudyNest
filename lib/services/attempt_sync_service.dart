import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ml/attempt_logger.dart';
import '../ml/question_attempt.dart';
import 'network_service.dart';
import 'supabase_service.dart';

/// [AttemptStorage] backed by [SharedPreferences] for on-device persistence.
class SharedPreferencesAttemptStorage implements AttemptStorage {
  static const String guestAttemptsKey = 'guest_question_attempts';
  static const String outboxKey = 'question_attempts_outbox';
  static const String userAttemptsPrefix = 'user_question_attempts_';

  Future<List<QuestionAttempt>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => QuestionAttempt.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error decoding question attempts for $key: $e');
      return [];
    }
  }

  Future<void> _writeList(String key, List<QuestionAttempt> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    if (attempts.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      jsonEncode(attempts.map((a) => a.toJson()).toList()),
    );
  }

  @override
  Future<List<QuestionAttempt>> loadGuestAttempts() =>
      _readList(guestAttemptsKey);

  @override
  Future<void> saveGuestAttempts(List<QuestionAttempt> attempts) =>
      _writeList(guestAttemptsKey, attempts);

  @override
  Future<List<QuestionAttempt>> loadOutbox() => _readList(outboxKey);

  @override
  Future<void> saveOutbox(List<QuestionAttempt> attempts) =>
      _writeList(outboxKey, attempts);

  @override
  Future<List<QuestionAttempt>> loadUserAttempts(String userId) =>
      _readList('$userAttemptsPrefix$userId');

  @override
  Future<void> saveUserAttempts(
    String userId,
    List<QuestionAttempt> attempts,
  ) =>
      _writeList('$userAttemptsPrefix$userId', attempts);
}

/// [AttemptRemoteSink] backed by Supabase `question_attempts` table.
class SupabaseAttemptRemoteSink implements AttemptRemoteSink {
  @override
  bool get isReady => SupabaseService.instance.isInitialized;

  @override
  Future<void> upsertAttempts(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await SupabaseService.instance.client
        .from('question_attempts')
        .upsert(rows, onConflict: 'id', ignoreDuplicates: true);
  }
}

/// App-level singleton wiring [AttemptLogger] to SharedPreferences,
/// NetworkService, and SupabaseService.
class AttemptSyncService {
  AttemptSyncService._();

  static final AttemptLogger logger = AttemptLogger(
    storage: SharedPreferencesAttemptStorage(),
    remoteSink: SupabaseAttemptRemoteSink(),
    isOnline: NetworkService.isOnline,
    getCurrentUserId: () => SupabaseService.instance.currentUser?.id,
  );
}
