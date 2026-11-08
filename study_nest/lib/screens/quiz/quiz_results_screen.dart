import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../services/recommendation_engine.dart';
import '../materials/materials_screen.dart';
import '../recommendations/recommendations_hub_screen.dart';
import 'quiz_screen.dart';

class QuizResultsScreen extends StatefulWidget {
  final String subject;
  final int score;
  final String grade;
  final List<String> strongTopics;
  final List<String> focusTopics;

  const QuizResultsScreen({
    super.key,
    required this.subject,
    required this.score,
    required this.grade,
    this.strongTopics = const ['Algebra', 'Functions'],
    this.focusTopics = const ['Derivatives', 'Limits'],
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  List<RecommendationItem> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final list = await RecommendationEngine.getRankedRecommendations();
    if (mounted) {
      setState(() {
        _recommendations = list;
      });
    }
  }

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
                        color: AppColors.accent,
                        width: 8,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.score}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        widget.grade,
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

              // Strengths & Focus (Ranked dynamically)
              Text(
                'Strengths • ${widget.strongTopics.isNotEmpty ? widget.strongTopics.join(', ') : widget.subject}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Focus • ${widget.focusTopics.isNotEmpty ? widget.focusTopics.join(', ') : "General Review"}',
                style: const TextStyle(
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
                        // Actually start the plan (navigates to Materials per Figma)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaterialsScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Start plan →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ML Recommendations Hub Header (clickable)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsHubScreen(),
                    ),
                  ).then((_) => _loadRecommendations());
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'ML Recommendations Hub',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_recommendations.isNotEmpty)
                ..._recommendations.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildRecommendationItem(
                      context,
                      title: '${item.subject} — ${item.topic}',
                      subtitle: '${item.priority} • ${item.timeEstimate}',
                      actionLabel: 'Retake',
                      actionColor: item.priority == 'High priority'
                          ? AppColors.error
                          : AppColors.success,
                      subject: item.subject,
                    ),
                  );
                })
              else ...[
                _buildRecommendationItem(
                  context,
                  title: 'Calculus — Derivatives',
                  subtitle: 'High priority • 8 min',
                  actionLabel: 'Retake',
                  actionColor: AppColors.success,
                  subject: 'Calculus',
                ),
                const SizedBox(height: 10),
                _buildRecommendationItem(
                  context,
                  title: 'Physics — Forces',
                  subtitle: 'Medium • 6 min',
                  actionLabel: 'Retake',
                  actionColor: AppColors.warning,
                  subject: 'Physics',
                ),
              ],

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
    required String subject,
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
          Expanded(
            child: Column(
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
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: subject),
                ),
              ).then((_) => _loadRecommendations());
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
