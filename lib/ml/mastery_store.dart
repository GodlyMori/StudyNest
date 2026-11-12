import 'bkt_mastery.dart';
import 'question_attempt.dart';
import 'sm2_scheduler.dart';

/// Storage abstraction for per-topic mastery caching (guest + signed-in user).
abstract class MasteryStorage {
  Future<Map<String, TopicMastery>> loadTopicMasteries(String? userId);
  Future<void> saveTopicMasteries(
    String? userId,
    Map<String, TopicMastery> masteries,
  );
}

/// Remote sink abstraction for persisting and fetching `topic_mastery` rows.
abstract class MasteryRemoteSink {
  bool get isReady;
  Future<List<TopicMastery>> fetchTopicMasteries(String userId);
  Future<void> upsertTopicMasteries(List<Map<String, dynamic>> rows);
}

/// In-memory [MasteryStorage] for fast, pure-Dart unit tests.
class InMemoryMasteryStorage implements MasteryStorage {
  final Map<String, Map<String, TopicMastery>> _store = {};

  String _bucket(String? userId) => userId ?? '__guest__';

  @override
  Future<Map<String, TopicMastery>> loadTopicMasteries(String? userId) async {
    return Map<String, TopicMastery>.from(_store[_bucket(userId)] ?? const {});
  }

  @override
  Future<void> saveTopicMasteries(
    String? userId,
    Map<String, TopicMastery> masteries,
  ) async {
    _store[_bucket(userId)] = Map<String, TopicMastery>.from(masteries);
  }
}

/// Coordinates local caching, Supabase persistence, and chronological rebuilds
/// of BKT [TopicMastery] per student per topic.
class MasteryTracker {
  final MasteryStorage storage;
  final MasteryRemoteSink remoteSink;
  final Future<bool> Function() isOnline;
  final String? Function() getCurrentUserId;
  final BktModel model;

  MasteryTracker({
    required this.storage,
    required this.remoteSink,
    required this.isOnline,
    required this.getCurrentUserId,
    this.model = const BktModel(),
  });

  /// Updates the topic's mastery immediately when a question is answered,
  /// caches it locally, and persists to Supabase if signed in and online.
  Future<TopicMastery> recordAttempt(
    QuestionAttempt attempt, {
    String? userIdOverride,
  }) async {
    final userId = userIdOverride ?? attempt.userId ?? getCurrentUserId();
    final masteries = await storage.loadTopicMasteries(userId);
    final key = TopicMastery.topicKey(attempt.subject, attempt.topic);
    final existing = masteries[key];
    final prior = existing?.mastery ?? model.params.pInit;
    final nextMastery = model.updateFromAttempt(prior, attempt);

    final updated = (existing ??
            TopicMastery(
              userId: userId,
              subject: attempt.subject,
              topic: attempt.topic,
              mastery: nextMastery,
              updatedAt: attempt.answeredAt.toUtc(),
            ))
        .copyWith(
      userId: userId,
      mastery: nextMastery,
      updatedAt: attempt.answeredAt.toUtc(),
    );

    masteries[key] = updated;
    await storage.saveTopicMasteries(userId, masteries);

    if (userId != null && remoteSink.isReady && await isOnline()) {
      try {
        await remoteSink.upsertTopicMasteries([updated.toSupabaseRow(userId)]);
      } catch (_) {
        // Local cache already updated; remote can be synced or rebuilt later.
      }
    }

    return updated;
  }

  /// Updates the SM-2 spaced-repetition schedule for `(subject, topic)` after
  /// a quiz based on the topic's session performance.
  Future<TopicMastery> recordTopicReview({
    required String subject,
    required String topic,
    required int correctCount,
    required int totalCount,
    int hintCount = 0,
    DateTime? reviewedAt,
    String? userIdOverride,
  }) async {
    final userId = userIdOverride ?? getCurrentUserId();
    final masteries = await storage.loadTopicMasteries(userId);
    final key = TopicMastery.topicKey(subject, topic);
    final existing = masteries[key];
    final now = (reviewedAt ?? DateTime.now()).toUtc();

    final quality = Sm2Scheduler.qualityFromQuizPerformance(
      correctCount: correctCount,
      totalCount: totalCount,
      hintCount: hintCount,
    );
    final schedule = Sm2Scheduler.scheduleNext(
      ease: existing?.ease ?? Sm2Scheduler.initialEase,
      intervalDays: existing?.intervalDays ?? 0,
      repetitions: existing?.repetitions ?? 0,
      quality: quality,
      reviewedAt: now,
    );

    final updated = (existing ??
            TopicMastery(
              userId: userId,
              subject: subject,
              topic: topic,
              mastery: model.params.pInit,
              updatedAt: now,
            ))
        .copyWith(
      userId: userId,
      updatedAt: now,
      ease: schedule.ease,
      intervalDays: schedule.intervalDays,
      repetitions: schedule.repetitions,
      nextReviewAt: schedule.nextReviewAt,
    );

    masteries[key] = updated;
    await storage.saveTopicMasteries(userId, masteries);

    if (userId != null && remoteSink.isReady && await isOnline()) {
      try {
        await remoteSink.upsertTopicMasteries([updated.toSupabaseRow(userId)]);
      } catch (_) {
        // Local cache updated; remote can be synced later.
      }
    }

    return updated;
  }

