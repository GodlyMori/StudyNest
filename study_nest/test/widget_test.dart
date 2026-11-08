import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/screens/auth/login_screen.dart';
import 'package:study_nest/services/guest_score_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StudyNest welcome screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyNestApp());
    expect(find.text('StudyNest'), findsOneWidget);
  });

  testWidgets('Continue as Guest shows Save your progress prompt (Figma Frame 35)', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyNestApp());
    await tester.pumpAndSettle();

    final guestButton = find.widgetWithText(ElevatedButton, 'Continue as Guest');
    expect(guestButton, findsOneWidget);

    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    // Verify Figma frame 35 "Save your progress?" dialog is displayed
    expect(find.text('Save your progress?'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('Logging in with empty password shows Figma frame 36 error state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify Frame 36 error message appears
    expect(find.text('Incorrect email or password. Try again.'), findsOneWidget);
  });

  test('Guest score taken is stored locally and migrated on registration', () async {
    SharedPreferences.setMockInitialValues({});

    // 1. Guest takes quiz and saves score
    await GuestScoreService.saveGuestScore(
      subject: 'Calculus',
      score: 82,
      grade: 'Grade B',
    );

    final guestScores = await GuestScoreService.getGuestScores();
    expect(guestScores.length, 1);
    expect(guestScores.first['subject'], 'Calculus');
    expect(guestScores.first['score'], 82);

    // 2. Guest registers -> migrate scores to new Supabase user ID
    const newUserId = 'supabase-user-12345';
    final migratedCount = await GuestScoreService.migrateGuestScoresToAccount(newUserId);
    expect(migratedCount, 1);

    // 3. Guest store is cleared
    final remainingGuestScores = await GuestScoreService.getGuestScores();
    expect(remainingGuestScores.isEmpty, true);

    // 4. Scores are now permanently attached to the user account
    final userScores = await GuestScoreService.getScoresForUser(userId: newUserId);
    expect(userScores.length, 1);
    expect(userScores.first['subject'], 'Calculus');
    expect(userScores.first['score'], 82);
  });
}
