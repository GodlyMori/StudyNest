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
    this.level = 'Level 5',
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': name,
        'name': name,
        'subject': subject,
        'level': level,
        'avatar_url': avatarUrl,
      };

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    // 1. Name: Read display_name (live schema) or fallback to name
    final nameStr = (json['display_name'] ?? json['name'] ?? 'Student') as String;

    // 2. Subject: Extract from subjects array or subject string
    String subjectStr = 'General';
    if (json['subjects'] != null && json['subjects'] is List && (json['subjects'] as List).isNotEmpty) {
      subjectStr = (json['subjects'] as List).first.toString();
    } else if (json['subject'] != null) {
      subjectStr = json['subject'].toString();
    }

    // 3. Level: Handle level as integer (live schema) or String
    String levelStr = 'Level 1';
    final rawLevel = json['level'];
    if (rawLevel != null) {
      if (rawLevel is int) {
        levelStr = 'Level $rawLevel';
      } else {
        final parsed = int.tryParse(rawLevel.toString().replaceAll(RegExp(r'[^0-9]'), ''));
        if (parsed != null) {
          levelStr = 'Level $parsed';
        } else {
          levelStr = rawLevel.toString();
        }
      }
    }

    return UserProfileSummary(
      id: json['id'] as String? ?? '',
      name: nameStr,
      subject: subjectStr,
      level: levelStr,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
