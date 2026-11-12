import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/services/attempt_sync_service.dart';
import 'package:study_nest/services/mastery_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  group('RecommendationEngine BKT swap (V2 Stage 2.2)', () {
    tearDown(() {
      RecommendationEngine.useBktMastery = true;
    });

    test('priorityForMastery maps <0.4 High, 0.4-0.7 Medium, >0.7 Low', () {
      expect(RecommendationEngine.priorityForMastery(0.15), 'High priority');
      expect(RecommendationEngine.priorityForMastery(0.39), 'High priority');
      expect(RecommendationEngine.priorityForMastery(0.4), 'Medium');
      expect(RecommendationEngine.priorityForMastery(0.7), 'Medium');
      expect(RecommendationEngine.priorityForMastery(0.71), 'Low');
    });

    test('ranks lowest BKT mastery first and keeps old rules engine behind flag', () async {
      SharedPreferences.setMockInitialValues({});
      RecommendationEngine.useBktMastery = true;

      // Topic A: 2 wrong answers -> low mastery (< 0.4, High priority)
      for (var i = 0; i < 2; i++) {
        final attempt = await AttemptSyncService.logger.logAttempt(
          questionId: 'calc_$i',
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: false,
          timeTakenMs: 3000,
          hintUsed: false,
        );
        await MasteryService.tracker.recordAttempt(attempt);
        await RecommendationEngine.recordAnswer(
          subject: 'Calculus',
          topic: 'Derivatives',
          isCorrect: false,
        );
      }

      // Topic B: 3 correct answers -> high mastery (> 0.7, Low)
      for (var i = 0; i < 3; i++) {
        final attempt = await AttemptSyncService.logger.logAttempt(
          questionId: 'bio_$i',
          subject: 'Biology',
          topic: 'Genetics',
          correct: true,
          timeTakenMs: 3000,
          hintUsed: false,
        );
        await MasteryService.tracker.recordAttempt(attempt);
        await RecommendationEngine.recordAnswer(
          subject: 'Biology',
          topic: 'Genetics',
          isCorrect: true,
        );
      }

      final bktRanked = await RecommendationEngine.getRankedRecommendations();
      expect(bktRanked.length, 2);
      expect(bktRanked[0].subject, 'Calculus');
      expect(bktRanked[0].topic, 'Derivatives');
      expect(bktRanked[0].priority, 'High priority');
      expect(bktRanked[0].mastery, isNotNull);
      expect(bktRanked[0].mastery!, lessThan(0.4));

      expect(bktRanked[1].subject, 'Biology');
      expect(bktRanked[1].priority, 'Low');
      expect(bktRanked[1].mastery!, greaterThan(0.7));

      // Flipping flag to false falls back to V1 rules engine (no BKT mastery attached)
      RecommendationEngine.useBktMastery = false;
      final rulesRanked = await RecommendationEngine.getRankedRecommendations();
      expect(rulesRanked.length, 2);
      expect(rulesRanked[0].subject, 'Calculus');
      expect(rulesRanked[0].mastery, isNull);
    });
  });
}
