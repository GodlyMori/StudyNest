import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/data/quiz_questions.dart';
import 'package:study_nest/screens/quiz/custom_quiz_screen.dart';
import 'package:study_nest/screens/quiz/topics_quizzes_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';

void main() {
  group('Task 5.2: Custom Quiz Setup and Execution', () {
    testWidgets('CustomQuizScreen renders initial configuration with subjects and topics',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );

      expect(find.text('Design Your Quiz'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Topics'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Number of Questions'), findsOneWidget);

      // Verify all 4 subjects exist
      expect(find.byKey(const Key('custom_quiz_subject_Calculus')), findsOneWidget);
      expect(find.byKey(const Key('custom_quiz_subject_Biology')), findsOneWidget);
      expect(find.byKey(const Key('custom_quiz_subject_History')), findsOneWidget);
      expect(find.byKey(const Key('custom_quiz_subject_Physics')), findsOneWidget);

      // Default should have 25 questions available for Calculus
      expect(find.textContaining('25 questions available'), findsOneWidget);
      expect(find.text('Start Quiz (10 Qs) →'), findsOneWidget);
    });

    testWidgets('Switching subject reloads subject-specific topics',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );

      // Tap Biology subject
      await tester.tap(find.byKey(const Key('custom_quiz_subject_Biology')));
      await tester.pumpAndSettle();

      // Check for a Biology topic (e.g. Genetics or Cell Biology)
      final bioQuestions = QuizQuestionBank.getQuestionsForSubject('Biology');
      final firstBioTopic = bioQuestions.first.topic;
      expect(find.text(firstBioTopic), findsWidgets);
    });

    testWidgets('Short pool shows clean notice and adjusts quiz size without repeats',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );

      // Select 'Hard only' difficulty for Calculus (there are ~5 hard questions out of 25)
      await tester.tap(find.byKey(const Key('custom_quiz_difficulty_3')));
      await tester.pumpAndSettle();

      // Select 10 questions preset
      await tester.tap(find.byKey(const Key('custom_quiz_length_10')));
      await tester.pumpAndSettle();

      // Verify short pool notice
      final hardCount = QuizQuestionBank.calculusQuestions
          .where((q) => q.difficulty == 3)
          .length;
      expect(
        find.textContaining('Only $hardCount questions match your filters — running a $hardCount-question quiz.'),
        findsOneWidget,
      );

      expect(find.text('Start Quiz ($hardCount Qs) →'), findsOneWidget);
    });

    testWidgets('Custom quiz starts and serves questions from the filtered pool adaptively',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );

      // Filter to Physics, Hard only
      await tester.tap(find.byKey(const Key('custom_quiz_subject_Physics')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('custom_quiz_difficulty_3')));
      await tester.pumpAndSettle();

      final hardPhysCount = QuizQuestionBank.physicsQuestions
          .where((q) => q.difficulty == 3)
          .length;

      final startButton = find.byKey(const Key('custom_quiz_start_button'));
      expect(startButton, findsOneWidget);
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify QuizScreen is active and showing a question
      expect(find.byType(QuizScreen), findsOneWidget);
      expect(find.text('Question 1 of $hardPhysCount'), findsOneWidget);
    });

    testWidgets('TopicsQuizzesScreen has Custom Quiz entry button leading to CustomQuizScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TopicsQuizzesScreen(),
        ),
      );

      final entryButton = find.byKey(const Key('custom_quiz_entry_button'));
      expect(entryButton, findsOneWidget);
      expect(find.text('Target specific topics, difficulty, and quiz length'), findsOneWidget);

      await tester.tap(entryButton);
      await tester.pumpAndSettle();

      expect(find.byType(CustomQuizScreen), findsOneWidget);
    });
    testWidgets('Empty selection disables Start Quiz button with explanatory notice',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );

      // Deselect all topics
      await tester.tap(find.byKey(const Key('custom_quiz_toggle_all_topics')));
      await tester.pumpAndSettle();

      // Notice should indicate 0 matching questions
      expect(
        find.text('No questions match your filters. Please select more topics or another difficulty.'),
        findsOneWidget,
      );

      final startButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('custom_quiz_start_button')),
      );
      expect(startButton.onPressed, isNull);
      expect(find.text('No Questions Available'), findsOneWidget);
    });
  });
}
