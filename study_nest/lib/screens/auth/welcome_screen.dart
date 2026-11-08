import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../dashboard/main_navigation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background decorative circle top-right
          Positioned(
            top: -70,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Background decorative circle bottom-left
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Background decorative ring
          Positioned(
            top: 310,
            left: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.03),
                  width: 14,
                ),
              ),
            ),
          ),

          // Peeking Owl Mascot from the left edge (hiding/peeking effect, clear of text)
          Positioned(
            top: -70,
            left: -190,
            child: Transform.rotate(
              angle: 30 * 3.1415926535 / 180,
              child: SizedBox(
                width: 440,
                height: 440,
                child: Image.asset(
                  AppAssets.owlHero,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

          // Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Space to reveal the peeking owl at top-left without any text overlap
                        const SizedBox(height: 270),

                        // Title & Subtitle
                        const Text(
                          'StudyNest',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'An intelligent, adaptive study companion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textLightMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'ML-driven recommendations, made for how you actually learn.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLightMuted,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Mascot dialogue card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Ready for your Calculus check-in?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '— Owl, your study buddy',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFD7D7D7),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Get Started Button
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Continue as Guest Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MainNavigationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Continue as Guest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Already have an account? Log in
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Already have an account? Log in',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLightMuted,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Login • Register • Forgot password?',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
