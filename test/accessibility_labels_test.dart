import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/models/quiz_question.dart';
import 'package:study_nest/models/question_review_item.dart';
import 'package:study_nest/models/flashcard.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/screens/quiz/custom_quiz_screen.dart';
import 'package:study_nest/screens/quiz/quiz_review_screen.dart';
import 'package:study_nest/screens/materials/materials_screen.dart';
import 'package:study_nest/screens/materials/flashcard_study_screen.dart';
import 'package:study_nest/screens/groups/study_groups_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/screens/profile/profile_screen.dart';
import 'package:study_nest/screens/profile/settings_screen.dart';
import 'package:study_nest/screens/owl_chat/owl_chat_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Task 6.4: Accessibility Semantics Labels', () {
    testWidgets('Home screen contains key semantic action labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Open profile')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Take Assessment')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Open Study Groups')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Open Study Schedule')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Browse Materials')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'View all recommendations')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Take Calculus quiz')), findsOneWidget);
      expect(find.bySemanticsLabel('Open Owl Chat'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Quiz screen contains semantics for back, mascot AI, hints, options, and next', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(subject: 'Calculus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Leave quiz')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Chat with Owl AI')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Ask Owl for a Hint')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Next question')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Option A:')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Custom Quiz screen contains back, topic toggle, and start quiz labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomQuizScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Back')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Deselect all topics')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Start Custom Quiz')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Quiz Review screen contains back semantics', (tester) async {
      final handle = tester.ensureSemantics();
      const q = QuizQuestion(
        id: 'rev_1',
        subject: 'Calculus',
        topic: 'Derivatives',
        difficulty: 1,
        questionText: 'Derivative of x^2?',
        options: ['2x', 'x', '2', 'x^2'],
        correctOptionIndex: 0,
        explanation: 'Power rule: 2x.',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: QuizReviewScreen(
            subject: 'Calculus',
            reviewItems: [
              QuestionReviewItem(
                question: q,
                selectedOptionIndex: 0,
                isCorrect: true,
                hintUsed: false,
                timeTakenMs: 3000,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Back')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Materials screen contains search, Owl AI, and category labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: MaterialsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Search study materials')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Chat with Owl AI')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'All category')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Flashcard Study screen contains close, flip, and rating semantics', (tester) async {
      final handle = tester.ensureSemantics();
      final now = DateTime.now();
      final card = Flashcard(
        id: 'fc_test_1',
        materialId: 'mat_calc',
        front: 'What is a derivative?',
        back: 'The instantaneous rate of change.',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardStudyScreen(
            title: 'Calculus Essentials',
            cards: [card],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Close flashcards')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Flip flashcard')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Show Answer')), findsOneWidget);

      // Reveal answer to check SM-2 grade buttons
      await tester.tap(find.bySemanticsLabel(RegExp(r'Show Answer')));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Rate Again')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Rate Hard')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Rate Good')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Rate Easy')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Study Groups screen contains tabs, search/invite, and Owl AI labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: StudyGroupsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Chat with Owl AI')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'My Groups tab')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Discover tab')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Create Study Group')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Find Users to Invite')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'View Invites')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Planner screen contains notifications, Owl AI, and add session labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: PlannerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'View scheduled reminders')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Chat with Owl AI')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Add study session')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Profile screen contains settings label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Open settings')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Settings screen contains back, toggle, logout, and delete account labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Back')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Push Notifications toggle')), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Log Out')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Delete Account')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Owl Chat screen contains back, input, and send labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: OwlChatScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'Back')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Ask Owl a question')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'Send message to Owl')), findsOneWidget);
      handle.dispose();
    });
  });
}
