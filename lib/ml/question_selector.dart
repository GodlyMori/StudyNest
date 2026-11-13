import 'dart:math';
import '../models/quiz_question.dart';
import 'bkt_mastery.dart';

/// Pure-Dart adaptive question selector using BKT mastery and item difficulty.
///
/// **Estimated Success Mapping ($P(\text{correct})$):**
///
/// Modeled via a standard 1-parameter Item Response / logistic formulation:
/// $$\text{estimatedSuccess}(L, D) = c + (1 - c) \cdot \frac{1}{1 + \exp\left(-a \cdot (L - b(D))\right)}$$
///
/// Where:
/// - $L \in [0.0, 1.0]$ is the student's current BKT mastery probability for the topic.
/// - $D \in \{1, 2, 3\}$ is the question difficulty:
///   - $D = 1$ (Easy): $b(1) = 0.25$
///   - $D = 2$ (Medium): $b(2) = 0.50$
///   - $D = 3$ (Hard): $b(3) = 0.75$
/// - $c = 0.25$ is the 4-option guessing lower bound.
/// - $a = 5.0$ is the logistic discrimination factor.
///
/// Target Zone: Questions with estimated success closest to `0.65` (sweet spot
/// between `0.60` and `0.75`) are prioritized.
class QuestionSelector {
  static const double targetSuccess = 0.65;
  static const double guessFloor = 0.25;
  static const double discrimination = 5.0;

  static const Map<int, double> difficultyThresholds = {
    1: 0.25, // Easy
    2: 0.50, // Medium
    3: 0.75, // Hard
  };

  /// Estimates the probability that a student with [mastery] answers a
  /// question of [difficulty] correctly.
  static double estimateSuccess({
    required double mastery,
    required int difficulty,
  }) {
    final m = mastery.clamp(0.0, 1.0);
    final b = difficultyThresholds[difficulty] ?? 0.50;
    final logit = 1.0 / (1.0 + exp(-discrimination * (m - b)));
    final p = guessFloor + (1.0 - guessFloor) * logit;
    return p.clamp(0.0, 1.0);
  }

  /// Selects the best next [QuizQuestion] from [availablePool].
  ///
  /// Criteria:
  /// 1. Excludes any question ID in [servedInCurrentQuiz] (zero repetition per quiz).
  /// 2. If [isDiagnostic] and [servedInCurrentQuiz] is empty, targets medium difficulty (2).
  /// 3. Otherwise, for each candidate, retrieves the student's mastery for its topic
  ///    from [topicMasteries] (defaulting to [defaultMastery]), computes [estimateSuccess],
  ///    and scores proximity to [targetSuccess] (`0.65`).
  /// 4. Ties or near-ties prefer questions that appear least recently (or never)
  ///    in [recentAttemptIds] (oldest/unattempted first).
  static QuizQuestion? pickNextQuestion({
    required List<QuizQuestion> availablePool,
    required Set<String> servedInCurrentQuiz,
    Map<String, double> topicMasteries = const {},
    List<String> recentAttemptIds = const [],
    double defaultMastery = BktParams.defaultInit, // 0.3
    bool isDiagnostic = false,
  }) {
    final candidates = availablePool
        .where((q) => !servedInCurrentQuiz.contains(q.id))
        .toList();

    if (candidates.isEmpty) return null;

    // Diagnostic first-question rule: start at medium difficulty (2)
    if (isDiagnostic && servedInCurrentQuiz.isEmpty) {
      final mediums = candidates.where((q) => q.difficulty == 2).toList();
      final pool = mediums.isNotEmpty ? mediums : candidates;
      return _pickLeastRecent(pool, recentAttemptIds);
    }

    // Rank candidates by distance to targetSuccess (0.65)
    candidates.sort((a, b) {
      final masteryA = topicMasteries[a.topic] ?? defaultMastery;
      final masteryB = topicMasteries[b.topic] ?? defaultMastery;

      final pSuccessA = estimateSuccess(mastery: masteryA, difficulty: a.difficulty);
      final pSuccessB = estimateSuccess(mastery: masteryB, difficulty: b.difficulty);

      final diffA = (pSuccessA - targetSuccess).abs();
      final diffB = (pSuccessB - targetSuccess).abs();

      // If within 0.03 proximity, use recency as tie-breaker
      if ((diffA - diffB).abs() > 0.03) {
        return diffA.compareTo(diffB);
      }

      final recencyA = _recencyScore(a.id, recentAttemptIds);
      final recencyB = _recencyScore(b.id, recentAttemptIds);
      if (recencyA != recencyB) {
        return recencyA.compareTo(recencyB); // lower score = answered less recently
      }

      return diffA.compareTo(diffB);
    });

    return candidates.first;
  }

  /// Builds a complete adaptively ordered quiz sequence of up to [count]
  /// questions starting from [seedPool].
  static List<QuizQuestion> buildAdaptiveSequence({
    required List<QuizQuestion> seedPool,
    int count = 10,
    Map<String, double> topicMasteries = const {},
    List<String> recentAttemptIds = const [],
    double defaultMastery = BktParams.defaultInit,
    bool isDiagnostic = false,
  }) {
    final sequence = <QuizQuestion>[];
    final served = <String>{};
    final targetCount = min(count, seedPool.length);

    while (sequence.length < targetCount) {
      final next = pickNextQuestion(
        availablePool: seedPool,
        servedInCurrentQuiz: served,
        topicMasteries: topicMasteries,
        recentAttemptIds: recentAttemptIds,
        defaultMastery: defaultMastery,
        isDiagnostic: isDiagnostic,
      );
      if (next == null) break;
      sequence.add(next);
      served.add(next.id);
    }

    return sequence;
  }

  static QuizQuestion _pickLeastRecent(
    List<QuizQuestion> pool,
    List<String> recentAttemptIds,
  ) {
    var best = pool.first;
    var lowestRecency = _recencyScore(best.id, recentAttemptIds);
    for (var i = 1; i < pool.length; i++) {
      final score = _recencyScore(pool[i].id, recentAttemptIds);
      if (score < lowestRecency) {
        lowestRecency = score;
        best = pool[i];
      }
    }
    return best;
  }

  static int _recencyScore(String questionId, List<String> recentAttemptIds) {
    final idx = recentAttemptIds.lastIndexOf(questionId);
    if (idx < 0) return -1; // Never attempted -> highest priority (lowest score)
    return idx; // Higher index = attempted more recently
  }
}
