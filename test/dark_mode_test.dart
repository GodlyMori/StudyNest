import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_nest/main.dart';
import 'package:study_nest/screens/dashboard/home_screen.dart';
import 'package:study_nest/screens/profile/settings_screen.dart';
import 'package:study_nest/screens/quiz/quiz_screen.dart';
import 'package:study_nest/theme/app_theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StudyNestApp.themeModeNotifier.value = ThemeMode.light;
  });

  group('Dark Mode tests', () {
    testWidgets('Toggling Settings switch flips app ThemeMode and persists preference', (tester) async {
      SharedPreferences.setMockInitialValues({});
      StudyNestApp.themeModeNotifier.value = ThemeMode.light;

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: StudyNestApp.themeModeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: const SettingsScreen(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(StudyNestApp.themeModeNotifier.value, ThemeMode.light);

      final darkSwitch = find.byKey(const Key('dark_mode_switch'));
      expect(darkSwitch, findsOneWidget);

      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();

      expect(StudyNestApp.themeModeNotifier.value, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_dark_mode'), isTrue);

      // Toggle back to light
      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();

      expect(StudyNestApp.themeModeNotifier.value, ThemeMode.light);
      expect(prefs.getBool('settings_dark_mode'), isFalse);
    });

    testWidgets('Relaunching app with persisted dark preference loads dark mode', (tester) async {
      SharedPreferences.setMockInitialValues({'settings_dark_mode': true});
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('settings_dark_mode') ?? false;
      StudyNestApp.themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

      await tester.pumpWidget(const StudyNestApp());
      await tester.pumpAndSettle();

      expect(StudyNestApp.themeModeNotifier.value, ThemeMode.dark);
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);
    });

    testWidgets('HomeScreen renders in dark mode without overflow or unhandled exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('QuizScreen renders in dark mode without overflow or unhandled exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const QuizScreen(subject: 'Calculus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuizScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen renders in dark mode without overflow or unhandled exceptions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });
  });
}
