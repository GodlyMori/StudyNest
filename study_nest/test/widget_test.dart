import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/data/quiz_questions.dart';
import 'package:study_nest/data/study_materials.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/models/study_session.dart';
import 'package:study_nest/screens/auth/login_screen.dart';
import 'package:study_nest/screens/materials/material_detail_screen.dart';
import 'package:study_nest/screens/materials/materials_screen.dart';
import 'package:study_nest/screens/planner/add_study_session_screen.dart';
import 'package:study_nest/screens/planner/notifications_list_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/screens/recommendations/recommendations_hub_screen.dart';
import 'package:study_nest/services/guest_score_service.dart';
import 'package:study_nest/services/material_download_service.dart';
import 'package:study_nest/services/network_service.dart';
import 'package:study_nest/services/notification_service.dart';
import 'package:study_nest/services/planner_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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

  // --- Phase 3 New Tests ---

  testWidgets('Search filters the list by title and by content; clearing search shows all 4 materials', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 4 materials are initially visible
    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Cell Structure Notes'), findsOneWidget);
    expect(find.text('WW2 Timeline'), findsOneWidget);
    expect(find.text('Calculus Integral Tables'), findsOneWidget);

    // 1. Filter by Title: typing "derivative"
    await tester.enterText(find.byType(TextField), 'derivative');
    await tester.pumpAndSettle();

    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Cell Structure Notes'), findsNothing);
    expect(find.text('WW2 Timeline'), findsNothing);
    expect(find.text('Calculus Integral Tables'), findsNothing);

    // 2. Clear search: shows all 4 materials again
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Cell Structure Notes'), findsOneWidget);
    expect(find.text('WW2 Timeline'), findsOneWidget);
    expect(find.text('Calculus Integral Tables'), findsOneWidget);

    // 3. Filter by Content: typing "organelles" (from Cell Structure content)
    await tester.enterText(find.byType(TextField), 'organelles');
    await tester.pumpAndSettle();

    expect(find.text('Cell Structure Notes'), findsOneWidget);
    expect(find.text('Derivatives Cheat Sheet'), findsNothing);
    expect(find.text('WW2 Timeline'), findsNothing);
    expect(find.text('Calculus Integral Tables'), findsNothing);
  });

  testWidgets('Search with no matches shows the no-results state with clear search button', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'termthatmatchesnothing123');
    await tester.pumpAndSettle();

    expect(find.text('No materials match your search'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Clear search'), findsOneWidget);

    // Tap Clear search button recovers the list
    await tester.tap(find.widgetWithText(ElevatedButton, 'Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Cell Structure Notes'), findsOneWidget);
    expect(find.text('WW2 Timeline'), findsOneWidget);
    expect(find.text('Calculus Integral Tables'), findsOneWidget);
  });

  testWidgets('Searching while Maths chip is selected only shows Maths materials', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Maths' chip
    await tester.tap(find.text('Maths'));
    await tester.pumpAndSettle();

    // Only Maths items should be visible
    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Calculus Integral Tables'), findsOneWidget);
    expect(find.text('Cell Structure Notes'), findsNothing);
    expect(find.text('WW2 Timeline'), findsNothing);

    // Search for "integral" within Maths
    await tester.enterText(find.byType(TextField), 'integral');
    await tester.pumpAndSettle();

    expect(find.text('Calculus Integral Tables'), findsOneWidget);
    expect(find.text('Derivatives Cheat Sheet'), findsNothing);
  });

  testWidgets('Tapping a material opens the Material Detail screen (not bottom sheet) with full content', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Derivatives Cheat Sheet
    await tester.tap(find.text('Derivatives Cheat Sheet'));
    await tester.pumpAndSettle();

    // Verify it opened MaterialDetailScreen as a full screen
    expect(find.byType(MaterialDetailScreen), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    // Verify Title, Meta, and Full content are displayed
    expect(find.text('Material Details'), findsOneWidget);
    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Maths • 8 min • Easy'), findsOneWidget);
    expect(find.textContaining('Product rule: (uv)\' = u\'v + uv\''), findsOneWidget);
  });

  testWidgets('Downloading Derivatives Cheat Sheet persists it, changes status to Downloaded, and leaves other 3 with Needs Internet (no hardcoded Offline)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await MaterialDownloadService.clearAll();

    await tester.pumpWidget(
      const MaterialApp(
        home: MaterialsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Initially, no material has an "Offline" badge; all 4 show "Needs Internet"
    expect(find.text('Offline'), findsNothing);
    expect(find.text('Needs Internet'), findsNWidgets(4));
    expect(find.text('Downloaded'), findsNothing);

    // Download Derivatives Cheat Sheet directly from its list item action
    final downloadButtons = find.byTooltip('Download offline');
    expect(downloadButtons, findsNWidgets(4));
    await tester.tap(downloadButtons.first);
    await tester.pumpAndSettle();

    // Check SharedPreferences persistence via service
    final isDownloaded = await MaterialDownloadService.isDownloaded('mat_derivatives');
    expect(isDownloaded, true);

    // Check UI: Derivatives Cheat Sheet now has "Downloaded" badge, the others still show "Needs Internet"
    expect(find.text('Downloaded'), findsOneWidget);
    expect(find.text('Needs Internet'), findsNWidgets(3));
    expect(find.text('Offline'), findsNothing);
  });

  testWidgets('A downloaded cheat sheet opens from local copy with network/wifi off', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await MaterialDownloadService.clearAll();

    // 1. Download Derivatives Cheat Sheet
    final derivativesMat = StudyMaterialBank.getById('mat_derivatives')!;
    await MaterialDownloadService.downloadMaterial(derivativesMat);

    // 2. Simulate offline / wifi off
    NetworkService.mockIsOnline = false;

    // 3. Open downloaded material in MaterialDetailScreen
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialDetailScreen(material: derivativesMat),
      ),
    );
    await tester.pumpAndSettle();

    // Content is successfully read from local offline storage
    expect(find.text('Derivatives Cheat Sheet'), findsOneWidget);
    expect(find.text('Loaded from local copy. Available without wifi.'), findsOneWidget);
    expect(find.textContaining('Product rule: (uv)\' = u\'v + uv\''), findsOneWidget);

    // 4. In contrast, opening an un-downloaded material with wifi off displays internet required notice
    final cellMat = StudyMaterialBank.getById('mat_cell_structure')!;
    await tester.pumpWidget(
      MaterialApp(
        home: MaterialDetailScreen(material: cellMat),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Internet Connection Required'), findsOneWidget);
    expect(find.textContaining('This material has not been downloaded for offline reading'), findsOneWidget);

    // Reset mock
    NetworkService.mockIsOnline = null;
  });

  // --- Phase 4 New Tests ---

  testWidgets('Add Session opens as a full screen (not a dialog) with title, subject, date, time, and reminder toggle', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: PlannerScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap + Add Study Session
    final addButton = find.widgetWithText(ElevatedButton, '+ Add Study Session');
    expect(addButton, findsOneWidget);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Verify it opened as a full screen and NOT an AlertDialog dialog
    expect(find.byType(AddStudySessionScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    // Verify all 5 required fields exist on the screen
    expect(find.byType(TextField), findsOneWidget); // Title field
    expect(find.text('Subject'), findsOneWidget); // Subject field
    expect(find.text('Date'), findsOneWidget); // Date field
    expect(find.text('Time'), findsOneWidget); // Time field
    expect(find.byType(Switch), findsOneWidget); // Reminder toggle
  });

  testWidgets('The date picker (frame 43) and time picker (frame 44) set the date and time fields', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: AddStudySessionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Test Date Picker (frame 43)
    final dateFinder = find.textContaining('Nov 2026');
    expect(dateFinder, findsOneWidget);
    await tester.tap(dateFinder);
    await tester.pumpAndSettle();

    // Verify DatePickerDialog appears
    expect(find.byType(DatePickerDialog), findsOneWidget);
    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);

    // 2. Test Time Picker (frame 44)
    final timeFinder = find.textContaining('PM');
    expect(timeFinder, findsOneWidget);
    await tester.tap(timeFinder);
    await tester.pumpAndSettle();

    // Verify TimePicker appears
    expect(find.byType(TimePickerDialog), findsOneWidget);
    // Tap OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
  });

  testWidgets('Saving a session for Thursday makes it appear on Thursday and not on Wednesday', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await PlannerService.resetToDefaults();

    // Save a custom session for Thursday
    const thursdaySession = StudySession(
      id: 'session_thu_physics',
      title: 'Physics Mechanics Mastery',
      subject: 'Physics',
      date: 'Thu',
      time: '3:00 PM – 3:30 PM',
      type: 'Self Study',
      duration: '30 min',
      status: 'Scheduled',
    );
    await PlannerService.saveSession(thursdaySession);

    await tester.pumpWidget(
      const MaterialApp(
        home: PlannerScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // By default Wednesday is selected
    expect(find.text('Wed\'s Plan'), findsOneWidget);
    // Wednesday starting sessions must be present
    expect(find.text('Calculus — Derivatives Check-in'), findsOneWidget);
    expect(find.text('Biology — Cell Structure Flashcards'), findsOneWidget);
    expect(find.text('Calculus Crew — Group Study Session'), findsOneWidget);
    // Thursday session must NOT appear on Wednesday
    expect(find.text('Physics Mechanics Mastery'), findsNothing);

    // Switch to Thursday
    await tester.tap(find.text('Thu'));
    await tester.pumpAndSettle();

    expect(find.text('Thu\'s Plan'), findsOneWidget);
    // Thursday session MUST appear
    expect(find.text('Physics Mechanics Mastery'), findsOneWidget);
    // Wednesday sessions must NOT appear on Thursday
    expect(find.text('Calculus — Derivatives Check-in'), findsNothing);
    expect(find.text('Biology — Cell Structure Flashcards'), findsNothing);
    expect(find.text('Calculus Crew — Group Study Session'), findsNothing);
  });

  testWidgets('The permission dialog appears the first time a reminder is turned on, and declining leaves reminder off', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService.clearAll();

    await tester.pumpWidget(
      const MaterialApp(
        home: AddStudySessionScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Toggle reminder ON
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Verify permission dialog (frame 39) appears
    expect(find.text('Allow Notifications?'), findsOneWidget);
    expect(find.text('Don\'t Allow'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);

    // User taps "Don't Allow"
    await tester.tap(find.text('Don\'t Allow'));
    await tester.pumpAndSettle();

    // Reminder toggle must remain OFF
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, false);

    // Tap switch again to allow
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Dialog appears again
    expect(find.text('Allow Notifications?'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    // Reminder toggle is now ON
    final switchWidgetOn = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidgetOn.value, true);
  });

  testWidgets('Saving with reminder on schedules a notification, and notifications list shows scheduled reminder with cancel action', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService.clearAll();

    // 1. Schedule a session reminder
    await NotificationService.scheduleSessionReminder(
      id: 777,
      title: 'Calculus Final Review',
      body: 'Starts at 2:00 PM for Calculus',
      scheduledDateTime: DateTime(2026, 11, 7, 14, 0),
      dateStr: 'Thu, 7 Nov 2026',
      timeStr: '2:00 PM',
    );

    // Verify it is saved in service
    final reminders = await NotificationService.getScheduledReminders();
    expect(reminders.length, 1);
    expect(reminders.first['title'], 'Calculus Final Review');

    // 2. Open Notifications List Screen
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsListScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify screen displays the scheduled reminder
    expect(find.text('Scheduled Reminders'), findsOneWidget);
    expect(find.text('Calculus Final Review'), findsOneWidget);
    expect(find.text('Thu, 7 Nov 2026 • 2:00 PM'), findsOneWidget);

    // 3. Cancel the reminder
    final cancelBtn = find.byTooltip('Cancel reminder');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    // Verify it is removed and shows empty state
    expect(find.text('Calculus Final Review'), findsNothing);
    expect(find.text('No scheduled reminders'), findsOneWidget);

    final updatedReminders = await NotificationService.getScheduledReminders();
    expect(updatedReminders.isEmpty, true);
  });
}
