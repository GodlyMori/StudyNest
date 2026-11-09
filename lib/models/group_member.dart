class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String name;
  final String role; // 'Admin' or 'Member'
  final String? avatarUrl;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.name,
    this.role = 'Member',
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'name': name,
        'role': role,
        'avatar_url': avatarUrl,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String? ?? 'Student',
        role: json['role'] as String? ?? 'Member',
        avatarUrl: json['avatar_url'] as String?,
      );
}
