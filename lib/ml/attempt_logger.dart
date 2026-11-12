import 'dart:async';

import 'question_attempt.dart';

/// Storage abstraction for question attempts (guest store, outbox, user cache).
///
/// Pure Dart interface so [AttemptLogger] can be unit-tested in-memory
/// without Flutter widgets or platform channels.
abstract class AttemptStorage {
  Future<List<QuestionAttempt>> loadGuestAttempts();
  Future<void> saveGuestAttempts(List<QuestionAttempt> attempts);

  Future<List<QuestionAttempt>> loadOutbox();
  Future<void> saveOutbox(List<QuestionAttempt> attempts);

  Future<List<QuestionAttempt>> loadUserAttempts(String userId);
  Future<void> saveUserAttempts(String userId, List<QuestionAttempt> attempts);
}

/// Remote sink abstraction for uploading batched attempts (e.g., to Supabase).
abstract class AttemptRemoteSink {
  bool get isReady;

  /// Uploads [rows] idempotently (deduplicated server-side by `id`).
  Future<void> upsertAttempts(List<Map<String, dynamic>> rows);
}

/// In-memory [AttemptStorage] implementation for fast, pure-Dart unit tests.
class InMemoryAttemptStorage implements AttemptStorage {
  List<QuestionAttempt> _guestAttempts = [];
  List<QuestionAttempt> _outbox = [];
  final Map<String, List<QuestionAttempt>> _userAttempts = {};

  @override
  Future<List<QuestionAttempt>> loadGuestAttempts() async =>
      List<QuestionAttempt>.from(_guestAttempts);

  @override
  Future<void> saveGuestAttempts(List<QuestionAttempt> attempts) async {
    _guestAttempts = List<QuestionAttempt>.from(attempts);
  }

  @override
  Future<List<QuestionAttempt>> loadOutbox() async =>
      List<QuestionAttempt>.from(_outbox);

  @override
  Future<void> saveOutbox(List<QuestionAttempt> attempts) async {
    _outbox = List<QuestionAttempt>.from(attempts);
  }

  @override
  Future<List<QuestionAttempt>> loadUserAttempts(String userId) async =>
      List<QuestionAttempt>.from(_userAttempts[userId] ?? const []);

  @override
  Future<void> saveUserAttempts(
    String userId,
    List<QuestionAttempt> attempts,
  ) async {
    _userAttempts[userId] = List<QuestionAttempt>.from(attempts);
  }
}

/// Logs per-question quiz attempts, handles guest storage & account migration,
/// and manages an ordered, deduplicated offline outbox for Supabase sync.
class AttemptLogger {
  final AttemptStorage storage;
  final AttemptRemoteSink remoteSink;
  final Future<bool> Function() isOnline;
  final String? Function() getCurrentUserId;
  final DateTime Function() _clock;
  final String Function() _idGenerator;
  final int batchSize;

  Future<int>? _syncInFlight;

  AttemptLogger({
    required this.storage,
    required this.remoteSink,
    required this.isOnline,
    required this.getCurrentUserId,
    DateTime Function()? clock,
    String Function()? idGenerator,
    this.batchSize = 50,
  })  : _clock = clock ?? (() => DateTime.now().toUtc()),
        _idGenerator = idGenerator ?? QuestionAttempt.generateUuidV4;

  /// Records a single answered question.
  ///
  /// - If no user is signed in (`getCurrentUserId() == null`), saves locally
  ///   in the guest attempts store for later migration on registration.
  /// - If a user is signed in, saves to the user's local cache, enqueues into
  ///   the ordered outbox, and attempts immediate sync if online.
  Future<QuestionAttempt> logAttempt({
    required String questionId,
    required String subject,
    required String topic,
    required bool correct,
    required int timeTakenMs,
    required bool hintUsed,
    String? userIdOverride,
  }) async {
    final userId = userIdOverride ?? getCurrentUserId();
    final attempt = QuestionAttempt(
      id: _idGenerator(),
      userId: userId,
      questionId: questionId,
      subject: subject,
      topic: topic,
      correct: correct,
      timeTakenMs: timeTakenMs < 0 ? 0 : timeTakenMs,
      hintUsed: hintUsed,
      answeredAt: _clock().toUtc(),
    );

    if (userId == null) {
      final guest = await storage.loadGuestAttempts();
      guest.add(attempt);
      await storage.saveGuestAttempts(dedupeAndSort(guest));
    } else {
      final userList = await storage.loadUserAttempts(userId);
      userList.add(attempt);
      await storage.saveUserAttempts(userId, dedupeAndSort(userList));

      final outbox = await storage.loadOutbox();
      outbox.add(attempt);
      await storage.saveOutbox(dedupeAndSort(outbox));

      await syncOutbox();
    }

    return attempt;
  }

