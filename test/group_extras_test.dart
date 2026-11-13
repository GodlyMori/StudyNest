import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/models/group_member.dart';
import 'package:study_nest/models/study_group.dart';
import 'package:study_nest/screens/groups/group_detail_screen.dart';
import 'package:study_nest/services/group_extras_service.dart';
import 'package:study_nest/services/group_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GroupService.resetToDefaults();
  });

  group('GroupExtrasService - Leaderboard & Challenges', () {
    test('ranks members with real quiz scores and displays honest empty state for unranked members', () async {
      await GroupExtrasService.clearAll('group_calc_crew');

      const members = [
        GroupMember(id: 'm1', groupId: 'group_calc_crew', userId: 'user_maya', name: 'Maya Santos', role: 'Admin'),
        GroupMember(id: 'm2', groupId: 'group_calc_crew', userId: 'user_jonas', name: 'Jonas Reyes', role: 'Member'),
        GroupMember(id: 'm3', groupId: 'group_calc_crew', userId: 'user_sofia', name: 'Sofia Cruz', role: 'Member'),
      ];

      // Give Maya 90% and 80% (avg 85%)
      await GroupExtrasService.recordMemberScore(userId: 'user_maya', subject: 'Calculus', score: 90);
      await GroupExtrasService.recordMemberScore(userId: 'user_maya', subject: 'Calculus', score: 80);

      // Give Sofia 95% (avg 95%)
      await GroupExtrasService.recordMemberScore(userId: 'user_sofia', subject: 'Calculus', score: 95);

      // Jonas has 0 scores

      final leaderboard = await GroupExtrasService.getGroupLeaderboard('group_calc_crew', members);

      expect(leaderboard.length, 3);

      // #1 Sofia Cruz: 95% avg
      expect(leaderboard[0].name, 'Sofia Cruz');
      expect(leaderboard[0].hasScores, isTrue);
      expect(leaderboard[0].averageScore, 95.0);
      expect(leaderboard[0].quizCount, 1);

      // #2 Maya Santos: 85% avg
      expect(leaderboard[1].name, 'Maya Santos');
      expect(leaderboard[1].hasScores, isTrue);
      expect(leaderboard[1].averageScore, 85.0);
      expect(leaderboard[1].quizCount, 2);

      // #3 Jonas Reyes: no scores ("No quizzes yet")
      expect(leaderboard[2].name, 'Jonas Reyes');
      expect(leaderboard[2].hasScores, isFalse);
      expect(leaderboard[2].averageScore, isNull);
      expect(leaderboard[2].quizCount, 0);
    });

    test('creates a challenge and records ranked attempts', () async {
      await GroupExtrasService.clearAll('group_test');

      final challenge = await GroupExtrasService.createChallenge(
        groupId: 'group_test',
        subject: 'Calculus',
        questionCount: 5,
        creatorId: 'user_maya',
        creatorName: 'Maya Santos',
      );

      expect(challenge.id, startsWith('challenge_group_test'));
      expect(challenge.subject, 'Calculus');
      expect(challenge.questionCount, 5);

      // Maya attempts: 4/5 (80%)
      await GroupExtrasService.recordChallengeAttempt(
        groupId: 'group_test',
        challengeId: challenge.id,
        score: 4,
        total: 5,
        userId: 'user_maya',
        userName: 'Maya Santos',
      );

      // Jonas attempts: 5/5 (100%)
      await GroupExtrasService.recordChallengeAttempt(
        groupId: 'group_test',
        challengeId: challenge.id,
        score: 5,
        total: 5,
        userId: 'user_jonas',
        userName: 'Jonas Reyes',
      );

      final challenges = await GroupExtrasService.getChallenges('group_test');
      expect(challenges.length, 1);
      final loaded = challenges.first;
      expect(loaded.attempts.length, 2);

      // Ranked board: Jonas (100%) #1, Maya (80%) #2
      expect(loaded.attempts[0].userName, 'Jonas Reyes');
      expect(loaded.attempts[0].percentage, 100);
      expect(loaded.attempts[1].userName, 'Maya Santos');
      expect(loaded.attempts[1].percentage, 80);
    });
  });

  group('GroupDetailScreen UI - Leaderboard and Challenges', () {
    testWidgets('renders Leaderboard with real scores and No quizzes yet for unranked members', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Record a real score for Maya
      await GroupExtrasService.recordMemberScore(userId: 'u1', subject: 'Calculus', score: 90);

      const group = StudyGroup(
        id: 'group_calc_crew',
        name: 'Calculus Crew',
        subject: 'Calculus',
        description: 'Test group',
        memberCount: 3,
        onlineCount: 2,
        isPublic: true,
        isJoined: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: GroupDetailScreen(group: group),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Leaderboard section exists
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.byKey(const Key('group_leaderboard_container')), findsOneWidget);

      // Maya Santos has 90% avg (1 quiz)
      expect(find.text('90% avg (1 quiz)'), findsOneWidget);

      // Jonas Reyes and Sofia Cruz have no quizzes yet
      expect(find.text('No quizzes yet'), findsWidgets);

      // Verify Quiz Challenges section and + Challenge button
      expect(find.text('Quiz Challenges'), findsOneWidget);
      expect(find.byKey(const Key('create_challenge_button')), findsOneWidget);
    });

    testWidgets('creates challenge via dialog and displays challenge card with Take Challenge', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await GroupExtrasService.clearAll('group_calc_crew');

      const group = StudyGroup(
        id: 'group_calc_crew',
        name: 'Calculus Crew',
        subject: 'Calculus',
        description: 'Test group',
        memberCount: 3,
        onlineCount: 2,
        isPublic: true,
        isJoined: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: GroupDetailScreen(group: group),
        ),
      );
      await tester.pumpAndSettle();

      // Tap + Challenge button
      await tester.tap(find.byKey(const Key('create_challenge_button')));
      await tester.pumpAndSettle();

      expect(find.text('Start a Quiz Challenge'), findsOneWidget);
      expect(find.byKey(const Key('confirm_create_challenge_button')), findsOneWidget);

      // Tap Confirm Create Challenge
      await tester.tap(find.byKey(const Key('confirm_create_challenge_button')));
      await tester.pumpAndSettle();

      // Verify Challenge card appeared
      expect(find.text('Take Challenge'), findsOneWidget);
      expect(find.text('Calculus • 5 Questions'), findsOneWidget);
      expect(find.text('Ranked Board'), findsOneWidget);
      expect(find.text('No attempts yet. Be the first to complete this challenge!'), findsOneWidget);
    });
  });
}
