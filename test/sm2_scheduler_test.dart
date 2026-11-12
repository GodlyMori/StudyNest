import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/bkt_mastery.dart';
import 'package:study_nest/ml/mastery_store.dart';
import 'package:study_nest/ml/sm2_scheduler.dart';
import 'package:study_nest/services/recommendation_engine.dart';

class _NoopRemoteSink implements MasteryRemoteSink {
  @override
  bool get isReady => false;

  @override
  Future<List<TopicMastery>> fetchTopicMasteries(String userId) async => [];

  @override
  Future<void> upsertTopicMasteries(List<Map<String, dynamic>> rows) async {}
}

void main() {
  group('Sm2Scheduler (V2 Stage 3.1)', () {
    test('intervals grow 1 -> 6 -> prev*ease on good recall and reset on failure', () {
      final t0 = DateTime.utc(2026, 11, 1, 10, 0, 0);

      // 1st successful review (quality 4): interval = 1 day
      final s1 = Sm2Scheduler.scheduleNext(
        quality: 4,
        reviewedAt: t0,
      );
      expect(s1.repetitions, 1);
      expect(s1.intervalDays, 1);
      expect(s1.ease, closeTo(2.5, 1e-9));
      expect(s1.nextReviewAt, t0.add(const Duration(days: 1)));

      // 2nd successful review (quality 5): interval = 6 days, ease increases
      final t1 = t0.add(const Duration(days: 1));
      final s2 = Sm2Scheduler.scheduleNext(
        ease: s1.ease,
        intervalDays: s1.intervalDays,
        repetitions: s1.repetitions,
        quality: 5,
        reviewedAt: t1,
      );
      expect(s2.repetitions, 2);
      expect(s2.intervalDays, 6);
      expect(s2.ease, closeTo(2.6, 1e-9));
      expect(s2.nextReviewAt, t1.add(const Duration(days: 6)));

      // 3rd successful review (quality 4): interval = round(6 * 2.6) = 16 days
      final t2 = t1.add(const Duration(days: 6));
      final s3 = Sm2Scheduler.scheduleNext(
        ease: s2.ease,
        intervalDays: s2.intervalDays,
        repetitions: s2.repetitions,
        quality: 4,
        reviewedAt: t2,
      );
      expect(s3.repetitions, 3);
      expect(s3.intervalDays, 16);
      expect(s3.nextReviewAt, t2.add(const Duration(days: 16)));

      // Failed review (quality 1): resets repetitions to 0 and interval to 1 day
      final t3 = t2.add(const Duration(days: 16));
      final sFail = Sm2Scheduler.scheduleNext(
        ease: s3.ease,
        intervalDays: s3.intervalDays,
        repetitions: s3.repetitions,
        quality: 1,
        reviewedAt: t3,
      );
      expect(sFail.repetitions, 0);
      expect(sFail.intervalDays, 1);
      expect(sFail.ease, greaterThanOrEqualTo(Sm2Scheduler.minEase));
      expect(sFail.nextReviewAt, t3.add(const Duration(days: 1)));
    });

    test('due-date computation and qualityFromQuizPerformance mapping work accurately', () {
      expect(
        Sm2Scheduler.qualityFromQuizPerformance(correctCount: 9, totalCount: 10),
        5,
      );
      expect(
        Sm2Scheduler.qualityFromQuizPerformance(correctCount: 8, totalCount: 10),
        4,
      );
      expect(
        Sm2Scheduler.qualityFromQuizPerformance(correctCount: 6, totalCount: 10),
        3,
      );
      expect(
        Sm2Scheduler.qualityFromQuizPerformance(correctCount: 2, totalCount: 10),
        1,
      );

      final now = DateTime.utc(2026, 11, 12, 12, 0, 0);
      expect(Sm2Scheduler.isDue(now.subtract(const Duration(hours: 1)), now: now), isTrue);
      expect(Sm2Scheduler.isDue(now, now: now), isTrue);
      expect(Sm2Scheduler.isDue(now.add(const Duration(hours: 1)), now: now), isFalse);
      expect(Sm2Scheduler.isDue(null, now: now), isFalse);
    });

    test('MasteryTracker.recordTopicReview persists schedule and getDueTopics returns overdue topics', () async {
      final tracker = MasteryTracker(
        storage: InMemoryMasteryStorage(),
        remoteSink: _NoopRemoteSink(),
        isOnline: () async => false,
        getCurrentUserId: () => null,
      );

      final reviewedAt = DateTime.utc(2026, 11, 10, 9, 0, 0);
      final updated = await tracker.recordTopicReview(
        subject: 'Calculus',
        topic: 'Derivatives',
        correctCount: 8,
        totalCount: 10,
        reviewedAt: reviewedAt,
      );

      expect(updated.intervalDays, 1);
      expect(updated.nextReviewAt, reviewedAt.add(const Duration(days: 1)));

      // Not due yet on Nov 10
      expect(
        await tracker.getDueTopics(asOf: reviewedAt),
        isEmpty,
      );

      // Due on Nov 12
      final due = await tracker.getDueTopics(
        asOf: DateTime.utc(2026, 11, 12, 9, 0, 0),
      );
      expect(due.length, 1);
      expect(due.first.topic, 'Derivatives');
    });

    test('RecommendationEngine ranks lowest mastery first, and among similar mastery ranks most overdue first', () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.utc(2026, 11, 12, 12, 0, 0);

      final masteries = <String, TopicMastery>{
        // Similar mastery ~0.31-0.32, but Topic B is 3 days overdue vs Topic A due in 2 days
        'Calculus::Derivatives': TopicMastery(
          subject: 'Calculus',
          topic: 'Derivatives',
          mastery: 0.31,
          updatedAt: now,
          nextReviewAt: now.add(const Duration(days: 2)),
        ),
        'Physics::Forces & Laws': TopicMastery(
          subject: 'Physics',
          topic: 'Forces & Laws',
          mastery: 0.32,
          updatedAt: now,
          nextReviewAt: now.subtract(const Duration(days: 3)),
        ),
        // Much lower mastery (0.15) should still rank #1 overall
        'Biology::Genetics': TopicMastery(
          subject: 'Biology',
          topic: 'Genetics',
          mastery: 0.15,
          updatedAt: now,
          nextReviewAt: now.add(const Duration(days: 5)),
        ),
      };

      final ranked = await RecommendationEngine.rankByBktMastery(
        masteries,
        now: now,
      );

      expect(ranked.map((r) => r.topic).toList(), [
        'Genetics', // lowest mastery (0.15)
        'Forces & Laws', // similar mastery (0.32 vs 0.31), most overdue (-3d)
        'Derivatives', // similar mastery, due in +2d
      ]);
    });
  });
}
