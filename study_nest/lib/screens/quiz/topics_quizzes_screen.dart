import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import 'quiz_screen.dart';

class TopicsQuizzesScreen extends StatelessWidget {
  const TopicsQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Quizzes & Topics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pick a subject to start a quiz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    AppAssets.owlThinking,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Diagnostic Assessment Banner
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(subject: 'Diagnostic Quiz'),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology, color: AppColors.textDark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Diagnostic Quiz',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Evaluate all topics for personalized ML study plans',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textLightMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Subjects List
              _buildSubjectCategory(
                context,
                title: 'Mathematics',
                icon: Icons.calculate_outlined,
                color: const Color(0xFFF59E0B),
                quizzes: [
                  {'name': 'Calculus — Derivatives', 'questions': '10 Qs', 'difficulty': 'Medium', 'mastery': '82%'},
                  {'name': 'Calculus — Integrals', 'questions': '12 Qs', 'difficulty': 'Hard', 'mastery': '58%'},
                  {'name': 'Linear Algebra — Matrices', 'questions': '8 Qs', 'difficulty': 'Easy', 'mastery': '90%'},
                ],
              ),

              const SizedBox(height: 20),

              _buildSubjectCategory(
                context,
                title: 'Sciences',
                icon: Icons.science_outlined,
                color: const Color(0xFF10B981),
                quizzes: [
                  {'name': 'Biology — Cell Structure', 'questions': '10 Qs', 'difficulty': 'Easy', 'mastery': '64%'},
                  {'name': 'Chemistry — Periodic Table', 'questions': '15 Qs', 'difficulty': 'Medium', 'mastery': '72%'},
                  {'name': 'Physics — Newton’s Laws', 'questions': '8 Qs', 'difficulty': 'Hard', 'mastery': '45%'},
                ],
              ),

              const SizedBox(height: 20),

              _buildSubjectCategory(
                context,
                title: 'Humanities & History',
                icon: Icons.history_edu_outlined,
                color: const Color(0xFF6366F1),
                quizzes: [
                  {'name': 'World War II Timeline', 'questions': '10 Qs', 'difficulty': 'Easy', 'mastery': '85%'},
                  {'name': 'Ancient Civilizations', 'questions': '12 Qs', 'difficulty': 'Medium', 'mastery': '70%'},
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCategory(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, String>> quizzes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...quizzes.map((quiz) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(subject: quiz['name']!),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz['name']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${quiz['questions']} • ${quiz['difficulty']} • Mastery: ${quiz['mastery']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