  /// Returns all topics whose SM-2 `nextReviewAt` is due on or before [asOf],
  /// sorted most overdue first.
  Future<List<TopicMastery>> getDueTopics({
    DateTime? asOf,
    String? userId,
  }) async {
    final ref = (asOf ?? DateTime.now()).toUtc();
    final masteries = await getMasteries(userId: userId);
    final due = masteries.values
        .where((m) => Sm2Scheduler.isDue(m.nextReviewAt, now: ref))
        .toList()
      ..sort((a, b) => a.nextReviewAt!.compareTo(b.nextReviewAt!));
    return due;
  }

  /// Rebuilds mastery from [attempts] in chronological order and persists it.
  Future<Map<String, TopicMastery>> rebuildFromAttempts(
    List<QuestionAttempt> attempts, {
    String? userId,
  }) async {
    final resolvedUserId = userId ?? getCurrentUserId();
    final rebuilt = model.replayAttempts(attempts, userId: resolvedUserId);
    await storage.saveTopicMasteries(resolvedUserId, rebuilt);

    if (resolvedUserId != null &&
        rebuilt.isNotEmpty &&
        remoteSink.isReady &&
        await isOnline()) {
      try {
        final rows = rebuilt.values
            .map((m) => m.toSupabaseRow(resolvedUserId))
            .toList(growable: false);
        await remoteSink.upsertTopicMasteries(rows);
      } catch (_) {
        // Keep local rebuilt cache even if remote upsert fails.
      }
    }

    return rebuilt;
  }

  /// Loads topic masteries for [userId].
  ///
  /// Checks remote `topic_mastery` when signed in and online. If remote is
  /// empty (and local cache is empty or [fallbackAttempts] are provided when
  /// `topic_mastery` is empty), rebuilds mastery chronologically from
  /// [fallbackAttempts].
  Future<Map<String, TopicMastery>> getMasteries({
    String? userId,
    List<QuestionAttempt>? fallbackAttempts,
  }) async {
    final resolvedUserId = userId ?? getCurrentUserId();
    var local = await storage.loadTopicMasteries(resolvedUserId);

    if (resolvedUserId != null && remoteSink.isReady && await isOnline()) {
      try {
        final remoteRows = await remoteSink.fetchTopicMasteries(resolvedUserId);
        if (remoteRows.isNotEmpty) {
          final merged = Map<String, TopicMastery>.from(local);
          for (final row in remoteRows) {
            final existing = merged[row.key];
            if (existing == null || row.updatedAt.isAfter(existing.updatedAt)) {
              merged[row.key] = row;
            }
          }
          await storage.saveTopicMasteries(resolvedUserId, merged);
          return merged;
        }
        // Remote topic_mastery table is empty: rebuild from question_attempts if available.
        if (fallbackAttempts != null && fallbackAttempts.isNotEmpty) {
          return rebuildFromAttempts(fallbackAttempts, userId: resolvedUserId);
        }
      } catch (_) {
        // Fall back to local cache if remote fetch fails.
      }
    }

    if (local.isEmpty && fallbackAttempts != null && fallbackAttempts.isNotEmpty) {
      return rebuildFromAttempts(fallbackAttempts, userId: resolvedUserId);
    }

    return local;
  }

  /// Migrates guest mastery into [userId] on registration by replaying
  /// [allUserAttempts] chronologically (or moving guest cache if no attempts).
  Future<void> migrateGuestMastery(
    String userId,
    List<QuestionAttempt> allUserAttempts,
  ) async {
    if (allUserAttempts.isNotEmpty) {
      await rebuildFromAttempts(allUserAttempts, userId: userId);
    } else {
      final guest = await storage.loadTopicMasteries(null);
      if (guest.isNotEmpty) {
        final stamped = guest.map(
          (k, v) => MapEntry(k, v.copyWith(userId: userId)),
        );
        await storage.saveTopicMasteries(userId, stamped);
      }
    }
    await storage.saveTopicMasteries(null, const {});
  }
}
