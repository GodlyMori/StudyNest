class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final bool isOwl;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.isMe = false,
    this.isOwl = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'is_me': isMe,
        'is_owl': isOwl,
      };

  factory GroupMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sender = json['sender_id'] as String? ?? '';
    final isMeUser = currentUserId != null && currentUserId.isNotEmpty && sender == currentUserId;
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: sender,
      senderName: json['sender_name'] as String? ?? 'Student',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isMe: isMeUser || (json['is_me'] as bool? ?? false),
      isOwl: json['is_owl'] as bool? ?? (json['sender_name'] == 'Owl (Study Buddy)'),
    );
  }
}
