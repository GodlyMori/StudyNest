import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/question_attempt.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/profile/profile_screen.dart';
import 'package:study_nest/services/attempt_sync_service.dart';
import 'package:study_nest/services/xp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 1: XpService XP Rules & Replay', () {
    test('XP rule: easy correct = 10, medium correct = 15, hard correct = 20, wrong = 0 at any difficulty', () {
      final now = DateTime.now().toUtc();

      final easyCorrect = QuestionAttempt(
        id: '1',
        questionId: 'calc_1', // difficulty 1
        subject: 'Calculus',
        topic: 'Derivatives',
        correct: true,
        timeTakenMs: 2000,
        hintUsed: false,
        answeredAt: now,
      );
      final medCorrect = QuestionAttempt(
        id: '2',
        questionId: 'calc_2', // difficulty 2
        subject: 'Calculus',
        topic: 'Limits',
        correct: true,
        timeTakenMs: 2000,
        hintUsed: false,
        answeredAt: now,
      );
      final hardCorrect = QuestionAttempt(
        id: '3',
        questionId: 'calc_8', // difficulty 3
        subject: 'Calculus',
        topic: 'Integrals',
        correct: true,
        timeTakenMs: 2000,
        hintUsed: false,
        answeredAt: now,
      );

      final easyWrong = easyCorrect.copyWith(id: '4', correct: false);
      final medWrong = medCorrect.copyWith(id: '5', correct: false);
      final hardWrong = hardCorrect.copyWith(id: '6', correct: false);

      expect(XpService.xpForAttempt(easyCorrect), equals(10));
      expect(XpService.xpForAttempt(medCorrect), equals(15));
      expect(XpService.xpForAttempt(hardCorrect), equals(20));

      expect(XpService.xpForAttempt(easyWrong), equals(0));
      expect(XpService.xpForAttempt(medWrong), equals(0));
      expect(XpService.xpForAttempt(hardWrong), equals(0));
    });

    test('XP rule: perfect quiz adds +20, imperfect quiz adds no bonus', () {
      final t0 = DateTime.utc(2026, 11, 26, 10, 0, 0);

      // Quiz 1 (imperfect: 1 easy correct = 10, 1 hard wrong = 0 -> 10 total)
      final quiz1 = [
        QuestionAttempt(
          id: 'q1_1',
          quizId: 'quiz_1',
          questionId: 'calc_1', // difficulty 1
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 1000,
          hintUsed: false,
          answeredAt: t0,
        ),
        QuestionAttempt(
          id: 'q1_2',
          quizId: 'quiz_1',
          questionId: 'calc_8', // difficulty 3
          subject: 'Calculus',
          topic: 'Integrals',
          correct: false,
          timeTakenMs: 1000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(seconds: 10)),
        ),
      ];

      // Quiz 2 (perfect: 1 medium correct = 15, 1 hard correct = 20 -> 35 + 20 bonus = 55 total)
      final quiz2 = [
        QuestionAttempt(
          id: 'q2_1',
          quizId: 'quiz_2',
          questionId: 'calc_2', // difficulty 2
          subject: 'Calculus',
          topic: 'Limits',
          correct: true,
          timeTakenMs: 1000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(hours: 1)),
        ),
        QuestionAttempt(
          id: 'q2_2',
          quizId: 'quiz_2',
          questionId: 'calc_8', // difficulty 3
          subject: 'Calculus',
          topic: 'Integrals',
          correct: true,
          timeTakenMs: 1000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(hours: 1, seconds: 15)),
        ),
      ];

      expect(XpService.computeTotalXp(quiz1), equals(10), reason: 'Imperfect quiz gets no bonus');
      expect(XpService.computeTotalXp(quiz2), equals(55), reason: 'Perfect quiz gets +20 bonus (15 + 20 + 20 = 55)');
    });

    test('Level thresholds: 0 XP -> Level 1, 99 -> 1, 100 -> 2, 250 -> 3', () {
      expect(XpService.levelFor(0), equals(1));
      expect(XpService.levelFor(99), equals(1));
      expect(XpService.levelFor(100), equals(2));
      expect(XpService.levelFor(249), equals(2));
      expect(XpService.levelFor(250), equals(3));
      expect(XpService.levelFor(450), equals(4));
      expect(XpService.levelFor(700), equals(5));
      expect(XpService.levelFor(1000), equals(6));
    });

    test('Backfill: seeded attempts (mixed difficulties, some wrong, one perfect quiz) produce the exact expected total', () {
      final t0 = DateTime.utc(2026, 11, 25, 9, 0, 0);

      // Quiz 1 (imperfect session):
      // - easy correct = 10
      // - medium correct = 15
      // - hard wrong = 0
      // Quiz 1 sum = 25 (no bonus)
      final q1Attempts = [
        QuestionAttempt(
          id: 'a1',
          quizId: 'session_1',
          questionId: 'calc_1', // easy (1)
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0,
        ),
        QuestionAttempt(
          id: 'a2',
          quizId: 'session_1',
          questionId: 'calc_2', // medium (2)
          subject: 'Calculus',
          topic: 'Limits',
          correct: true,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(seconds: 20)),
        ),
        QuestionAttempt(
          id: 'a3',
          quizId: 'session_1',
          questionId: 'calc_8', // hard (3)
          subject: 'Calculus',
          topic: 'Integrals',
          correct: false,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(seconds: 40)),
        ),
      ];

      // Quiz 2 (perfect quiz session):
      // - easy correct = 10
      // - medium correct = 15
      // - hard correct = 20
      // Perfect bonus = +20
      // Quiz 2 sum = 10 + 15 + 20 + 20 = 65
      final q2Attempts = [
        QuestionAttempt(
          id: 'b1',
          quizId: 'session_2',
          questionId: 'calc_1', // easy (1)
          difficulty: 1,
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(days: 1)),
        ),
        QuestionAttempt(
          id: 'b2',
          quizId: 'session_2',
          questionId: 'calc_2', // medium (2)
          difficulty: 2,
          subject: 'Calculus',
          topic: 'Limits',
          correct: true,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(days: 1, seconds: 20)),
        ),
        QuestionAttempt(
          id: 'b3',
          quizId: 'session_2',
          questionId: 'calc_8', // hard (3)
          difficulty: 3,
          subject: 'Calculus',
          topic: 'Integrals',
          correct: true,
          timeTakenMs: 2000,
          hintUsed: false,
          answeredAt: t0.add(const Duration(days: 1, seconds: 40)),
        ),
      ];

      final combined = [...q1Attempts, ...q2Attempts];
      // Expected total: 25 + 65 = 90 XP
      expect(XpService.computeTotalXp(combined), equals(90));
      // Replaying empty attempts gives 0
      expect(XpService.computeTotalXp([]), equals(0));
    });
  });

  group('Task 2 & 3: UI Displays & Migration', () {
    testWidgets('Home chip test: with a seeded XP total, the chip shows that total, not 1,240', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      // Seed 350 XP
      await prefs.setInt(XpService.guestXpKey, 350);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final xpChipFinder = find.byKey(const Key('home_xp_chip_text'));
      expect(xpChipFinder, findsOneWidget);

      final xpText = tester.widget<Text>(xpChipFinder);
      expect(xpText.data, equals('350 XP'));
      expect(find.text('1,240 XP'), findsNothing, reason: 'Hardcoded 1,240 XP must be replaced with real value');
    });

    testWidgets('Profile screen displays derived level and real XP, never Level 6 for fresh student', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      // 100 XP -> Level 2
      await prefs.setInt(XpService.guestXpKey, 100);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Expect Level 2 and 100 XP
      expect(find.textContaining('Level 2'), findsOneWidget);
      expect(find.textContaining('100 XP'), findsOneWidget);
      expect(find.textContaining('Level 6'), findsNothing, reason: 'Signed-in or guest student without XP must not see Level 6');
    });

    test('Register migration: guest XP earned before registering is still counted after registering', () async {
      final prefs = await SharedPreferences.getInstance();
      const testUserId = 'test_registered_user_id';

      // 1. Log guest attempts
      final t0 = DateTime.utc(2026, 11, 26, 8, 0, 0);
      final guestAttempts = [
        QuestionAttempt(
          id: 'g1',
          quizId: 'guest_q1',
          questionId: 'calc_1', // easy = 10
          subject: 'Calculus',
          topic: 'Derivatives',
          correct: true,
          timeTakenMs: 1500,
          hintUsed: false,
          answeredAt: t0,
        ),
        QuestionAttempt(
          id: 'g2',
          quizId: 'guest_q1',
          questionId: 'calc_2', // medium = 15
          subject: 'Calculus',
          topic: 'Limits',
          correct: true,
          timeTakenMs: 1500,
          hintUsed: false,
          answeredAt: t0.add(const Duration(seconds: 15)),
        ),
      ];

      // Save as guest attempts
      await AttemptSyncService.logger.storage.saveGuestAttempts(guestAttempts);
      final guestXp = await XpService.recomputeAndSave(userId: null);
      // Perfect quiz: 10 + 15 + 20 bonus = 45 XP
      expect(guestXp, equals(45));
      expect(prefs.getInt(XpService.guestXpKey), equals(45));

      // 2. Simulate account migration
      await AttemptSyncService.logger.migrateGuestAttempts(testUserId);
      await XpService.migrateGuestXp(testUserId);

      // 3. Verify user has the 45 XP and guest XP key is cleared
      final userTotal = await XpService.getTotalXp(userId: testUserId);
      expect(userTotal, equals(45));
      expect(prefs.getInt(XpService.guestXpKey), isNull, reason: 'Guest XP key must be cleared on migration');
      expect(prefs.getInt('${XpService.userXpPrefix}$testUserId'), equals(45));
    });
  });
}
