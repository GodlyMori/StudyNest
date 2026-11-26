import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/screens/auth/welcome_screen.dart';
import 'package:study_nest/screens/auth/login_screen.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/dashboard/main_navigation_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/screens/quiz/quiz_results_screen.dart';
import 'package:study_nest/screens/quiz/topics_quizzes_screen.dart';
import 'package:study_nest/screens/groups/study_groups_screen.dart';
import 'package:study_nest/screens/profile/profile_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/screens/planner/add_study_session_screen.dart';
import 'package:study_nest/services/planner_service.dart';
import 'package:study_nest/services/guest_score_service.dart';

/// End-to-end integration tests covering single-account app flows.
///
/// Acceptance:
/// - Flow A: launch → Welcome → login (or guest fallback if credentials not provided via --dart-define) → Home
/// - Flow B: full quiz flow: pick a subject → answer questions → finish → score screen shows computed score
/// - Flow C: bottom navigation across all four tabs (Home, Quizzes, Groups, Profile)
/// - Flow D: planner: add a study session → it appears on that date
/// - Clean up any data created during the test run
///
/// Running:
/// flutter test integration_test/app_test.dart
/// flutter test integration_test/app_test.dart --dart-define=TEST_USER_EMAIL=... --dart-define=TEST_USER_PASSWORD=...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const testEmail = String.fromEnvironment('TEST_USER_EMAIL', defaultValue: '');
  const testPassword = String.fromEnvironment('TEST_USER_PASSWORD', defaultValue: '');

  group('StudyNest Single-Account End-to-End Integration Tests', () {
    tearDown(() async {
      // Clean up test study sessions created in planner
      await PlannerService.resetToDefaults();
      await GuestScoreService.clearGuestScores();
    });

    testWidgets('Flow A: Launch app -> Welcome -> authenticate (login or guest fallback) -> Home', (tester) async {
      await tester.pumpWidget(const StudyNestApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);

      if (testEmail.isNotEmpty && testPassword.isNotEmpty) {
        // Authenticated live account flow via --dart-define credentials
        final logInLink = find.bySemanticsLabel(RegExp(r'Log in to existing account'));
        expect(logInLink, findsOneWidget);
        await tester.tap(logInLink);
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);

        // Enter email and password
        final emailField = find.widgetWithText(TextField, 'you@example.com');
        final passwordField = find.byType(TextField).last;

        await tester.enterText(emailField, testEmail);
        await tester.enterText(passwordField, testPassword);
        await tester.pumpAndSettle();

        final logInBtn = find.bySemanticsLabel(RegExp(r'^Log In'));
        await tester.tap(logInBtn);
        await tester.pumpAndSettle(const Duration(seconds: 4));
      } else {
        // Fallback: Test guest entry flow when credentials are not supplied via --dart-define.
        // This ensures the integration test suite passes gracefully in local and CI environments.
        final guestButton = find.widgetWithText(ElevatedButton, 'Continue as Guest');
        expect(guestButton, findsOneWidget);
        await tester.tap(guestButton);
        await tester.pumpAndSettle();

        // Save progress prompt appears: tap Continue as Guest dialog button
        final dialogGuestBtn = find.widgetWithText(OutlinedButton, 'Continue as Guest');
        expect(dialogGuestBtn, findsOneWidget);
        await tester.tap(dialogGuestBtn);
        await tester.pumpAndSettle();
      }

      // Verify Home Screen and Main Navigation are active
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('StudyNest'), findsOneWidget);
    });

    testWidgets('Flow B: Full quiz flow: pick subject -> answer questions -> finish -> score screen shows computed score', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(subject: 'Calculus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuizScreen), findsOneWidget);

      // Loop answering questions until quiz completion
      for (int i = 0; i < 20; i++) {
        if (find.byType(QuizResultsScreen).evaluate().isNotEmpty) {
          break;
        }

        // Tap the first available option for the current question
        final optionFinder = find.bySemanticsLabel(RegExp(r'^Option A:'));
        if (optionFinder.evaluate().isNotEmpty) {
          await tester.tap(optionFinder.first);
          await tester.pumpAndSettle();
        }

        // Tap Next question or Finish Quiz button
        final nextBtn = find.bySemanticsLabel(RegExp(r'(Next question|Finish Quiz)'));
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.tap(nextBtn.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify Quiz Results screen is reached with computed score display
      expect(find.byType(QuizResultsScreen), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets('Flow C: Bottom navigation across all four tabs (Home, Quizzes, Groups, Profile)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initial tab is Home
      expect(find.byType(HomeScreen), findsOneWidget);

      // 1. Switch to Quizzes tab
      final quizzesTab = find.bySemanticsLabel(RegExp(r'Quizzes tab'));
      expect(quizzesTab, findsOneWidget);
      await tester.tap(quizzesTab);
      await tester.pumpAndSettle();
      expect(find.byType(TopicsQuizzesScreen), findsOneWidget);

      // 2. Switch to Groups tab
      final groupsTab = find.bySemanticsLabel(RegExp(r'Groups tab'));
      expect(groupsTab, findsOneWidget);
      await tester.tap(groupsTab);
      await tester.pumpAndSettle();
      expect(find.byType(StudyGroupsScreen), findsOneWidget);

      // 3. Switch to Profile tab
      final profileTab = find.bySemanticsLabel(RegExp(r'Profile tab'));
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // 4. Return to Home tab
      final homeTab = find.bySemanticsLabel(RegExp(r'Home tab'));
      expect(homeTab, findsOneWidget);
      await tester.tap(homeTab);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Flow D: Planner: add a study session -> session appears on date', (tester) async {
      await PlannerService.resetToDefaults();

      await tester.pumpWidget(
        const MaterialApp(
          home: PlannerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlannerScreen), findsOneWidget);

      // Tap + Add study session button
      final addBtn = find.widgetWithText(ElevatedButton, '+ Add Study Session');
      expect(addBtn, findsOneWidget);
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddStudySessionScreen), findsOneWidget);

      // Enter session title
      const customTitle = 'E2E Final Review Session';
      final titleField = find.widgetWithText(TextField, 'e.g. Calculus Practice');
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, customTitle);
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Session');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Return to PlannerScreen and verify newly created session appears
      expect(find.byType(PlannerScreen), findsOneWidget);
      expect(find.text(customTitle), findsOneWidget);
    });
  });
}
