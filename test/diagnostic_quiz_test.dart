import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/data/quiz_questions.dart';
import 'package:study_nest/ml/question_selector.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/screens/quiz/quiz_results_screen.dart';
import 'package:study_nest/services/mastery_service.dart';

void main() {
  group('Diagnostic Pool Builder', () {
    test('buildDiagnosticPool returns exactly 8 questions', () {
      final pool = QuizQuestionBank.buildDiagnosticPool();
      expect(pool.length, 8);
    });

    test('buildDiagnosticPool selects exactly 2 questions per subject', () {
      final pool = QuestionSelector.buildDiagnosticPool();
      final countBySubject = <String, int>{};
      for (final q in pool) {
        countBySubject[q.subject] = (countBySubject[q.subject] ?? 0) + 1;
      }
      expect(countBySubject['Calculus'], 2);
      expect(countBySubject['Biology'], 2);
      expect(countBySubject['History'], 2);
      expect(countBySubject['Physics'], 2);
    });

    test('buildDiagnosticPool selects one difficulty 1 and one difficulty 2 per subject', () {
      final pool = QuizQuestionBank.buildDiagnosticPool();
      const subjects = ['Calculus', 'Biology', 'History', 'Physics'];
      for (final subject in subjects) {
        final subjectQs = pool.where((q) => q.subject == subject).toList();
        expect(subjectQs.length, 2);
        final difficulties = subjectQs.map((q) => q.difficulty).toSet();
        expect(difficulties, {1, 2}, reason: '$subject should have one diff 1 and one diff 2');
      }
    });

    test('buildDiagnosticPool selects distinct topics per subject where bank allows', () {
      final pool = QuizQuestionBank.buildDiagnosticPool();
      const subjects = ['Calculus', 'Biology', 'History', 'Physics'];
      for (final subject in subjects) {
        final subjectQs = pool.where((q) => q.subject == subject).toList();
        expect(
          subjectQs[0].topic,
          isNot(equals(subjectQs[1].topic)),
          reason: '$subject should test two distinct topics in diagnostic pool',
        );
      }
    });

    test('buildDiagnosticPool contains no duplicate question IDs', () {
      final pool = QuizQuestionBank.buildDiagnosticPool();
      final ids = pool.map((q) => q.id).toSet();
      expect(ids.length, 8);
    });

    test('buildDiagnosticPool order is mixed and not all of one subject first', () {
      final pool = QuizQuestionBank.buildDiagnosticPool();
      final subjects = pool.map((q) => q.subject).toList();
      // First two questions must not be the same subject
      expect(subjects[0], isNot(equals(subjects[1])));
      // The first 4 questions must span more than 1 subject
      expect(subjects.take(4).toSet().length, greaterThan(1));
    });

    test('buildDiagnosticPool supports custom Random generator', () {
      final seededPool = QuizQuestionBank.buildDiagnosticPool(random: Random(42));
      expect(seededPool.length, 8);
      final ids = seededPool.map((q) => q.id).toSet();
      expect(ids.length, 8);
    });
  });

  group('QuizScreen Diagnostic Mode', () {
    testWidgets('QuizScreen in diagnostic mode loads 8 questions and finishes to starting-level header', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(isDiagnostic: true),
        ),
      );
      await tester.pumpAndSettle();

      // Check first question progress
      expect(find.text('Question 1 of 8'), findsOneWidget);

      // Walk through all 8 questions
      for (var i = 1; i <= 8; i++) {
        expect(find.text('Question $i of 8'), findsOneWidget);

        // Tap the first available option card (Option A)
        final optionFinder = find.byKey(const Key('quiz_option_0'));
        await tester.ensureVisible(optionFinder);
        await tester.tap(optionFinder);
        await tester.pumpAndSettle();

        if (i < 8) {
          final nextBtn = find.text('Next question →');
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        } else {
          final finishBtn = find.text('Finish Quiz →');
          await tester.ensureVisible(finishBtn);
          await tester.tap(finishBtn);
          await tester.pumpAndSettle();
        }
      }

      // Assert QuizResultsScreen is displayed with diagnostic framing
      expect(find.byType(QuizResultsScreen), findsOneWidget);
      expect(find.text('Diagnostic complete — your starting level'), findsOneWidget);
      expect(find.text('Starting Level by Subject'), findsOneWidget);
    });

    testWidgets('a fresh guest diagnostic seeds real BKT mastery across multiple subjects', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(isDiagnostic: true),
        ),
      );
      await tester.pumpAndSettle();

      // Answer all 8 questions to complete diagnostic
      for (var i = 1; i <= 8; i++) {
        final optionFinder = find.byKey(const Key('quiz_option_0'));
        await tester.ensureVisible(optionFinder);
        await tester.tap(optionFinder);
        await tester.pumpAndSettle();

        if (i < 8) {
          final nextBtn = find.text('Next question →');
          await tester.ensureVisible(nextBtn);
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        } else {
          final finishBtn = find.text('Finish Quiz →');
          await tester.ensureVisible(finishBtn);
          await tester.tap(finishBtn);
          await tester.pumpAndSettle();
        }
      }

      // Verify BKT mastery map is populated with entries for multiple subjects
      final masteries = await MasteryService.tracker.getMasteries();
      expect(masteries.isNotEmpty, isTrue);

      final seededSubjects = masteries.values.map((m) => m.subject).toSet();
      expect(
        seededSubjects.length,
        greaterThan(1),
        reason: 'Diagnostic quiz questions span multiple subjects and should seed mastery for each',
      );
    });
  });
}
