import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'login_screen.dart';
import '../dashboard/main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Alvin Legarbes');
  final _emailController = TextEditingController(text: 'you@example.com');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleRegister() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              children: const [
                Icon(Icons.arrow_back, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join StudyNest and start learning smarter.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Full Name
              const Text(
                'Full name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Alvin Legarbes',
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Email
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.textSecondary),
                ),
              ),

              const SizedBox(height: 20),

              // Password
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Choose a password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // Create Account Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _handleRegister,
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
