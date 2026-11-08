import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
