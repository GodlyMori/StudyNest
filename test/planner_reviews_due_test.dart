import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/ml/bkt_mastery.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';
import 'package:study_nest/services/mastery_service.dart';
import 'package:study_nest/services/planner_service.dart';

void main() {
  group('Planner SM-2 Reviews Due integration (V2 Stage 3.2)', () {
    testWidgets('due review produces a suggestion and tapping it creates the study session', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Seed a due review (reviewed 3 days ago, 1-day interval -> overdue by 2 days)
      await MasteryService.tracker.recordTopicReview(
        subject: 'Calculus',
        topic: 'Derivatives',
        correctCount: 7,
        totalCount: 10,
        reviewedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        const MaterialApp(home: PlannerScreen()),
      );
      await tester.pumpAndSettle();

      // "Reviews due" section lists the due topic
      expect(find.text('Reviews due'), findsOneWidget);
      expect(find.text('Calculus — Derivatives'), findsOneWidget);

      // One tap on the suggestion adds it to the Planner
      await tester.tap(find.text('Calculus — Derivatives'));
      await tester.pumpAndSettle();

      // Session is created for the selected day (Wed, 6) and shown in the plan
      expect(find.text('Review: Derivatives'), findsOneWidget);

      final wedSessions = await PlannerService.getSessionsForDay('Wed', '6');
      expect(
        wedSessions.any((s) => s.title == 'Review: Derivatives' && s.subject == 'Calculus'),
        isTrue,
      );

      // Also verify TopicMastery cache still holds SM-2 fields
      final masteries = await MasteryService.tracker.getMasteries();
      final m = masteries[TopicMastery.topicKey('Calculus', 'Derivatives')];
      expect(m, isNotNull);
      expect(m!.intervalDays, 1);
    });
  });
}
