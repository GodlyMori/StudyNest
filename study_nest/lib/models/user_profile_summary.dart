class UserProfileSummary {
  final String id;
  final String name;
  final String subject;
  final String level;
  final String? avatarUrl;

  const UserProfileSummary({
    required this.id,
    required this.name,
    this.subject = 'Calculus',
    this.level = 'Grade 12',
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'level': level,
        'avatar_url': avatarUrl,
      };

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    String subjectStr = 'General';
    if (json['subjects'] != null && json['subjects'] is List && (json['subjects'] as List).isNotEmpty) {
      subjectStr = (json['subjects'] as List).first.toString();
    } else if (json['subject'] != null) {
      subjectStr = json['subject'].toString();
    }

    return UserProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Student',
      subject: subjectStr,
      level: json['level'] as String? ?? 'Grade 12',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
