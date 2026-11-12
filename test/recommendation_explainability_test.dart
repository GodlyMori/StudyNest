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
  });
}
