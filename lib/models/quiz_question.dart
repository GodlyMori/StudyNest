class QuizQuestion {
  final String id;
  final String subject;
  final String topic;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  /// Difficulty level: 1 = easy, 2 = medium, 3 = hard.
  final int difficulty;

  const QuizQuestion({
    required this.id,
    required this.subject,
    required this.topic,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.difficulty = 1,
  }) : assert(difficulty >= 1 && difficulty <= 3);
}