  /// Migrates all locally stored guest attempts to [userId].
  ///
  /// Stamps each guest attempt with [userId], merges them into the user's
  /// local cache and the ordered outbox, clears the guest store, and triggers
  /// an immediate outbox sync (which succeeds if online or stays queued if offline).
  Future<int> migrateGuestAttempts(String userId) async {
    final guestAttempts = await storage.loadGuestAttempts();
    if (guestAttempts.isEmpty) return 0;

    final stamped = guestAttempts
        .map((a) => a.copyWith(userId: userId))
        .toList(growable: false);

    final userList = await storage.loadUserAttempts(userId);
    userList.addAll(stamped);
    await storage.saveUserAttempts(userId, dedupeAndSort(userList));

    final outbox = await storage.loadOutbox();
    outbox.addAll(stamped);
    await storage.saveOutbox(dedupeAndSort(outbox));

    await storage.saveGuestAttempts(const []);
    await syncOutbox();

    return stamped.length;
  }

  /// Flushes the outbox in chronological order (`answeredAt` ascending) in
  /// chunks of [batchSize].
  ///
  /// Uses a single-flight lock (`_syncInFlight`) so concurrent triggers never
  /// send overlapping batches. Each batch is only removed from the outbox after
  /// [AttemptRemoteSink.upsertAttempts] succeeds, and any new attempts appended
  /// while a network call is in flight are preserved.
  Future<int> syncOutbox() async {
    final existing = _syncInFlight;
    if (existing != null) {
      return existing;
    }

    final future = _runSyncOutbox();
    _syncInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_syncInFlight, future)) {
        _syncInFlight = null;
      }
    }
  }

  Future<int> _runSyncOutbox() async {
    if (!remoteSink.isReady) return 0;
    if (!await isOnline()) return 0;

    final pending = dedupeAndSort(await storage.loadOutbox())
        .where((a) => a.userId != null && a.userId!.isNotEmpty)
        .toList();
    if (pending.isEmpty) return 0;

    var syncedCount = 0;
    for (var i = 0; i < pending.length; i += batchSize) {
      final end = (i + batchSize < pending.length) ? i + batchSize : pending.length;
      final chunk = pending.sublist(i, end);
      final rows = chunk.map((a) => a.toSupabaseRow(a.userId!)).toList();

      try {
        await remoteSink.upsertAttempts(rows);
      } catch (_) {
        // Stop on first failed chunk to preserve chronological ordering
        // and leave remaining items in the outbox for the next retry.
        break;
      }

      // Reload latest outbox before removing synced IDs so attempts logged
      // concurrently during the upsert are not lost.
      final syncedIds = chunk.map((a) => a.id).toSet();
      final latestOutbox = await storage.loadOutbox();
      final remaining = latestOutbox
          .where((a) => !syncedIds.contains(a.id))
          .toList();
      await storage.saveOutbox(dedupeAndSort(remaining));
      syncedCount += chunk.length;
    }

    return syncedCount;
  }

  /// Returns locally cached attempts for [userId], or guest attempts if null.
  Future<List<QuestionAttempt>> getAttempts({String? userId}) async {
    if (userId == null) {
      return dedupeAndSort(await storage.loadGuestAttempts());
    }
    return dedupeAndSort(await storage.loadUserAttempts(userId));
  }

  /// Returns currently queued outbox attempts waiting for sync.
  Future<List<QuestionAttempt>> getPendingOutbox() async {
    return dedupeAndSort(await storage.loadOutbox());
  }

  /// Deduplicates by [QuestionAttempt.id] and sorts chronologically by
  /// [QuestionAttempt.answeredAt] ascending (with `id` as tiebreaker).
  static List<QuestionAttempt> dedupeAndSort(List<QuestionAttempt> items) {
    final byId = <String, QuestionAttempt>{};
    for (final item in items) {
      byId.putIfAbsent(item.id, () => item);
    }
    final result = byId.values.toList();
    result.sort((a, b) {
      final timeCmp = a.answeredAt.toUtc().compareTo(b.answeredAt.toUtc());
      if (timeCmp != 0) return timeCmp;
      return a.id.compareTo(b.id);
    });
    return result;
  }
}
