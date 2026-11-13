import 'bkt_mastery.dart';
import 'question_attempt.dart';

/// Represents a single timestamped mastery point in a topic's learning progression.
class TopicTrendPoint {
  final DateTime timestamp;
  final double mastery;
  final bool correct;

  const TopicTrendPoint({
    required this.timestamp,
    required this.mastery,
    required this.correct,
  });
}

/// Aggregated mastery and chronological progress for a topic.
class TopicProgressData {
  final String subject;
  final String topic;
  final List<TopicTrendPoint> points;
  final double currentMastery;
  final int totalAttempts;

  const TopicProgressData({
    required this.subject,
    required this.topic,
    required this.points,
    required this.currentMastery,
    required this.totalAttempts,
  });

  bool get hasAttempts => points.isNotEmpty;

  /// Whether the student improved from their first attempt to their latest.
  bool get isImproving {
    if (points.length < 2) return false;
    return points.last.mastery >= points.first.mastery;
  }
}

/// Pure Dart analytics service computing mastery-over-time trends from real
/// question attempt history using Bayesian Knowledge Tracing (BKT).
class TopicProgressAnalytics {
  final BktModel bktModel;

  const TopicProgressAnalytics({
    this.bktModel = const BktModel(),
  });

  /// Computes the mastery-over-time trend for a single [topic] in [subject]
  /// from raw [attempts].
  TopicProgressData computeTopicProgress({
    required String subject,
    required String topic,
    required List<QuestionAttempt> attempts,
  }) {
    // Filter attempts for this subject and topic
    final topicAttempts = attempts.where((a) {
      return a.subject.trim().toLowerCase() == subject.trim().toLowerCase() &&
          a.topic.trim().toLowerCase() == topic.trim().toLowerCase();
    }).toList();

    if (topicAttempts.isEmpty) {
      return TopicProgressData(
        subject: subject,
        topic: topic,
        points: const [],
        currentMastery: 0.0,
        totalAttempts: 0,
      );
    }

    // Sort chronologically ascending
    topicAttempts.sort((a, b) {
      final cmp = a.answeredAt.compareTo(b.answeredAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    double current = BktParams.defaultInit;
    final points = <TopicTrendPoint>[];

    for (final attempt in topicAttempts) {
      current = bktModel.updateMastery(
        current,
        correct: attempt.correct,
        hintUsed: attempt.hintUsed,
        timeTakenMs: attempt.timeTakenMs,
      );
      points.add(
        TopicTrendPoint(
          timestamp: attempt.answeredAt,
          mastery: current,
          correct: attempt.correct,
        ),
      );
    }

    return TopicProgressData(
      subject: subject,
      topic: topic,
      points: points,
      currentMastery: current,
      totalAttempts: topicAttempts.length,
    );
  }

  /// Computes progress data across a list of (subject, topic) pairs.
  Map<String, TopicProgressData> computeAllProgress({
    required List<({String subject, String topic})> targetTopics,
    required List<QuestionAttempt> attempts,
  }) {
    final result = <String, TopicProgressData>{};
    for (final item in targetTopics) {
      final key = '${item.subject}::${item.topic}';
      result[key] = computeTopicProgress(
        subject: item.subject,
        topic: item.topic,
        attempts: attempts,
      );
    }
    return result;
  }
}
