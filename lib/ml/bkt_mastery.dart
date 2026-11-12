import 'question_attempt.dart';

/// Tunable parameters for Bayesian Knowledge Tracing (BKT).
class BktParams {
  /// Default prior probability the student already knows the skill: P(L0).
  static const double defaultInit = 0.3;

  /// Default probability of transitioning from unlearned to learned: P(T).
  static const double defaultLearn = 0.15;

  /// Default probability of answering incorrectly despite knowing: P(S).
  static const double defaultSlip = 0.1;

  /// Default probability of guessing correctly without knowing: P(G).
  static const double defaultGuess = 0.25;

  /// Additional guess probability when a hint was used before answering.
  static const double hintGuessBoost = 0.15;

  /// Learning-rate multiplier when a hint was used on a correct answer.
  static const double hintLearnScale = 0.6;

  /// Responses faster than this (ms) on a correct answer get a slight guess boost.
  static const int fastGuessThresholdMs = 1200;

  /// Additional guess probability for suspiciously fast responses.
  static const double fastGuessBoost = 0.05;

  final double pInit;
  final double pLearn;
  final double pSlip;
  final double pGuess;

  const BktParams({
    this.pInit = defaultInit,
    this.pLearn = defaultLearn,
    this.pSlip = defaultSlip,
    this.pGuess = defaultGuess,
  });
}

/// Persisted mastery state for a single (user, subject, topic) tuple.
class TopicMastery {
  final String? userId;
  final String subject;
  final String topic;
  final double mastery;
  final DateTime updatedAt;

  const TopicMastery({
    this.userId,
    required this.subject,
    required this.topic,
    required this.mastery,
    required this.updatedAt,
  });

  String get key => topicKey(subject, topic);

  static String topicKey(String subject, String topic) => '$subject::$topic';

  TopicMastery copyWith({
    String? userId,
    String? subject,
    String? topic,
    double? mastery,
    DateTime? updatedAt,
  }) {
    return TopicMastery(
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      mastery: mastery ?? this.mastery,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'subject': subject,
      'topic': topic,
      'mastery': mastery,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory TopicMastery.fromJson(Map<String, dynamic> json) {
    return TopicMastery(
      userId: json['user_id'] as String?,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      mastery: (json['mastery'] as num).toDouble().clamp(0.0, 1.0),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toSupabaseRow(String resolvedUserId) {
    return {
      'user_id': resolvedUserId,
      'subject': subject,
      'topic': topic,
      'mastery': mastery.clamp(0.0, 1.0),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory TopicMastery.fromSupabaseRow(Map<String, dynamic> row) {
    return TopicMastery(
      userId: row['user_id'] as String?,
      subject: row['subject'] as String,
      topic: row['topic'] as String,
      mastery: (row['mastery'] as num).toDouble().clamp(0.0, 1.0),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }
}

/// Pure-Dart Bayesian Knowledge Tracing (BKT) engine.
class BktModel {
  final BktParams params;

  const BktModel({this.params = const BktParams()});

  /// Computes updated mastery probability P(L_n+1) given [prior] P(L_n)
  /// and an observed answer outcome.
  double updateMastery(
    double prior, {
    required bool correct,
    bool hintUsed = false,
    int timeTakenMs = 3000,
  }) {
    final pPrior = prior.clamp(0.0001, 0.9999);
    var slip = params.pSlip;
    var guess = params.pGuess;
    var learn = params.pLearn;

    if (hintUsed) {
      guess = (guess + BktParams.hintGuessBoost).clamp(0.01, 0.95);
      if (correct) {
        learn = (learn * BktParams.hintLearnScale).clamp(0.0, 1.0);
      }
    }

    if (timeTakenMs > 0 && timeTakenMs < BktParams.fastGuessThresholdMs && correct) {
      guess = (guess + BktParams.fastGuessBoost).clamp(0.01, 0.95);
    }

    final double posterior;
    if (correct) {
      final num = pPrior * (1.0 - slip);
      final den = num + (1.0 - pPrior) * guess;
      posterior = den > 0 ? num / den : pPrior;
    } else {
      final num = pPrior * slip;
      final den = num + (1.0 - pPrior) * (1.0 - guess);
      posterior = den > 0 ? num / den : pPrior;
    }

    final next = posterior + (1.0 - posterior) * learn;
    return next.clamp(0.0, 1.0);
  }

  /// Updates [prior] using a [QuestionAttempt] record.
  double updateFromAttempt(double prior, QuestionAttempt attempt) {
    return updateMastery(
      prior,
      correct: attempt.correct,
      hintUsed: attempt.hintUsed,
      timeTakenMs: attempt.timeTakenMs,
    );
  }

  /// Replays [attempts] in chronological order to reconstruct per-topic mastery.
  Map<String, TopicMastery> replayAttempts(
    List<QuestionAttempt> attempts, {
    String? userId,
  }) {
    final sorted = List<QuestionAttempt>.from(attempts)
      ..sort((a, b) {
        final cmp = a.answeredAt.compareTo(b.answeredAt);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });

    final result = <String, TopicMastery>{};
    for (final attempt in sorted) {
      final key = TopicMastery.topicKey(attempt.subject, attempt.topic);
      final prior = result[key]?.mastery ?? params.pInit;
      final next = updateFromAttempt(prior, attempt);
      result[key] = TopicMastery(
        userId: userId ?? attempt.userId,
        subject: attempt.subject,
        topic: attempt.topic,
        mastery: next,
        updatedAt: attempt.answeredAt.toUtc(),
      );
    }
    return result;
  }
}
