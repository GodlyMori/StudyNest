import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/services/crash_reporting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CrashReportingService.closeForTesting();
  });

  tearDown(() async {
    await CrashReportingService.closeForTesting();
  });

  group('Task 6.2: Sentry Crash Reporting', () {
    test('CrashReportingService initializes gracefully without DSN and executes appRunner', () async {
      bool appStarted = false;

      await CrashReportingService.initialize(
        dsn: '',
        appRunner: () {
          appStarted = true;
        },
      );

      expect(appStarted, isTrue, reason: 'appRunner must be invoked so app startup is never blocked');
      expect(CrashReportingService.isEnabled, isFalse);
    });

    test('CrashReportingService captures exception in no-op mode without throwing', () async {
      await CrashReportingService.initialize(dsn: '');

      expect(
        () async => await CrashReportingService.captureException(
          Exception('Simulated non-production exception'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('CrashReportingService initializes with provided DSN without crashing app startup', () async {
      bool runnerExecuted = false;

      // Use standard Sentry test format DSN without sending real events
      await CrashReportingService.initialize(
        dsn: 'https://1234567890abcdef1234567890abcdef@o0.ingest.sentry.io/0',
        appRunner: () {
          runnerExecuted = true;
        },
      );

      expect(runnerExecuted, isTrue);
      expect(CrashReportingService.isEnabled, isTrue);
    });

    testWidgets('StudyNestApp root widget builds and renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const StudyNestApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(StudyNestApp), findsOneWidget);
    });
  });
}
