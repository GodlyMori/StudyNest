import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/data/quiz_questions.dart';
import 'package:study_nest/ml/question_selector.dart';
import 'package:study_nest/models/quiz_question.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';

void main() {
  group('QuestionSelector Adaptive Selection (V2 Stage 4.2)', () {
    test('higher mastery yields harder questions', () {
      // Create three questions of different difficulties in the same topic
      const qEasy = QuizQuestion(
        id: 'test_easy',
        subject: 'Calculus',
        topic: 'Derivatives',
        questionText: 'Easy derivative',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
        explanation: 'Easy explanation',
        difficulty: 1,
      );
      const qMed = QuizQuestion(
        id: 'test_med',
        subject: 'Calculus',
        topic: 'Derivatives',
        questionText: 'Medium derivative',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
        explanation: 'Medium explanation',
        difficulty: 2,
      );
      const qHard = QuizQuestion(
        id: 'test_hard',
        subject: 'Calculus',
        topic: 'Derivatives',
        questionText: 'Hard derivative',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
        explanation: 'Hard explanation',
        difficulty: 3,
      );
      final pool = [qEasy, qMed, qHard];

      // Low mastery (0.15) should pick Easy (difficulty 1)
      final lowPick = QuestionSelector.pickNextQuestion(
        availablePool: pool,
        servedInCurrentQuiz: {},
        topicMasteries: {'Derivatives': 0.15},
      );
      expect(lowPick?.difficulty, 1);

      // Medium mastery (0.50) should pick Medium (difficulty 2)
      final medPick = QuestionSelector.pickNextQuestion(
        availablePool: pool,
        servedInCurrentQuiz: {},
        topicMasteries: {'Derivatives': 0.50},
      );
      expect(medPick?.difficulty, 2);

      // High mastery (0.85) should pick Hard (difficulty 3)
      final highPick = QuestionSelector.pickNextQuestion(
        availablePool: pool,
        servedInCurrentQuiz: {},
        topicMasteries: {'Derivatives': 0.85},
      );
      expect(highPick?.difficulty, 3);
    });

    test('avoids repeating questions within the same quiz', () {
      const pool = QuizQuestionBank.calculusQuestions;
      final served = <String>{};

      for (var i = 0; i < pool.length; i++) {
        final q = QuestionSelector.pickNextQuestion(
          availablePool: pool,
          servedInCurrentQuiz: served,
        );
        expect(q, isNotNull);
        expect(served.contains(q!.id), isFalse, reason: 'Must not repeat in same quiz');
        served.add(q.id);
      }

      // Exhausted pool returns null
      final exhausted = QuestionSelector.pickNextQuestion(
        availablePool: pool,
        servedInCurrentQuiz: served,
      );
      expect(exhausted, isNull);
    });

    test('diagnostic quiz starts at medium difficulty (2)', () {
      final pool = QuizQuestionBank.getQuestionsForSubject('Diagnostic Quiz');
      final firstDiag = QuestionSelector.pickNextQuestion(
        availablePool: pool,
        servedInCurrentQuiz: {},
        isDiagnostic: true,
      );

      expect(firstDiag, isNotNull);
      expect(firstDiag!.difficulty, 2, reason: 'Diagnostic quiz must start at medium difficulty');
    });

    test('prefers questions not answered recently over recently attempted ones', () {
      const q1 = QuizQuestion(
        id: 'q_recent',
        subject: 'Calculus',
        topic: 'Derivatives',
        questionText: 'Recent question',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
        explanation: 'Exp',
        difficulty: 2,
      );
      const q2 = QuizQuestion(
        id: 'q_fresh',
        subject: 'Calculus',
        topic: 'Derivatives',
        questionText: 'Fresh question',
        options: ['A', 'B', 'C', 'D'],
        correctOptionIndex: 0,
        explanation: 'Exp',
        difficulty: 2,
      );

      final pick = QuestionSelector.pickNextQuestion(
        availablePool: [q1, q2],
        servedInCurrentQuiz: {},
        topicMasteries: {'Derivatives': 0.5},
        recentAttemptIds: ['q_recent'],
      );

      expect(pick?.id, 'q_fresh', reason: 'Fresh unattempted question must be preferred');
    });

    testWidgets('QuizScreen in adaptive mode loads and transitions smoothly through questions', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(subject: 'Calculus', isAdaptive: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 10'), findsOneWidget);

      // Verify options are clickable and feedback appears
      final firstOption = find.text('2x');
      expect(firstOption, findsOneWidget);
      await tester.tap(firstOption);
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Next question →'), findsOneWidget);

      await tester.ensureVisible(find.text('Next question →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next question →'));
      await tester.pumpAndSettle();

      expect(find.text('Question 2 of 10'), findsOneWidget);
    });
  });
}
