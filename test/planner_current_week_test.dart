import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/screens/planner/add_study_session_screen.dart';
import 'package:study_nest/screens/planner/planner_screen.dart';

void main() {
  group('Planner Current Week Dynamic Dates', () {
    testWidgets('PlannerScreen displays the real current week dates and labels', (tester) async {
      final handle = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({});

      final monday = PlannerScreen.getMondayOfCurrentWeek();
      final expectedDates = List.generate(7, (i) => monday.add(Duration(days: i)));
      final expectedDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      await tester.pumpWidget(
        const MaterialApp(home: PlannerScreen()),
      );
      await tester.pumpAndSettle();

      // Check all 7 weekday abbreviations are displayed
      for (final day in expectedDayLabels) {
        expect(find.text(day), findsWidgets);
      }

      // Check each day date number and semantic label with real month name
      for (var i = 0; i < 7; i++) {
        final date = expectedDates[i];
        final dayNum = date.day.toString();
        final dayAbbr = expectedDayLabels[i];
        final monthName = PlannerScreen.monthNames[date.month - 1];

        expect(find.text(dayNum), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp('Select $dayAbbr, $dayNum $monthName')),
          findsOneWidget,
        );
      }
      handle.dispose();
    });

    testWidgets('AddStudySessionScreen initial date maps to real current week date', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final monday = PlannerScreen.getMondayOfCurrentWeek();
      final wednesday = monday.add(const Duration(days: 2));

      await tester.pumpWidget(
        const MaterialApp(
          home: AddStudySessionScreen(initialDay: 'Wed'),
        ),
      );
      await tester.pumpAndSettle();

      final expectedDisplay = AddStudySessionScreen.formatDisplayDate(wednesday);
      expect(find.text(expectedDisplay), findsOneWidget);
    });
  });
}
