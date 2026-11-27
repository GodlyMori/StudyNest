import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/bkt_mastery.dart';
import 'package:study_nest/models/quiz_question.dart';
import 'package:study_nest/models/topic_mastery_movement.dart';
import 'package:study_nest/screens/quiz/quiz_results_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/services/mastery_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TopicMasteryMovement — Unit Tests', () {
    test('computeMovements includes a topic that moved from before to after', () {
      final before = {
        'Biology::Cell Structure': TopicMastery(
          subject: 'Biology',
          topic: 'Cell Structure',
          mastery: 0.32, // 32%
          updatedAt: DateTime(2026, 11, 20),
        ),
      };

      final after = {
        'Biology::Cell Structure': TopicMastery(
          subject: 'Biology',
          topic: 'Cell Structure',
          mastery: 0.47, // 47%
          updatedAt: DateTime(2026, 11, 27),
        ),
      };

      final movements = TopicMasteryMovement.computeMovements(
        beforeMasteries: before,
        afterMasteries: after,
        attemptedTopics: ['Cell Structure'],
        topicSubjects: {'Cell Structure': 'Biology'},
      );

      expect(movements.length, equals(1));
      expect(movements.first.subject, equals('Biology'));
      expect(movements.first.topic, equals('Cell Structure'));
      expect(movements.first.beforePct, equals(32));
      expect(movements.first.afterPct, equals(47));
    });

    test('computeMovements excludes a first-time topic with no pre-quiz entry', () {
      final before = <String, TopicMastery>{}; // empty pre-quiz map

      final after = {
        'Calculus::Derivatives': TopicMastery(
          subject: 'Calculus',
          topic: 'Derivatives',
          mastery: 0.50,
          updatedAt: DateTime(2026, 11, 27),
        ),
      };

      final movements = TopicMasteryMovement.computeMovements(
        beforeMasteries: before,
        afterMasteries: after,
        attemptedTopics: ['Derivatives'],
        topicSubjects: {'Derivatives': 'Calculus'},
      );

      expect(movements, isEmpty);
    });

    test('computeMovements excludes a topic whose rounded percentages are equal', () {
      final before = {
        'Physics::Optics': TopicMastery(
          subject: 'Physics',
          topic: 'Optics',
          mastery: 0.451, // 45%
          updatedAt: DateTime(2026, 11, 20),
        ),
      };

      final after = {
        'Physics::Optics': TopicMastery(
          subject: 'Physics',
          topic: 'Optics',
          mastery: 0.454, // 45%
          updatedAt: DateTime(2026, 11, 27),
        ),
      };

      final movements = TopicMasteryMovement.computeMovements(
        beforeMasteries: before,
        afterMasteries: after,
        attemptedTopics: ['Optics'],
        topicSubjects: {'Optics': 'Physics'},
      );

      expect(movements, isEmpty);
    });
  });

  group('QuizResultsScreen — Movement Card Widget Tests', () {
    testWidgets('QuizResultsScreen displays moved topic with before% -> after%', (tester) async {
      const movement = TopicMasteryMovement(
        subject: 'Biology',
        topic: 'Cell Structure',
        beforePct: 32,
        afterPct: 47,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizResultsScreen(
            subject: 'Biology',
            score: 85,
            grade: 'Grade B',
            masteryMovements: [movement],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastery Progress'), findsOneWidget);
      expect(find.text('Biology — Cell Structure 32% → 47%'), findsOneWidget);
      expect(find.textContaining('32% → 47%'), findsOneWidget);
    });

    testWidgets('Empty masteryMovements shows no card and no placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QuizResultsScreen(
            subject: 'Biology',
            score: 85,
            grade: 'Grade B',
            masteryMovements: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastery Progress'), findsNothing);
      expect(find.textContaining('% →'), findsNothing);
    });

    testWidgets('Diagnostic mode does not display the mastery movement card', (tester) async {
      const movement = TopicMasteryMovement(
        subject: 'Biology',
        topic: 'Cell Structure',
        beforePct: 32,
        afterPct: 47,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizResultsScreen(
            subject: 'Diagnostic',
            score: 85,
            grade: 'Grade B',
            isDiagnostic: true,
            subjectMasteries: {'Biology': 47, 'Calculus': 50},
            masteryMovements: [movement],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mastery Progress'), findsNothing);
      expect(find.text('Starting Level by Subject'), findsOneWidget);
    });

    testWidgets('Full quiz flow: finishing quiz displays mastery movement card on results screen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed pre-quiz mastery for Calculus::Derivatives at 32%
      final preQuizMastery = TopicMastery(
        subject: 'Calculus',
        topic: 'Derivatives',
        mastery: 0.32,
        updatedAt: DateTime(2026, 11, 20),
      );
      await MasteryService.tracker.storage.saveTopicMasteries(
        null,
        {'Calculus::Derivatives': preQuizMastery},
      );

      final question = QuizQuestion(
        id: 'calc_test_movement',
        subject: 'Calculus',
        topic: 'Derivatives',
        difficulty: 1,
        questionText: 'What is the derivative of x^2?',
        options: ['2x', 'x', 'x^2', '2'],
        correctOptionIndex: 0,
        explanation: 'Power rule gives 2x.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizScreen(
            subject: 'Calculus',
            isAdaptive: false,
            customPool: [question],
            targetQuestionCount: 1,
            initialMasteries: {'Calculus::Derivatives': preQuizMastery},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap correct answer (option 0)
      final optionFinder = find.byKey(const Key('quiz_option_0'));
      expect(optionFinder, findsOneWidget);
      await tester.tap(optionFinder);
      await tester.pumpAndSettle();

      // Tap Finish button to finish quiz
      final finishFinder = find.bySemanticsLabel('Finish Quiz');
      expect(finishFinder, findsOneWidget);
      await tester.tap(finishFinder);
      await tester.pumpAndSettle();

      // Expect QuizResultsScreen with Mastery Progress card showing movement
      expect(find.byType(QuizResultsScreen), findsOneWidget);
      expect(find.text('Mastery Progress'), findsOneWidget);
      expect(find.textContaining('Calculus — Derivatives 32% →'), findsOneWidget);
    });
  });
}
