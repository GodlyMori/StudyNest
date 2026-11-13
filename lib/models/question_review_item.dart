import '../models/quiz_question.dart';

/// Encapsulates the answered outcome of a single question in a completed quiz,
/// used by [QuizReviewScreen] to render question-level review.
class QuestionReviewItem {
  final QuizQuestion question;
  final int? selectedOptionIndex;
  final bool isCorrect;
  final bool hintUsed;
  final int timeTakenMs;

  const QuestionReviewItem({
    required this.question,
    required this.selectedOptionIndex,
    required this.isCorrect,
    required this.hintUsed,
    required this.timeTakenMs,
  });

  String get studentAnswerText =>
      (selectedOptionIndex != null &&
              selectedOptionIndex! >= 0 &&
              selectedOptionIndex! < question.options.length)
          ? question.options[selectedOptionIndex!]
          : 'No answer';

  String get correctAnswerText =>
      question.options[question.correctOptionIndex];
}
