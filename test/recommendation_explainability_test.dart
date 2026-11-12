import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/question_attempt.dart';
import 'package:study_nest/screens/recommendations/recommendations_hub_screen.dart';
import 'package:study_nest/services/attempt_sync_service.dart';
import 'package:study_nest/services/mastery_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  group('Recommendations Hub explainability (V2 Stage 2.3)', () {
    test('buildMasteryReason formats real mastery and recent missed count', () {
      final base = DateTime.utc(2026, 11, 12, 12, 0, 0);
      final attempts = [
        QuestionAttempt(
          id: '1',
          questionId: 'c1',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 2500,
          hintUsed: false,
          answeredAt: base,
        ),
        QuestionAttempt(
          id: '2',
          questionId: 'c2',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: false,
          timeTakenMs: 3000,
          hintUsed: false,
          answeredAt: base.add(const Duration(seconds: 10)),
        ),
        QuestionAttempt(
          id: '3',
          questionId: 'c3',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: false,
          timeTakenMs: 3200,
          hintUsed: false,
          answeredAt: base.add(const Duration(seconds: 20)),
        ),
        QuestionAttempt(
          id: '4',
          questionId: 'c4',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: false,
          timeTakenMs: 3500,
          hintUsed: false,
          answeredAt: base.add(const Duration(seconds: 30)),
        ),
      ];

      expect(
        RecommendationEngine.buildMasteryReason(0.32, attempts),
        'Mastery 32%, missed 3 of your last 4 questions',
      );
    });

    testWidgets('RecommendationsHubScreen displays one-line reason from real mastery and attempts', (tester) async {
      SharedPreferences.setMockInitialValues({});
      RecommendationEngine.useBktMastery = true;

      for (var i = 0; i < 4; i++) {
        final attempt = await AttemptSyncService.logger.logAttempt(
          questionId: 'calc_$i',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: i == 0, // 1 correct, 3 missed in last 4
          timeTakenMs: 3000,
          hintUsed: false,
        );
        await MasteryService.tracker.recordAttempt(attempt);
      }

      final recs = await RecommendationEngine.getRankedRecommendations();
      expect(recs.length, 1);
      final expectedReason = recs.first.reason!;
      expect(expectedReason, contains('missed 3 of your last 4 questions'));

      await tester.pumpWidget(
        const MaterialApp(home: RecommendationsHubScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text(expectedReason), findsOneWidget);
    });

    test('signed-in user wrongCount and reason reflect user attempts when guest store is empty', () async {
      SharedPreferences.setMockInitialValues({});
      const userId = 'user-signed-in';

      for (var i = 0; i < 4; i++) {
        final attempt = await AttemptSyncService.logger.logAttempt(
          questionId: 'phys_$i',
          subject: 'Physics',
          topic: 'Forces & Laws',
          correct: i == 0, // 1 correct, 3 missed
          timeTakenMs: 3000,
          hintUsed: false,
          userIdOverride: userId,
        );
        await MasteryService.tracker.recordAttempt(
          attempt,
          userIdOverride: userId,
        );
      }

      // Confirm guest store is empty
      expect(await AttemptSyncService.logger.getAttempts(userId: null), isEmpty);

      final masteries = await MasteryService.tracker.getMasteries(userId: userId);
      final recs = await RecommendationEngine.rankByBktMastery(
        masteries,
        userId: userId,
      );

      expect(recs.length, 1);
      expect(recs.first.subject, 'Physics');
      expect(recs.first.topic, 'Forces & Laws');
      expect(recs.first.wrongCount, 3);
      expect(recs.first.priority, 'High priority');
      expect(recs.first.reason, contains('missed 3 of your last 4 questions'));
      expect(recs.first.reason, isNot(contains('no recent attempts yet')));
    });
  });
}
