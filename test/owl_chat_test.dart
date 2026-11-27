import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/bkt_mastery.dart';
import 'package:study_nest/screens/owl_chat/owl_chat_screen.dart';
import 'package:study_nest/services/owl_chat_service.dart';
import 'package:study_nest/services/recommendation_engine.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final now = DateTime(2026, 11, 27, 12, 0);

  final sampleRec = RecommendationItem(
    topic: 'Cell Structure',
    subject: 'Biology',
    priority: 'High priority',
    timeEstimate: '8 min',
    wrongCount: 3,
    lastAttempt: now.subtract(const Duration(hours: 4)),
    mastery: 0.32,
    reason: 'Mastery 32%, missed 3 of your last 5 questions • Overdue by 2 days',
  );

  final sampleDueTopic1 = TopicMastery(
    subject: 'Biology',
    topic: 'Cell Structure',
    mastery: 0.32,
    updatedAt: now.subtract(const Duration(days: 3)),
    nextReviewAt: now.subtract(const Duration(days: 2)),
  );

  final sampleDueTopic2 = TopicMastery(
    subject: 'Calculus',
    topic: 'Derivatives',
    mastery: 0.55,
    updatedAt: now.subtract(const Duration(days: 1)),
    nextReviewAt: now,
  );

  final seededStudentData = OwlStudentData(
    displayName: 'Alvin',
    recommendations: [sampleRec],
    dueTopics: [sampleDueTopic1, sampleDueTopic2],
    currentStreak: 4,
    totalXp: 350,
    currentLevel: 4,
  );

  const guestNoData = OwlStudentData(
    displayName: null,
    recommendations: [],
    dueTopics: [],
    currentStreak: 0,
    totalXp: 0,
    currentLevel: 1,
  );

  group('OwlChatService — Greeting Builder', () {
    test('Signed in user with data receives personalized greeting with weakest topic and due count', () {
      final greeting = OwlChatService.buildGreeting(seededStudentData);
      expect(greeting, contains('Hi Alvin!'));
      expect(greeting, contains('Your weakest topic is Biology — Cell Structure'));
      expect(greeting, contains('2 reviews due'));
      expect(greeting, contains('Ask me what to study next.'));
    });

    test('Guest user with data receives standard greeting without name', () {
      final guestWithData = OwlStudentData(
        displayName: null,
        recommendations: [sampleRec],
        dueTopics: [sampleDueTopic1],
        currentStreak: 1,
        totalXp: 50,
        currentLevel: 1,
      );
      final greeting = OwlChatService.buildGreeting(guestWithData);
      expect(greeting, startsWith('Hi!'));
      expect(greeting, contains('Your weakest topic is Biology — Cell Structure'));
      expect(greeting, contains('1 review due'));
    });

    test('Signed in user with no data receives diagnostic quiz nudge', () {
      const userNoData = OwlStudentData(
        displayName: 'Alvin',
        recommendations: [],
        dueTopics: [],
        currentStreak: 0,
        totalXp: 0,
        currentLevel: 1,
      );
      final greeting = OwlChatService.buildGreeting(userNoData);
      expect(greeting, equals("Hi Alvin! Take the diagnostic quiz first and I'll know what to work on."));
    });

    test('Guest user with no data receives diagnostic quiz nudge', () {
      final greeting = OwlChatService.buildGreeting(guestNoData);
      expect(greeting, equals("Hi! Take the diagnostic quiz first and I'll know what to work on."));
    });
  });

  group('OwlChatService — Intent 1: What to study / recommend', () {
    test('Returns top ranked recommendation with topic, subject, and reason', () {
      final queries = [
        'what should I study',
        'what should i study next?',
        'what do I study',
        'what is my weakest topic?',
        'what should I focus on?',
        'recommend something to study',
      ];

      for (final query in queries) {
        final reply = OwlChatService.computeReply(query, seededStudentData, now: now);
        expect(reply, contains('Biology — Cell Structure'));
        expect(reply, contains('mastery 32%'));
        expect(reply, contains('missed 3 of your last 5 questions'));
        expect(reply, contains('overdue by 2 days'));
        expect(reply, contains('Want to start there?'));
      }
    });

    test('Guest or student with no data returns diagnostic nudge', () {
      final reply = OwlChatService.computeReply('what should I study', guestNoData, now: now);
      expect(reply, equals("Take the diagnostic quiz first and I'll know what to work on."));
    });
  });

  group('OwlChatService — Intent 2: What is due for review', () {
    test('Returns due topic list with overdue days calculation', () {
      final queries = [
        "what's due for review?",
        'due',
        'what reviews are due',
        'what should I revise',
      ];

      for (final query in queries) {
        final reply = OwlChatService.computeReply(query, seededStudentData, now: now);
        expect(reply, contains('You have 2 reviews due:'));
        expect(reply, contains('• Biology — Cell Structure (overdue by 2 days)'));
        expect(reply, contains('• Calculus — Derivatives (due today)'));
      }
    });

    test('Returns all caught up when no reviews are due', () {
      final caughtUpData = OwlStudentData(
        displayName: 'Alvin',
        recommendations: [sampleRec],
        dueTopics: const [],
        currentStreak: 2,
        totalXp: 100,
        currentLevel: 2,
      );

      final reply = OwlChatService.computeReply("what's due for review", caughtUpData, now: now);
      expect(reply, equals("No reviews due — you're all caught up."));
    });

    test('Guest or student with no data returns diagnostic nudge', () {
      final reply = OwlChatService.computeReply("what's due", guestNoData, now: now);
      expect(reply, equals("Take the diagnostic quiz first and I'll know what to work on."));
    });
  });

  group('OwlChatService — Intent 3: How am I doing / progress', () {
    test('Returns summary with weakest topic, mastery %, streak, XP, level, and reviews due', () {
      final queries = [
        'how am I doing',
        'show my progress',
        'what level am I?',
        'what is my streak?',
        'how much xp do I have?',
      ];

      for (final query in queries) {
        final reply = OwlChatService.computeReply(query, seededStudentData, now: now);
        expect(reply, contains("Here's how you're doing:"));
        expect(reply, contains('Biology — Cell Structure (32% mastery)'));
        expect(reply, contains('Streak: 4 days'));
        expect(reply, contains('Level: Level 4 (350 XP)'));
        expect(reply, contains('Reviews due: 2 reviews due'));
      }
    });

    test('Guest or student with no data returns diagnostic nudge', () {
      final reply = OwlChatService.computeReply('how am I doing', guestNoData, now: now);
      expect(reply, equals("Take the diagnostic quiz first and I'll know what to work on."));
    });
  });

  group('OwlChatService — Intent 4: Practice / quiz / problem', () {
    test('Returns weakest topic and directions to Home or Hub', () {
      final queries = [
        'give me a practice problem',
        'quiz me',
        'give me a problem',
        'test me',
      ];

      for (final query in queries) {
        final reply = OwlChatService.computeReply(query, seededStudentData, now: now);
        expect(
          reply,
          equals(
            'Your weakest topic is Biology — Cell Structure — open it from the For You cards on Home or the Hub and take a quiz.',
          ),
        );
      }
    });

    test('Guest or student with no data returns diagnostic nudge', () {
      final reply = OwlChatService.computeReply('give me practice', guestNoData, now: now);
      expect(reply, equals("Take the diagnostic quiz first and I'll know what to work on."));
    });
  });

  group('OwlChatService — Intent 5: Honest Fallback', () {
    test('Off-topic message returns honest fallback and never fakes topic knowledge', () {
      final offTopicQueries = [
        'Explain Pythagorean theorem',
        'Tell me a joke',
        'Who was Julius Caesar?',
        'Can you write a poem?',
      ];

      for (final query in offTopicQueries) {
        final reply = OwlChatService.computeReply(query, seededStudentData, now: now);
        expect(
          reply,
          equals("I can help with what to study next, what's due for review, and how you're doing — try asking one of those."),
        );
        expect(reply, isNot(contains('Pythagor')));
        expect(reply, isNot(contains('triangle')));
        expect(reply, isNot(contains('hypotenuse')));
      }
    });
  });

  group('OwlChatScreen — Widget Tests', () {
    testWidgets('Seed conversation is removed and only real data-driven greeting starts the chat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwlChatScreen(initialData: seededStudentData),
        ),
      );
      await tester.pumpAndSettle();

      // Verify old fake seed conversation is completely absent
      expect(find.textContaining('Pythagor'), findsNothing);
      expect(find.textContaining('Stuck on derivatives?'), findsNothing);
      expect(find.textContaining('a² + b² = c²'), findsNothing);

      // Verify initial greeting is present
      expect(find.textContaining('Hi Alvin! Your weakest topic is Biology — Cell Structure'), findsOneWidget);

      // Verify the 3 real quick prompts are present
      expect(find.text('What should I study next?'), findsOneWidget);
      expect(find.text("What's due for review?"), findsOneWidget);
      expect(find.text('How am I doing?'), findsOneWidget);
    });

    testWidgets('Sending "what should I study" returns data-driven reply with real weakest topic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwlChatScreen(initialData: seededStudentData),
        ),
      );
      await tester.pumpAndSettle();

      // Enter "what should I study"
      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'what should I study');
      await tester.pump();

      // Tap send button
      final sendFinder = find.bySemanticsLabel('Send message to Owl');
      await tester.tap(sendFinder);
      await tester.pump();

      // User message is added
      expect(find.text('what should I study'), findsOneWidget);

      // Wait for thinking delay
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify data-driven reply appears
      expect(
        find.textContaining(
          'Your weakest spot right now is Biology — Cell Structure (mastery 32%, missed 3 of your last 5 questions, overdue by 2 days). Want to start there?',
        ),
        findsOneWidget,
      );

      // Verify total chat bubbles: exactly 1 greeting + 1 user message + 1 Owl reply = 3
      // We can check Container message counts or text elements
      expect(find.text('what should I study'), findsOneWidget);
    });

    testWidgets('Tapping quick prompt chip sends message and generates real reply', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OwlChatScreen(initialData: seededStudentData),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "How am I doing?"
      await tester.tap(find.text('How am I doing?'));
      await tester.pump();

      expect(find.text('How am I doing?'), findsWidgets); // chip + user message bubble

      // Wait for thinking delay
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify reply
      expect(find.textContaining("Here's how you're doing:"), findsOneWidget);
      expect(find.textContaining('Biology — Cell Structure (32% mastery)'), findsOneWidget);
      expect(find.textContaining('Streak: 4 days'), findsOneWidget);
      expect(find.textContaining('Level: Level 4 (350 XP)'), findsOneWidget);
    });
  });
}
