class QuizQuestion {
  final String id;
  final String subject;
  final String topic;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.subject,
    required this.topic,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}
