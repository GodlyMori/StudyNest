import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/question_attempt.dart';
import 'package:study_nest/ml/topic_progress_analytics.dart';
import 'package:study_nest/screens/profile/profile_screen.dart';
import 'package:study_nest/screens/quiz/topics_quizzes_screen.dart';
import 'package:study_nest/services/attempt_sync_service.dart';
import 'package:study_nest/widgets/topic_trend_line.dart';

void main() {
  group('Task 5.3: Progress Analytics (Mastery Over Time)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TopicProgressAnalytics pure Dart engine tracks mastery progression chronologically', () {
      const analytics = TopicProgressAnalytics();

      final attempts = [
        QuestionAttempt(
          id: 'a1',
          questionId: 'calc_1',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 3500,
          hintUsed: false,
          answeredAt: DateTime.utc(2026, 11, 10, 10, 0),
        ),
        QuestionAttempt(
          id: 'a2',
          questionId: 'calc_2',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 4000,
          hintUsed: false,
          answeredAt: DateTime.utc(2026, 11, 11, 10, 0),
        ),
        QuestionAttempt(
          id: 'a3',
          questionId: 'calc_3',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: false,
          timeTakenMs: 7000,
          hintUsed: false,
          answeredAt: DateTime.utc(2026, 11, 12, 10, 0),
        ),
      ];

      final derivativesProgress = analytics.computeTopicProgress(
        subject: 'Calculus',
        topic: 'Derivatives',
        attempts: attempts,
      );

      expect(derivativesProgress.hasAttempts, isTrue);
      expect(derivativesProgress.totalAttempts, equals(3));
      expect(derivativesProgress.points.length, equals(3));

      // After first correct: mastery increases from prior (0.3)
      final m1 = derivativesProgress.points[0].mastery;
      expect(m1, greaterThan(0.3));

      // After second correct: mastery increases further
      final m2 = derivativesProgress.points[1].mastery;
      expect(m2, greaterThan(m1));

      // After third incorrect: mastery drops
      final m3 = derivativesProgress.points[2].mastery;
      expect(m3, lessThan(m2));

      // Test topic with no attempts: empty state
      final integralsProgress = analytics.computeTopicProgress(
        subject: 'Calculus',
        topic: 'Integrals',
        attempts: attempts,
      );

      expect(integralsProgress.hasAttempts, isFalse);
      expect(integralsProgress.totalAttempts, equals(0));
      expect(integralsProgress.points, isEmpty);
      expect(integralsProgress.currentMastery, equals(0.0));
    });

    testWidgets('ProfileScreen displays trend lines for attempted topics and honest empty state for unattempted topics',
        (tester) async {
      // Seed guest attempts for 'Derivatives'
      await AttemptSyncService.logger.logAttempt(
        questionId: 'calc_1',
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: true,
        timeTakenMs: 3000,
        hintUsed: false,
      );
      await AttemptSyncService.logger.logAttempt(
        questionId: 'calc_2',
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: true,
        timeTakenMs: 2800,
        hintUsed: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('Topic mastery'), findsOneWidget);

      // Derivatives should show mastery % and trend line
      expect(find.byKey(const Key('topic_card_Derivatives')), findsOneWidget);
      expect(find.byKey(const Key('topic_trend_Derivatives')), findsOneWidget);
      expect(find.byType(TopicTrendLine), findsWidgets);

      // Unattempted topic (e.g. Limits or Integrals) must show 'No attempts yet'
      expect(find.text('No attempts yet'), findsWidgets);
    });

    testWidgets('Tapping a topic card navigates to TopicsQuizzesScreen',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final derivativesCard = find.byKey(const Key('topic_card_Derivatives'));
      expect(derivativesCard, findsOneWidget);

      await tester.tap(derivativesCard);
      await tester.pumpAndSettle();

      // Verified navigation to TopicsQuizzesScreen
      expect(find.byType(TopicsQuizzesScreen), findsOneWidget);
      expect(find.text('Quizzes & Topics'), findsOneWidget);
    });
  });
}
