class StudyGroup {
  final String id;
  final String name;
  final String subject;
  final String description;
  final String? createdBy;
  final int memberCount;
  final int onlineCount;
  final bool isPublic;
  final bool isJoined;

  const StudyGroup({
    required this.id,
    required this.name,
    required this.subject,
    this.description = '',
    this.createdBy,
    this.memberCount = 1,
    this.onlineCount = 1,
    this.isPublic = true,
    this.isJoined = false,
  });

  StudyGroup copyWith({
    String? id,
    String? name,
    String? subject,
    String? description,
    String? createdBy,
    int? memberCount,
    int? onlineCount,
    bool? isPublic,
    bool? isJoined,
  }) {
    return StudyGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberCount: memberCount ?? this.memberCount,
      onlineCount: onlineCount ?? this.onlineCount,
      isPublic: isPublic ?? this.isPublic,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'description': description,
        'created_by': createdBy,
        'member_count': memberCount,
        'online_count': onlineCount,
        'is_public': isPublic,
        'is_joined': isJoined,
      };

  factory StudyGroup.fromJson(Map<String, dynamic> json) => StudyGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        subject: json['subject'] as String? ?? 'General',
        description: json['description'] as String? ?? '',
        createdBy: json['created_by'] as String?,
        memberCount: json['member_count'] as int? ?? 1,
        onlineCount: json['online_count'] as int? ?? 1,
        isPublic: json['is_public'] as bool? ?? true,
        isJoined: json['is_joined'] as bool? ?? false,
      );
}
