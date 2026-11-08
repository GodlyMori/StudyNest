import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/data/quiz_questions.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/screens/auth/login_screen.dart';
import 'package:study_nest/screens/materials/materials_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/screens/recommendations/recommendations_hub_screen.dart';
import 'package:study_nest/services/guest_score_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // --- Phase 1 Existing Tests ---
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

    expect(find.text('Incorrect email or password. Try again.'), findsOneWidget);
  });

  test('Guest score taken is stored locally and migrated on registration', () async {
    SharedPreferences.setMockInitialValues({});

    await GuestScoreService.saveGuestScore(
      subject: 'Calculus',
      score: 82,
      grade: 'Grade B',
    );

    final guestScores = await GuestScoreService.getGuestScores();
    expect(guestScores.length, 1);
    expect(guestScores.first['subject'], 'Calculus');
    expect(guestScores.first['score'], 82);

    const newUserId = 'supabase-user-12345';
    final migratedCount = await GuestScoreService.migrateGuestScoresToAccount(newUserId);
    expect(migratedCount, 1);

    final remainingGuestScores = await GuestScoreService.getGuestScores();
    expect(remainingGuestScores.isEmpty, true);

    final userScores = await GuestScoreService.getScoresForUser(userId: newUserId);
    expect(userScores.length, 1);
    expect(userScores.first['subject'], 'Calculus');
    expect(userScores.first['score'], 82);
  });

  // --- Phase 2 New Tests ---

  test('Question banks have 10 distinct questions per subject and keep Calculus question 1', () {
    for (final subject in ['Calculus', 'Biology', 'History', 'Physics']) {
      final questions = QuizQuestionBank.getQuestionsForSubject(subject);
      expect(questions.length, 10, reason: '$subject must have exactly 10 questions');

      final ids = questions.map((q) => q.id).toSet();
      expect(ids.length, 10, reason: '$subject must have unique IDs with no repeats');

      final texts = questions.map((q) => q.questionText).toSet();
      expect(texts.length, 10, reason: '$subject questions must not repeat text');

      for (final q in questions) {
        expect(q.options.length, 4);
        expect(q.correctOptionIndex >= 0 && q.correctOptionIndex < 4, true);
        expect(q.topic.isNotEmpty, true);
        expect(q.explanation.isNotEmpty, true);
      }
    }

    // Verify Calculus question 1 requirement
    final calc = QuizQuestionBank.calculusQuestions.first;
    expect(calc.questionText, 'What is the derivative of x²?');
    expect(calc.options[calc.correctOptionIndex], '2x');
  });

  test('Score computation and grade scale matches requirements', () {
    expect(QuizScreen.calculateGrade(100), 'Grade A');
    expect(QuizScreen.calculateGrade(90), 'Grade A');
    expect(QuizScreen.calculateGrade(89), 'Grade B');
    expect(QuizScreen.calculateGrade(80), 'Grade B');
    expect(QuizScreen.calculateGrade(79), 'Grade C');
    expect(QuizScreen.calculateGrade(70), 'Grade C');
    expect(QuizScreen.calculateGrade(69), 'Grade D');
    expect(QuizScreen.calculateGrade(60), 'Grade D');
    expect(QuizScreen.calculateGrade(59), 'Grade F');
    expect(QuizScreen.calculateGrade(0), 'Grade F');

    // 8 correct out of 10 gives 80% and Grade B
    final score = ((8 / 10) * 100).round();
    expect(score, 80);
    expect(QuizScreen.calculateGrade(score), 'Grade B');
  });

  test('Rules engine ranks weakest topic first (Derivatives wrong answer makes Calculus #1)', () async {
    SharedPreferences.setMockInitialValues({});
    await RecommendationEngine.clearStats();

    // Answer correctly on Genetics (Biology)
    await RecommendationEngine.recordAnswer(
      subject: 'Biology',
      topic: 'Genetics',
      isCorrect: true,
    );

    // Answer wrongly on Derivatives (Calculus)
    await RecommendationEngine.recordAnswer(
      subject: 'Calculus',
      topic: 'Derivatives',
      isCorrect: false,
    );

    final recommendations = await RecommendationEngine.getRankedRecommendations();
    expect(recommendations.isNotEmpty, true);

    // Calculus — Derivatives must be ranked #1
    expect(recommendations.first.subject, 'Calculus');
    expect(recommendations.first.topic, 'Derivatives');
    expect(recommendations.first.priority, 'High priority');
    expect(recommendations.first.wrongCount, 1);
  });

  testWidgets('Tapping wrong answer shows red state and explanation (Figma frame 33)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QuizScreen(subject: 'Calculus'),
      ),
    );
    await tester.pump();

    // Option 0 is '2x' (correct), Option 1 is 'x' (wrong)
    final wrongOptionFinder = find.text('x');
    expect(wrongOptionFinder, findsOneWidget);

    await tester.tap(wrongOptionFinder);
    await tester.pumpAndSettle();

    // Verification: "Incorrect" feedback banner and explanation appear
    expect(find.text('Incorrect'), findsOneWidget);
    expect(find.textContaining('Using the power rule'), findsOneWidget);

    // Next question button becomes active
    expect(find.text('Next question →'), findsOneWidget);
  });

  testWidgets('Recommendations Hub screen is reachable and Start Plan navigates to Materials', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RecommendationsHubScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ML Recommendations Hub'), findsOneWidget);
    expect(find.text('Recommended Review Plan'), findsOneWidget);

    final startPlanButton = find.widgetWithText(ElevatedButton, 'Start Recommended Plan');
    expect(startPlanButton, findsOneWidget);

    await tester.tap(startPlanButton);
    await tester.pumpAndSettle();

    // Verifies navigation reaches MaterialsScreen per Figma
    expect(find.byType(MaterialsScreen), findsOneWidget);
  });
}
