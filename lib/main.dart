import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/attempt_sync_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from --dart-define environment variables:
  // e.g. flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await SupabaseService.initialize();

  // Flush any queued offline question attempts if signed in and online
  AttemptSyncService.logger.syncOutbox();

  // Initialize Local Notifications and Timezone for study session reminders
  await NotificationService.initialize();

  runApp(const StudyNestApp());
}

class StudyNestApp extends StatelessWidget {
  const StudyNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyNest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}
