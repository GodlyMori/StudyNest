import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ml/bkt_mastery.dart';
import '../ml/mastery_store.dart';
import '../ml/question_attempt.dart';
import 'attempt_sync_service.dart';
import 'network_service.dart';
import 'supabase_service.dart';

/// [MasteryStorage] backed by [SharedPreferences] for on-device caching.
class SharedPreferencesMasteryStorage implements MasteryStorage {
  static const String guestMasteryKey = 'guest_topic_mastery';
  static const String userMasteryPrefix = 'user_topic_mastery_';

  String _keyForUser(String? userId) =>
      userId == null ? guestMasteryKey : '$userMasteryPrefix$userId';

  @override
  Future<Map<String, TopicMastery>> loadTopicMasteries(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForUser(userId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map;
      final result = <String, TopicMastery>{};
      decoded.forEach((k, v) {
        result[k as String] = TopicMastery.fromJson(
          Map<String, dynamic>.from(v as Map),
        );
      });
      return result;
    } catch (e) {
      debugPrint('Error decoding topic mastery for $userId: $e');
      return {};
    }
  }

  @override
  Future<void> saveTopicMasteries(
    String? userId,
    Map<String, TopicMastery> masteries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(userId);
    if (masteries.isEmpty) {
      await prefs.remove(key);
      return;
    }
    final encoded = masteries.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(key, jsonEncode(encoded));
  }
}

/// [MasteryRemoteSink] backed by Supabase `topic_mastery` table.
class SupabaseMasteryRemoteSink implements MasteryRemoteSink {
  @override
  bool get isReady => SupabaseService.instance.isInitialized;

  @override
  Future<List<TopicMastery>> fetchTopicMasteries(String userId) async {
    final rows = await SupabaseService.instance.client
        .from('topic_mastery')
        .select()
        .eq('user_id', userId);
    return (rows as List)
        .map((r) => TopicMastery.fromSupabaseRow(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  @override
  Future<void> upsertTopicMasteries(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await SupabaseService.instance.client
        .from('topic_mastery')
        .upsert(rows, onConflict: 'user_id,subject,topic');
  }
}

/// App-level singleton wiring [MasteryTracker] to SharedPreferences,
/// NetworkService, and SupabaseService.
class MasteryService {
  MasteryService._();

  static final MasteryTracker tracker = MasteryTracker(
    storage: SharedPreferencesMasteryStorage(),
    remoteSink: SupabaseMasteryRemoteSink(),
    isOnline: NetworkService.isOnline,
    getCurrentUserId: () => SupabaseService.instance.currentUser?.id,
  );

  /// Loads topic masteries, rebuilding chronologically from `question_attempts`
  /// (local cache, or remote Supabase if local is empty) when `topic_mastery` is empty.
  static Future<Map<String, TopicMastery>> loadOrRebuildMasteries() async {
    final userId = SupabaseService.instance.currentUser?.id;
    var attempts = await AttemptSyncService.logger.getAttempts(userId: userId);

    if (attempts.isEmpty &&
        userId != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = await SupabaseService.instance.client
            .from('question_attempts')
            .select()
            .eq('user_id', userId)
            .order('answered_at', ascending: true);
        attempts = (rows as List)
            .map((r) => QuestionAttempt.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error fetching question_attempts for mastery rebuild: $e');
      }
    }

    return tracker.getMasteries(
      userId: userId,
      fallbackAttempts: attempts,
    );
  }
}
