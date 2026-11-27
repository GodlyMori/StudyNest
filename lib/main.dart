import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/attempt_sync_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('settings_dark_mode') ?? false;
  StudyNestApp.themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  // Initialize Supabase from --dart-define environment variables:
  // e.g. flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await SupabaseService.initialize();

  // Flush any queued offline question attempts if signed in and online
  AttemptSyncService.logger.syncOutbox();

  // Initialize Local Notifications and Timezone for study session reminders
  await NotificationService.initialize();

  // Initialize Sentry crash reporting via --dart-define=SENTRY_DSN=...
  // Gracefully handles empty DSN so app startup is never blocked without configuration.
  await CrashReportingService.initialize(
    appRunner: () => runApp(const StudyNestApp()),
  );
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key});

  /// Global notifier allowing instant theme switching across the app
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'StudyNest',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
