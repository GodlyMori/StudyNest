class ChallengeAttempt {
  final String id;
  final String challengeId;
  final String userId;
  final String userName;
  final int score;
  final int total;
  final int percentage;
  final DateTime completedAt;

  const ChallengeAttempt({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.userName,
    required this.score,
    required this.total,
    required this.percentage,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'user_id': userId,
      'user_name': userName,
      'score': score,
      'total': total,
      'percentage': percentage,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }

  factory ChallengeAttempt.fromJson(Map<String, dynamic> json) {
    return ChallengeAttempt(
      id: json['id'] as String,
      challengeId: json['challenge_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Student',
      score: (json['score'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      percentage: (json['percentage'] as num).toInt(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }
}

class GroupChallenge {
  final String id;
  final String groupId;
  final String creatorId;
  final String creatorName;
  final String subject;
  final int questionCount;
  final DateTime createdAt;
  final List<ChallengeAttempt> attempts;

  const GroupChallenge({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.creatorName,
    required this.subject,
    required this.questionCount,
    required this.createdAt,
    this.attempts = const [],
  });

  GroupChallenge copyWith({
    String? id,
    String? groupId,
    String? creatorId,
    String? creatorName,
    String? subject,
    int? questionCount,
    DateTime? createdAt,
    List<ChallengeAttempt>? attempts,
  }) {
    return GroupChallenge(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      subject: subject ?? this.subject,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'subject': subject,
      'question_count': questionCount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'attempts': attempts.map((a) => a.toJson()).toList(),
    };
  }

  factory GroupChallenge.fromJson(Map<String, dynamic> json) {
    final rawAttempts = json['attempts'] as List? ?? [];
    return GroupChallenge(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      creatorId: json['creator_id'] as String,
      creatorName: json['creator_name'] as String? ?? 'Study Member',
      subject: json['subject'] as String,
      questionCount: (json['question_count'] as num?)?.toInt() ?? 5,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toUtc()
          : DateTime.now().toUtc(),
      attempts: rawAttempts
          .map((a) => ChallengeAttempt.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
    );
  }
}
