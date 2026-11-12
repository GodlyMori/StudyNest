/// Pure-Dart SM-2 spaced-repetition scheduler.
///
/// Quality grade mapping from quiz topic performance (`0..5`):
/// - `accuracy = correctCount / totalCount`, adjusted by `-0.1 * (hintCount / totalCount)`
///   when hints are used:
///   - `>= 0.90` -> `5` (strong recall)
///   - `>= 0.75` -> `4` (good recall)
///   - `>= 0.60` -> `3` (passing recall)
///   - `>= 0.40` -> `2` (failed, partial recall)
///   - `>= 0.20` -> `1` (failed, weak recall)
///   - `<  0.20` -> `0` (failed, blackout)
class Sm2Schedule {
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime nextReviewAt;

  const Sm2Schedule({
    required this.ease,
    required this.intervalDays,
    required this.repetitions,
    required this.nextReviewAt,
  });
}

class Sm2Scheduler {
  Sm2Scheduler._();

  static const double initialEase = 2.5;
  static const double minEase = 1.3;
  static const int firstIntervalDays = 1;
  static const int secondIntervalDays = 6;
  static const int passingQualityThreshold = 3;

  /// Maps a topic's quiz performance (`correctCount / totalCount`, with optional
  /// `hintCount` penalty) to an SM-2 quality grade in `0..5`.
  static int qualityFromQuizPerformance({
    required int correctCount,
    required int totalCount,
    int hintCount = 0,
  }) {
    if (totalCount <= 0) return 0;
    final accuracy = (correctCount / totalCount).clamp(0.0, 1.0);
    final hintPenalty =
        hintCount > 0 ? 0.1 * (hintCount / totalCount).clamp(0.0, 1.0) : 0.0;
    final score = (accuracy - hintPenalty).clamp(0.0, 1.0);

    if (score >= 0.90) return 5;
    if (score >= 0.75) return 4;
    if (score >= 0.60) return 3;
    if (score >= 0.40) return 2;
    if (score >= 0.20) return 1;
    return 0;
  }

  /// Computes the next SM-2 schedule given current [ease], [intervalDays],
  /// [repetitions], and [quality] (`0..5`).
  static Sm2Schedule scheduleNext({
    double ease = initialEase,
    int intervalDays = 0,
    int repetitions = 0,
    required int quality,
    DateTime? reviewedAt,
  }) {
    final q = quality.clamp(0, 5);
    final now = (reviewedAt ?? DateTime.now()).toUtc();

    final int nextRepetitions;
    final int nextIntervalDays;
    if (q >= passingQualityThreshold) {
      nextRepetitions = repetitions + 1;
      if (nextRepetitions == 1) {
        nextIntervalDays = firstIntervalDays;
      } else if (nextRepetitions == 2) {
        nextIntervalDays = secondIntervalDays;
      } else {
        final base = intervalDays > 0 ? intervalDays : secondIntervalDays;
        nextIntervalDays = (base * ease).round().clamp(1, 36500);
      }
    } else {
      // Failed review resets repetition count and interval.
      nextRepetitions = 0;
      nextIntervalDays = firstIntervalDays;
    }

    final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    final nextEase = (ease + delta).clamp(minEase, 5.0);
    final nextReviewAt = now.add(Duration(days: nextIntervalDays));

    return Sm2Schedule(
      ease: nextEase,
      intervalDays: nextIntervalDays,
      repetitions: nextRepetitions,
      nextReviewAt: nextReviewAt,
    );
  }

  /// Returns `true` if [nextReviewAt] is non-null and on or before [now].
  static bool isDue(DateTime? nextReviewAt, {DateTime? now}) {
    if (nextReviewAt == null) return false;
    final ref = (now ?? DateTime.now()).toUtc();
    return !nextReviewAt.toUtc().isAfter(ref);
  }

  /// Infers repetition count from persisted [intervalDays] when loading from
  /// Supabase (which stores `interval_days`, `ease`, and `next_review_at`).
  static int inferRepetitions(int intervalDays) {
    if (intervalDays <= 0) return 0;
    if (intervalDays == firstIntervalDays) return 1;
    if (intervalDays <= secondIntervalDays) return 2;
    return 3;
  }
}
