import '../ml/bkt_mastery.dart';

/// Represents the before and after mastery percentage movement of a topic attempted in a quiz.
class TopicMasteryMovement {
  final String topic;
  final String subject;
  final int beforePct;
  final int afterPct;

  const TopicMasteryMovement({
    required this.topic,
    required this.subject,
    required this.beforePct,
    required this.afterPct,
  });

  /// Computes the list of topic movements for topics attempted in this quiz.
  ///
  /// A topic is included ONLY if:
  /// 1. It had a pre-quiz mastery entry in [beforeMasteries].
  /// 2. It has an entry in [afterMasteries].
  /// 3. The rounded [beforePct] and [afterPct] differ.
  static List<TopicMasteryMovement> computeMovements({
    required Map<String, TopicMastery> beforeMasteries,
    required Map<String, TopicMastery> afterMasteries,
    required Iterable<String> attemptedTopics,
    Map<String, String>? topicSubjects,
    String defaultSubject = 'Calculus',
  }) {
    final movements = <TopicMasteryMovement>[];

    for (final topic in attemptedTopics) {
      final subject = topicSubjects?[topic] ?? defaultSubject;
      final key = TopicMastery.topicKey(subject, topic);

      // Find before mastery entry
      TopicMastery? before = beforeMasteries[key];
      before ??= beforeMasteries.values.cast<TopicMastery?>().firstWhere(
            (m) =>
                m?.topic == topic &&
                m?.subject.toLowerCase() == subject.toLowerCase(),
            orElse: () => null,
          );

      if (before == null) continue; // First-time topic has no "before"

      // Find after mastery entry
      TopicMastery? after = afterMasteries[key];
      after ??= afterMasteries.values.cast<TopicMastery?>().firstWhere(
            (m) =>
                m?.topic == topic &&
                m?.subject.toLowerCase() == subject.toLowerCase(),
            orElse: () => null,
          );

      if (after == null) continue;

      final beforePct = (before.mastery.clamp(0.0, 1.0) * 100).round();
      final afterPct = (after.mastery.clamp(0.0, 1.0) * 100).round();

      if (beforePct != afterPct) {
        movements.add(
          TopicMasteryMovement(
            topic: topic,
            subject: subject,
            beforePct: beforePct,
            afterPct: afterPct,
          ),
        );
      }
    }

    return movements;
  }
}
