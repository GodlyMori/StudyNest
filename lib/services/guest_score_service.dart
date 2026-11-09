import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class GuestScoreService {
  static const String _guestScoresKey = 'guest_quiz_scores';
  static const String _userScoresPrefix = 'user_quiz_scores_';

  /// Save a completed quiz score while in guest mode.
  static Future<void> saveGuestScore({
    required String subject,
    required int score,
    required String grade,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getGuestScores();
    final newScore = {
      'subject': subject,
      'score': score,
      'grade': grade,
      'date': DateTime.now().toIso8601String(),
    };
    existing.add(newScore);
    await prefs.setString(_guestScoresKey, jsonEncode(existing));
    debugPrint('Saved guest score for $subject: $score% ($grade)');
  }

  /// Retrieve all local scores saved while acting as a guest.
  static Future<List<Map<String, dynamic>>> getGuestScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestScoresKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error decoding guest scores: $e');
      return [];
    }
  }

  /// Clears stored guest scores after migration.
  static Future<void> clearGuestScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestScoresKey);
  }

  /// Migrates all guest quiz scores to the newly registered Supabase account.
  /// Guarantees that nothing is lost when a guest creates an account.
  static Future<int> migrateGuestScoresToAccount(String userId) async {
    final guestScores = await getGuestScores();
    if (guestScores.isEmpty) return 0;

    final prefs = await SharedPreferences.getInstance();
    // Persist under the user ID locally so history immediately renders
    final userKey = '$_userScoresPrefix$userId';
    final userExistingRaw = prefs.getString(userKey);
    List<Map<String, dynamic>> userScores = [];
    if (userExistingRaw != null && userExistingRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(userExistingRaw) as List;
        userScores = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    userScores.addAll(guestScores);
    await prefs.setString(userKey, jsonEncode(userScores));

    // If Supabase is connected, sync to the quiz_scores table
    if (SupabaseService.instance.isInitialized) {
      try {
        final rows = guestScores.map((s) => {
          'user_id': userId,
          'subject': s['subject'],
          'score': s['score'],
          'grade': s['grade'],
          'created_at': s['date'] ?? DateTime.now().toIso8601String(),
        }).toList();

        await SupabaseService.instance.client.from('quiz_scores').insert(rows);
        debugPrint('Successfully synced ${rows.length} guest scores to Supabase quiz_scores table.');
      } catch (e) {
        debugPrint('Supabase quiz_scores sync (optional table): $e');
      }
    }

    // Clear guest scores now that they are attached to the registered account
    await clearGuestScores();
    return guestScores.length;
  }

  /// Get scores for a registered user (or fallback to guest scores if not logged in).
  static Future<List<Map<String, dynamic>>> getScoresForUser({String? userId}) async {
    if (userId == null) {
      return getGuestScores();
    }
    final prefs = await SharedPreferences.getInstance();
    final userKey = '$_userScoresPrefix$userId';
    final raw = prefs.getString(userKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }
}
