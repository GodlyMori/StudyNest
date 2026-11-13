import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/models/quiz_question.dart';
import 'package:study_nest/models/question_review_item.dart';
import 'package:study_nest/screens/quiz/quiz_review_screen.dart';
import 'package:study_nest/screens/quiz/quiz_results_screen.dart';

void main() {
  group('Task 5.1: Question-Level Review View', () {
    const q1 = QuizQuestion(
      id: 'calc_test_1',
      subject: 'Calculus',
      topic: 'Derivatives',
      difficulty: 1,
      questionText: 'What is the derivative of x^2?',
      options: ['2x', 'x', 'x^2', '2'],
      correctOptionIndex: 0,
      explanation: 'The power rule gives d/dx(x^2) = 2x.',
    );

    const q2 = QuizQuestion(
      id: 'calc_test_2',
      subject: 'Calculus',
      topic: 'Limits',
      difficulty: 2,
      questionText: 'What is lim x->0 of sin(x)/x?',
      options: ['0', '1', 'Infinity', 'Undefined'],
      correctOptionIndex: 1,
      explanation: 'By standard limit theorem, lim x->0 sin(x)/x = 1.',
    );

    const q3 = QuizQuestion(
      id: 'calc_test_3',
      subject: 'Calculus',
      topic: 'Integrals',
      difficulty: 3,
      questionText: 'What is the integral of 1/x dx?',
      options: ['ln|x| + C', '1/x^2 + C', 'e^x + C', 'x + C'],
      correctOptionIndex: 0,
      explanation: 'The antiderivative of 1/x is ln|x| + C.',
    );

    final sampleItems = [
      // q1 answered correctly
      const QuestionReviewItem(
        question: q1,
        selectedOptionIndex: 0,
        isCorrect: true,
        hintUsed: false,
        timeTakenMs: 4500,
      ),
      // q2 answered incorrectly
      const QuestionReviewItem(
        question: q2,
        selectedOptionIndex: 0, // answered '0' instead of '1'
        isCorrect: false,
        hintUsed: true,
        timeTakenMs: 9200,
      ),
      // q3 answered correctly
      const QuestionReviewItem(
        question: q3,
        selectedOptionIndex: 0,
        isCorrect: true,
        hintUsed: false,
        timeTakenMs: 6100,
      ),
    ];

    testWidgets('renders all questions with question text, answers, and explanations',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizReviewScreen(
            subject: 'Calculus',
            reviewItems: sampleItems,
          ),
        ),
      );

      // Verify header and summary metrics
      expect(find.text('Calculus Review'), findsOneWidget);
      expect(find.text('Total Questions'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Correct'), findsWidgets);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Missed'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Verify question texts are visible
      expect(find.text('What is the derivative of x^2?'), findsOneWidget);
      expect(find.text('What is lim x->0 of sin(x)/x?'), findsOneWidget);
      expect(find.text('What is the integral of 1/x dx?'), findsOneWidget);

      // Verify explanations are visible
      expect(find.text('The power rule gives d/dx(x^2) = 2x.'), findsOneWidget);
      expect(find.text('By standard limit theorem, lim x->0 sin(x)/x = 1.'), findsOneWidget);
      expect(find.text('The antiderivative of 1/x is ln|x| + C.'), findsOneWidget);
    });

    testWidgets('sorts missed questions first and highlights them with correct answer',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizReviewScreen(
            subject: 'Calculus',
            reviewItems: sampleItems,
          ),
        ),
      );

      // Verify badges and labels
      expect(find.text('Missed'), findsNWidgets(2)); // 1 in summary + 1 badge
      expect(find.text('Correct'), findsNWidgets(3)); // 1 in summary + 2 badges

      // For missed question q2: both "Your Answer: 0" and "Correct Answer: 1" should appear
      expect(find.text('Your Answer: '), findsNWidgets(3));
      expect(find.text('Correct Answer: '), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Ensure missed question appears before the correct questions in the widget hierarchy
      final missedFinder = find.text('What is lim x->0 of sin(x)/x?');
      final firstCorrectFinder = find.text('What is the derivative of x^2?');

      final missedTop = tester.getTopLeft(missedFinder).dy;
      final correctTop = tester.getTopLeft(firstCorrectFinder).dy;
      expect(missedTop, lessThan(correctTop),
          reason: 'Missed questions must appear first');
    });

    testWidgets('QuizResultsScreen has review button that opens QuizReviewScreen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizResultsScreen(
            subject: 'Calculus',
            score: 67,
            grade: 'Grade D',
            reviewItems: sampleItems,
          ),
        ),
      );

      final reviewButton = find.byKey(const Key('review_questions_button'));
      expect(reviewButton, findsOneWidget);
      expect(find.text('Review Questions'), findsOneWidget);
      expect(find.text('3 questions answered'), findsOneWidget);

      // Tap to navigate to review view
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      expect(find.byType(QuizReviewScreen), findsOneWidget);
      expect(find.text('Calculus Review'), findsOneWidget);
    });
  });
}
