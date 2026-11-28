import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';

void main() {
  group('HomeScreen layout overflow and constraints tests', () {
    testWidgets('HomeScreen renders without overflow at narrow viewport (254x800)', (tester) async {
      tester.view.physicalSize = const Size(254, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      // Quick action titles should be rendered
      expect(find.text('Take Assessment'), findsAtLeastNWidgets(1));
      expect(find.text('My Study Groups'), findsOneWidget);
      expect(find.text('Study Schedule'), findsOneWidget);
      expect(find.text('Browse Materials'), findsOneWidget);
    });

    testWidgets('HomeScreen renders without overflow at desktop viewport (800x600)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Take Assessment'), findsAtLeastNWidgets(1));
    });

    testWidgets('HomeScreen renders without overflow at mobile viewport (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Quick actions'), findsOneWidget);
    });
  });
}
