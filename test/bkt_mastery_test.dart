import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/ml/bkt_mastery.dart';
import 'package:study_nest/ml/mastery_store.dart';
import 'package:study_nest/ml/question_attempt.dart';

class _FakeMasteryRemoteSink implements MasteryRemoteSink {
  @override
  bool isReady;

  final List<TopicMastery> serverRows = [];

  _FakeMasteryRemoteSink({this.isReady = true});

  @override
  Future<List<TopicMastery>> fetchTopicMasteries(String userId) async {
    return serverRows.where((r) => r.userId == userId).toList();
  }

  @override
  Future<void> upsertTopicMasteries(List<Map<String, dynamic>> rows) async {
    for (final row in rows) {
      final parsed = TopicMastery.fromSupabaseRow(row);
      serverRows.removeWhere(
        (r) =>
            r.userId == parsed.userId &&
            r.subject == parsed.subject &&
            r.topic == parsed.topic,
      );
      serverRows.add(parsed);
    }
  }
}

void main() {
  group('BktModel (V2 Stage 2.1)', () {
    test('uses default BKT constants P(init)=0.3, P(learn)=0.15, P(slip)=0.1, P(guess)=0.25', () {
      expect(BktParams.defaultInit, 0.3);
      expect(BktParams.defaultLearn, 0.15);
      expect(BktParams.defaultSlip, 0.1);
      expect(BktParams.defaultGuess, 0.25);
    });

    test('mastery rises after correct answers and falls after wrong ones', () {
      const model = BktModel();
      const prior = BktParams.defaultInit; // 0.3

      final afterCorrect = model.updateMastery(prior, correct: true);
      expect(afterCorrect, greaterThan(prior));

      final afterSecondCorrect = model.updateMastery(afterCorrect, correct: true);
      expect(afterSecondCorrect, greaterThan(afterCorrect));

      final afterWrong = model.updateMastery(prior, correct: false);
      expect(afterWrong, lessThan(prior));

      final afterSecondWrong = model.updateMastery(afterWrong, correct: false);
      expect(afterSecondWrong, lessThan(afterWrong));
    });

    test('2/2 wrong differs from 6/10 wrong', () {
      const model = BktModel();

      // Sequence A: 2/2 wrong
      double m2of2 = BktParams.defaultInit;
      for (var i = 0; i < 2; i++) {
        m2of2 = model.updateMastery(m2of2, correct: false);
      }

      // Sequence B: 4 correct then 6 wrong (6/10 wrong overall)
      double m6of10 = BktParams.defaultInit;
      for (var i = 0; i < 4; i++) {
        m6of10 = model.updateMastery(m6of10, correct: true);
      }
      for (var i = 0; i < 6; i++) {
        m6of10 = model.updateMastery(m6of10, correct: false);
      }

      expect(m2of2, isNot(closeTo(m6of10, 1e-6)));
      expect(m6of10, lessThan(m2of2));
    });

    test('correct answer with hint gives smaller mastery gain than without hint', () {
      const model = BktModel();
      final noHint = model.updateMastery(0.3, correct: true, hintUsed: false);
      final withHint = model.updateMastery(0.3, correct: true, hintUsed: true);
      expect(withHint, lessThan(noHint));
    });

    test('MasteryTracker updates per attempt and rebuilds chronologically if topic_mastery is empty', () async {
      final storage = InMemoryMasteryStorage();
      final remote = _FakeMasteryRemoteSink(isReady: true);
      final tracker = MasteryTracker(
        storage: storage,
        remoteSink: remote,
        isOnline: () async => true,
        getCurrentUserId: () => 'user-1',
      );

      final t0 = DateTime.utc(2026, 11, 12, 10, 0, 0);
      final a1 = QuestionAttempt(
        id: 'a1',
        userId: 'user-1',
        questionId: 'calc_1',
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: false,
        timeTakenMs: 4200,
        hintUsed: false,
        answeredAt: t0,
      );
      final a2 = QuestionAttempt(
        id: 'a2',
        userId: 'user-1',
        questionId: 'calc_2',
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: true,
        timeTakenMs: 3100,
        hintUsed: false,
        answeredAt: t0.add(const Duration(seconds: 15)),
      );

      final m1 = await tracker.recordAttempt(a1);
      expect(m1.mastery, lessThan(BktParams.defaultInit));

      final m2 = await tracker.recordAttempt(a2);
      expect(m2.mastery, greaterThan(m1.mastery));
      expect(remote.serverRows.length, 1);

      // Simulate empty topic_mastery table & empty local cache -> rebuild from attempts
      remote.serverRows.clear();
      await storage.saveTopicMasteries('user-1', const {});

      final rebuilt = await tracker.getMasteries(
        userId: 'user-1',
        fallbackAttempts: [a2, a1], // intentionally out of order
      );
      final rebuiltDeriv = rebuilt[TopicMastery.topicKey('Calculus', 'Derivatives')]!;
      expect(rebuiltDeriv.mastery, closeTo(m2.mastery, 1e-9));
      expect(remote.serverRows.length, 1);
    });
  });
}
