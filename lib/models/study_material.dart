class StudyMaterial {
  final String id;
  final String title;
  final String category;
  final String meta;
  final String content;

  const StudyMaterial({
    required this.id,
    required this.title,
    required this.category,
    required this.meta,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'meta': meta,
        'content': content,
      };

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        meta: json['meta'] as String,
        content: json['content'] as String,
      );
}
