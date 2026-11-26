import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/question_attempt.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/services/mastery_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RecommendationEngine.useBktMastery = true;
  });

  group('Core Loop: Home Recommendations & Reviews Due', () {
    testWidgets('fresh user with no attempts shows empty state card and no fake topics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Fake hardcoded topics must NOT appear
      expect(find.text('Calculus — Derivatives'), findsNothing);
      expect(find.text('Biology — Cell Structure'), findsNothing);

      // Empty state card must appear
      expect(find.text('Take your first quiz to get your study plan'), findsOneWidget);
      expect(find.text('Take Assessment'), findsWidgets);

      // Reviews due shows all caught up
      expect(find.text("No reviews due — you're all caught up"), findsOneWidget);

      // Tapping Take Assessment in empty state opens QuizScreen
      final emptyStateButton = find.widgetWithText(ElevatedButton, 'Take Assessment');
      expect(emptyStateButton, findsOneWidget);
      await tester.ensureVisible(emptyStateButton);
      await tester.pumpAndSettle();
      await tester.tap(emptyStateButton);
      await tester.pumpAndSettle();
      expect(find.byType(QuizScreen), findsOneWidget);
    });

    testWidgets('with seeded mastery data the top card shows weakest topic (not Calculus by default)', (tester) async {
      // Seed Physics as weakest topic with incorrect attempts
      final wrongPhysics = QuestionAttempt(
        id: 'att-phys-1',
        userId: null,
        questionId: 'p-1',
        subject: 'Physics',
        topic: 'Forces & Laws',
        correct: false,
        answeredAt: DateTime.now().subtract(const Duration(minutes: 10)),
        timeTakenMs: 4000,
        hintUsed: false,
      );
      await MasteryService.tracker.recordAttempt(wrongPhysics);

      // Seed History with correct attempt (higher mastery)
      final correctHistory = QuestionAttempt(
        id: 'att-hist-1',
        userId: null,
        questionId: 'h-1',
        subject: 'History',
        topic: 'WW2 Causes',
        correct: true,
        answeredAt: DateTime.now().subtract(const Duration(minutes: 5)),
        timeTakenMs: 3000,
        hintUsed: false,
      );
      await MasteryService.tracker.recordAttempt(correctHistory);

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Top card must show Physics — Forces & Laws (weakest topic, not Calculus)
      expect(find.text('Physics — Forces & Laws'), findsOneWidget);
      expect(find.text('Calculus — Derivatives'), findsNothing);

      // Second card shows History — WW2 Causes
      expect(find.text('History — WW2 Causes'), findsOneWidget);

      // Tapping top card opens QuizScreen for Physics
      final topCard = find.text('Physics — Forces & Laws');
      await tester.ensureVisible(topCard);
      await tester.pumpAndSettle();
      await tester.tap(topCard);
      await tester.pumpAndSettle();
      expect(find.byType(QuizScreen), findsOneWidget);
    });

    testWidgets('Home displays reviews due count and taps through to Planner', (tester) async {
      // Seed an overdue review via SM-2
      await MasteryService.tracker.recordTopicReview(
        subject: 'Calculus',
        topic: 'Derivatives',
        correctCount: 6,
        totalCount: 10,
        reviewedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Reviews due row shows 1 review due today
      expect(find.text('1 review due today'), findsOneWidget);
      expect(find.text("No reviews due — you're all caught up"), findsNothing);

      // Tapping navigates to PlannerScreen
      final reviewRow = find.text('1 review due today');
      await tester.ensureVisible(reviewRow);
      await tester.pumpAndSettle();
      await tester.tap(reviewRow);
      await tester.pumpAndSettle();
      expect(find.byType(PlannerScreen), findsOneWidget);
    });
  });
}
