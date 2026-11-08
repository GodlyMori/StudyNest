import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import 'quiz_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final String subject;
  final int score;
  final String grade;

  const QuizResultsScreen({
    super.key,
    this.subject = 'Calculus',
    this.score = 82,
    this.grade = 'Grade B',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              AppAssets.owlCelebrating,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Your Results',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 24),

              // Circular score display
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 8,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        grade,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Strengths & Focus
              const Text(
                'Strengths • Algebra, Functions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Focus • Derivatives, Limits',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 24),

              // Recommended Review Plan (Dark card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Review Plan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '3 topics, 24 minutes total.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLightMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Starting adaptive ML review plan...')),
                        );
                      },
                      child: const Text(
                        'Start plan →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ML Recommendations Hub Header
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'ML Recommendations Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildRecommendationItem(
                context,
                title: 'Calculus — Derivatives',
                subtitle: 'High priority • 8 min',
                actionLabel: 'Retake',
                actionColor: AppColors.success,
              ),
              const SizedBox(height: 10),
              _buildRecommendationItem(
                context,
                title: 'Physics — Forces',
                subtitle: 'Medium • 6 min',
                actionLabel: 'Retake',
                actionColor: AppColors.warning,
              ),
              const SizedBox(height: 10),
              _buildRecommendationItem(
                context,
                title: 'History — WW2 Causes',
                subtitle: 'Low • 10 min',
                actionLabel: 'Retake',
                actionColor: AppColors.textSecondary,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String actionLabel,
    required Color actionColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: title),
                ),
              );
            },
            child: Text(
              actionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
