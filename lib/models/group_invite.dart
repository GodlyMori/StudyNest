class GroupInvite {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterId;
  final String inviterName;
  final String inviteeId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterId,
    required this.inviterName,
    required this.inviteeId,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'group_name': groupName,
        'inviter_id': inviterId,
        'inviter_name': inviterName,
        'invitee_id': inviteeId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory GroupInvite.fromJson(Map<String, dynamic> json) => GroupInvite(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String? ?? 'Study Group',
        inviterId: json['inviter_id'] as String? ?? '',
        inviterName: json['inviter_name'] as String? ?? 'Group Admin',
        inviteeId: json['invitee_id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
