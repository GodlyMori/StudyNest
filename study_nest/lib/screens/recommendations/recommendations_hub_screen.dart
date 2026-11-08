import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/recommendation_engine.dart';
import '../quiz/quiz_screen.dart';
import '../materials/materials_screen.dart';

class RecommendationsHubScreen extends StatefulWidget {
  const RecommendationsHubScreen({super.key});

  @override
  State<RecommendationsHubScreen> createState() => _RecommendationsHubScreenState();
}

class _RecommendationsHubScreenState extends State<RecommendationsHubScreen> {
  List<RecommendationItem> _recommendations = [];
  bool _isLoading = true;

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
        _isLoading = false;
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
        title: const Text(
          'ML Recommendations Hub',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommended Review Plan Dark Card (Figma frame 19)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome, color: AppColors.accent, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Recommended Review Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ranked by your weakest topics & spaced repetition schedule. Focus where you need it most.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textLightMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
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
                                    builder: (context) => const MaterialsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Start Recommended Plan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Topic Recommendations Section
                    const Text(
                      'Targeted Focus Topics',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Weakest performance and oldest revision intervals appear first.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    ..._recommendations.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildRecommendationCard(context, item),
                      );
                    }),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, RecommendationItem item) {
    Color badgeColor;
    if (item.priority == 'High priority') {
      badgeColor = AppColors.error;
    } else if (item.priority == 'Medium') {
      badgeColor = AppColors.warning;
    } else {
      badgeColor = AppColors.textSecondary;
    }

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
                  '${item.subject} — ${item.topic}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.priority} • ${item.timeEstimate}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: badgeColor,
                      ),
                    ),
                    if (item.wrongCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${item.wrongCount} missed)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceMuted,
              foregroundColor: AppColors.textDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: item.subject),
                ),
              ).then((_) => _loadRecommendations());
            },
            child: const Text(
              'Retake',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
