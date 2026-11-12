import 'dart:math';

/// Pure Dart model representing a single answered quiz question attempt.
///
/// Used by V2 Stage 1 logging/outbox sync and consumed by Stage 2 mastery
/// and spaced-repetition calculations.
class QuestionAttempt {
  final String id;
  final String? userId;
  final String questionId;
  final String subject;
  final String topic;
  final bool correct;
  final int timeTakenMs;
  final bool hintUsed;
  final DateTime answeredAt;

  const QuestionAttempt({
    required this.id,
    this.userId,
    required this.questionId,
    required this.subject,
    required this.topic,
    required this.correct,
    required this.timeTakenMs,
    required this.hintUsed,
    required this.answeredAt,
  });

  QuestionAttempt copyWith({
    String? id,
    String? userId,
    String? questionId,
    String? subject,
    String? topic,
    bool? correct,
    int? timeTakenMs,
    bool? hintUsed,
    DateTime? answeredAt,
  }) {
    return QuestionAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questionId: questionId ?? this.questionId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      correct: correct ?? this.correct,
      timeTakenMs: timeTakenMs ?? this.timeTakenMs,
      hintUsed: hintUsed ?? this.hintUsed,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  /// Serializes to local JSON storage (SharedPreferences).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'question_id': questionId,
      'subject': subject,
      'topic': topic,
      'correct': correct,
      'time_taken_ms': timeTakenMs,
      'hint_used': hintUsed,
      'answered_at': answeredAt.toUtc().toIso8601String(),
    };
  }

  /// Deserializes from local JSON storage.
  factory QuestionAttempt.fromJson(Map<String, dynamic> json) {
    return QuestionAttempt(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      questionId: json['question_id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      correct: json['correct'] as bool,
      timeTakenMs: (json['time_taken_ms'] as num).toInt().clamp(0, 1 << 31),
      hintUsed: (json['hint_used'] as bool?) ?? false,
      answeredAt: DateTime.parse(json['answered_at'] as String).toUtc(),
    );
  }

  /// Converts to a row matching `public.question_attempts` in Supabase.
  Map<String, dynamic> toSupabaseRow(String resolvedUserId) {
    return {
      'id': id,
      'user_id': resolvedUserId,
      'question_id': questionId,
      'subject': subject,
      'topic': topic,
      'correct': correct,
      'time_taken_ms': timeTakenMs < 0 ? 0 : timeTakenMs,
      'hint_used': hintUsed,
      'answered_at': answeredAt.toUtc().toIso8601String(),
    };
  }

  /// Generates a RFC-4122 v4 UUID in pure Dart for client-side idempotency.
  static String generateUuidV4([Random? random]) {
    final rng = random ?? _secureRandom();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1

    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b.sublist(0, 4).join()}-'
        '${b.sublist(4, 6).join()}-'
        '${b.sublist(6, 8).join()}-'
        '${b.sublist(8, 10).join()}-'
        '${b.sublist(10, 16).join()}';
  }

  static Random _secureRandom() {
    try {
      return Random.secure();
    } catch (_) {
      return Random();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionAttempt &&
        other.id == id &&
        other.userId == userId &&
        other.questionId == questionId &&
        other.subject == subject &&
        other.topic == topic &&
        other.correct == correct &&
        other.timeTakenMs == timeTakenMs &&
        other.hintUsed == hintUsed &&
        other.answeredAt.toUtc() == answeredAt.toUtc();
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        questionId,
        subject,
        topic,
        correct,
        timeTakenMs,
        hintUsed,
        answeredAt.toUtc(),
      );

  @override
  String toString() {
    return 'QuestionAttempt(id: $id, userId: $userId, questionId: $questionId, '
        'subject: $subject, topic: $topic, correct: $correct, '
        'timeTakenMs: $timeTakenMs, hintUsed: $hintUsed, '
        'answeredAt: ${answeredAt.toIso8601String()})';
  }
}
