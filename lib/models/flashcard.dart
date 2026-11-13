import '../ml/sm2_scheduler.dart';

/// Represents a flashcard created from study material or manual entry.
class Flashcard {
  final String id;
  final String? userId;
  final String materialId;
  final String front;
  final String back;
  final double ease;
  final int intervalDays;
  final int repetitions;
  final DateTime? nextReviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Flashcard({
    required this.id,
    this.userId,
    required this.materialId,
    required this.front,
    required this.back,
    this.ease = Sm2Scheduler.initialEase,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.nextReviewAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the card is due for review.
  bool isDue([DateTime? now]) {
    if (nextReviewAt == null) return true;
    final current = now ?? DateTime.now().toUtc();
    return nextReviewAt!.toUtc().isBefore(current) ||
        nextReviewAt!.toUtc().isAtSameMomentAs(current);
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? materialId,
    String? front,
    String? back,
    double? ease,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      materialId: materialId ?? this.materialId,
      front: front ?? this.front,
      back: back ?? this.back,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'material_id': materialId,
      'front': front,
      'back': back,
      'ease': ease,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'next_review_at': nextReviewAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      materialId: json['material_id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      ease: (json['ease'] as num?)?.toDouble() ?? Sm2Scheduler.initialEase,
      intervalDays: (json['interval_days'] as num?)?.toInt() ?? 0,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      nextReviewAt: json['next_review_at'] != null
          ? DateTime.parse(json['next_review_at'] as String).toUtc()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toSupabaseRow([String? resolvedUserId]) {
    final uid = resolvedUserId ?? userId;
    return {
      'id': id,
      if (uid != null) 'user_id': uid,
      'material_id': materialId,
      'front': front,
      'back': back,
      'ease': ease,
      'interval_days': intervalDays,
      'repetitions': repetitions,
      'next_review_at': nextReviewAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Flashcard.fromSupabaseRow(Map<String, dynamic> row) =>
      Flashcard.fromJson(row);
}
