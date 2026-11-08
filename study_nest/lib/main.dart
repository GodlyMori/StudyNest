import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase from --dart-define environment variables:
  // e.g. flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  await SupabaseService.initialize();

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
