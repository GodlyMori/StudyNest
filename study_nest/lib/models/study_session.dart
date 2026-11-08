class StudySession {
  final String id;
  final String title;
  final String subject;
  final String date; // Day label e.g. "Wed", "Thu", or date string "6", "7"
  final String time; // e.g. "2:00 PM – 2:30 PM"
  final String type;
  final String duration;
  final String status;
  final bool reminderEnabled;
  final int? notificationId;

  const StudySession({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    required this.time,
    this.type = 'Self Study',
    this.duration = '30 min',
    this.status = 'Upcoming',
    this.reminderEnabled = false,
    this.notificationId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'date': date,
        'time': time,
        'type': type,
        'duration': duration,
        'status': status,
        'reminderEnabled': reminderEnabled,
        'notificationId': notificationId,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        title: json['title'] as String,
        subject: json['subject'] as String,
        date: json['date'] as String,
        time: json['time'] as String,
        type: json['type'] as String? ?? 'Self Study',
        duration: json['duration'] as String? ?? '30 min',
        status: json['status'] as String? ?? 'Upcoming',
        reminderEnabled: json['reminderEnabled'] as bool? ?? false,
        notificationId: json['notificationId'] as int?,
      );
}
