import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/profile/profile_screen.dart';
import 'package:study_nest/screens/profile/settings_screen.dart';
import 'package:study_nest/services/guest_score_service.dart';
import 'package:study_nest/services/streak_service.dart';

void main() {
  group('Task 5.4: Daily Goal and Streak Freeze', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('streak counts consecutive active days from real dates and breaks on missed day', () {
      final now = DateTime(2026, 11, 13, 12, 0); // Friday
      final todayStr = StreakService.formatDate(now);
      final yesterdayStr = StreakService.formatDate(now.subtract(const Duration(days: 1)));
      final twoDaysAgoStr = StreakService.formatDate(now.subtract(const Duration(days: 2)));

      // 1. Consecutive active days (Today + Yesterday + 2 days ago)
      final streak3 = StreakService.calculateStreak(
        activeDates: {todayStr, yesterdayStr, twoDaysAgoStr},
        frozenDates: {},
        today: now,
      );
      expect(streak3, equals(3));

      // 2. Active yesterday + 2 days ago, but no activity yet today -> streak maintained
      final streak2 = StreakService.calculateStreak(
        activeDates: {yesterdayStr, twoDaysAgoStr},
        frozenDates: {},
        today: now,
      );
      expect(streak2, equals(2));

      // 3. Active 2 days ago, but missed yesterday and no activity today -> broken (0)
      final streakBroken = StreakService.calculateStreak(
        activeDates: {twoDaysAgoStr},
        frozenDates: {},
        today: now,
      );
      expect(streakBroken, equals(0));
    });

    test('missed day is protected when a streak freeze is spent', () {
      final now = DateTime(2026, 11, 13, 12, 0);
      final yesterdayStr = StreakService.formatDate(now.subtract(const Duration(days: 1)));
      final twoDaysAgoStr = StreakService.formatDate(now.subtract(const Duration(days: 2)));

      // Active 2 days ago, missed yesterday, but yesterday is in frozenDates
      final streakSaved = StreakService.calculateStreak(
        activeDates: {twoDaysAgoStr},
        frozenDates: {yesterdayStr},
        today: now,
      );
      expect(streakSaved, equals(2));
    });

    test('freeze guard: spending a freeze with no prior activity is refused', () async {
      final friday = DateTime(2026, 11, 13, 10, 0);

      // Attempting to spend a freeze with no prior activity must be refused
      final refused = await StreakService.spendStreakFreeze(
        completedQuizTimestamps: [],
        now: friday,
      );
      expect(refused, isFalse, reason: 'Must not manufacture a streak from zero prior activity');
    });

    test('only one freeze per week is allowed and allowance resets across weeks', () async {
      final wednesdayWeek1 = DateTime(2026, 11, 11, 10, 0);
      final fridayWeek1 = DateTime(2026, 11, 13, 10, 0);
      final saturdayWeek1 = DateTime(2026, 11, 14, 10, 0);
      final tuesdayWeek2 = DateTime(2026, 11, 17, 10, 0);

      // Spend first freeze on Friday of Week 1 with Wednesday activity -> succeeds
      final firstSpend = await StreakService.spendStreakFreeze(
        completedQuizTimestamps: [wednesdayWeek1],
        now: fridayWeek1,
      );
      expect(firstSpend, isTrue);

      // Verify 0 freezes remaining in Week 1
      final dataSat = await StreakService.computeStreakData(
        completedQuizTimestamps: [wednesdayWeek1],
        now: saturdayWeek1,
      );
      expect(dataSat.freezesRemaining, equals(0));

      // Attempting second freeze in the same week fails
      final secondSpend = await StreakService.spendStreakFreeze(
        completedQuizTimestamps: [wednesdayWeek1],
        now: saturdayWeek1,
      );
      expect(secondSpend, isFalse);

      // Next week (Week 2): freeze allowance resets to 1
      final dataWeek2 = await StreakService.computeStreakData(
        completedQuizTimestamps: [wednesdayWeek1],
        now: tuesdayWeek2,
      );
      expect(dataWeek2.freezesRemaining, equals(1));
    });

    test('daily goal progress reflects today completed quizzes and setting persists', () async {
      await StreakService.setDailyGoal(2);
      expect(await StreakService.getDailyGoal(), equals(2));

      final now = DateTime.now();
      final todayTimestamp = now;
      final yesterdayTimestamp = now.subtract(const Duration(days: 1));

      final data = await StreakService.computeStreakData(
        completedQuizTimestamps: [todayTimestamp, yesterdayTimestamp],
        now: now,
      );

      expect(data.todayQuizzesCompleted, equals(1));
      expect(data.dailyGoal, equals(2));
      expect(data.isGoalMet, isFalse);
    });

    testWidgets('ProfileScreen shows real streak, daily goal progress, and freeze action',
        (tester) async {
      // Save 1 guest score for today
      await GuestScoreService.saveGuestScore(
        subject: 'Calculus',
        score: 90,
        grade: 'Grade A',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Real streak count displayed (1 day since 1 quiz taken today)
      expect(find.text('1-Day Streak • Active Goal'), findsOneWidget);
      expect(find.byKey(const Key('streak_count_text')), findsOneWidget);
      expect(find.text('1-day streak'), findsOneWidget);

      // Daily goal progress displayed
      expect(find.byKey(const Key('daily_goal_progress_text')), findsOneWidget);
      expect(find.text('1 of 1 quizzes done today'), findsOneWidget);

      // Freeze status displayed
      expect(find.byKey(const Key('streak_freeze_remaining_text')), findsOneWidget);
      expect(find.text('1 freeze available this week'), findsOneWidget);
    });

    testWidgets('SettingsScreen allows adjusting daily quiz goal',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Quiz Goal'), findsOneWidget);
      expect(find.text('Target: 1 quiz per day'), findsOneWidget);

      // Scroll to dropdown and select '3 quizzes'
      final dropdown = find.byKey(const Key('daily_goal_dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      await tester.tap(find.text('3 quizzes').last);
      await tester.pumpAndSettle();

      expect(find.text('Target: 3 quizzes per day'), findsOneWidget);
      expect(await StreakService.getDailyGoal(), equals(3));
    });

    testWidgets('HomeScreen streak chip displays real streak from StreakService',
        (tester) async {
      // 1. Initial zero streak
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home_streak_chip_text')), findsOneWidget);
      expect(find.text('0-Day Streak'), findsOneWidget);

      // 2. Add quiz score for today -> streak becomes 1
      await GuestScoreService.saveGuestScore(
        subject: 'Calculus',
        score: 85,
        grade: 'Grade B',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(key: Key('home_screen_second')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1-Day Streak'), findsOneWidget);
    });
  });
}
