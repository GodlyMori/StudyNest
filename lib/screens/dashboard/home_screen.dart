import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../ml/bkt_mastery.dart';
import '../../services/mastery_service.dart';
import '../../services/recommendation_engine.dart';
import '../../services/streak_service.dart';
import '../../services/xp_service.dart';
import '../quiz/quiz_screen.dart';
import '../groups/study_groups_screen.dart';
import '../planner/planner_screen.dart';
import '../materials/materials_screen.dart';
import '../owl_chat/owl_chat_screen.dart';
import '../profile/profile_screen.dart';
import '../recommendations/recommendations_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _streak = 0;
  int _totalXp = 0;
  List<RecommendationItem> _recommendations = [];
  List<TopicMastery> _dueTopics = [];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final streakData = await StreakService.getCurrentStreakData();
    final totalXp = await XpService.getTotalXp();
    final recs = await RecommendationEngine.getRankedRecommendations();
    final due = await MasteryService.tracker.getDueTopics();
    if (mounted) {
      setState(() {
        _streak = streakData.currentStreak;
        _totalXp = totalXp;
        _recommendations = recs;
        _dueTopics = due;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Greeting + Avatar (padded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good afternoon,',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Alvin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.textColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Semantics(
                      button: true,
                      label: 'Open profile',
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onNavigateTab != null) {
                            widget.onNavigateTab!(3); // Profile tab
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'A',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Streak & XP Chips Row (padded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: '$_streak-Day Streak',
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department, size: 18, color: AppColors.textDark),
                              const SizedBox(width: 6),
                              Text(
                                '$_streak-Day Streak',
                                key: const Key('home_streak_chip_text'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: '${XpService.formatXp(_totalXp)} XP',
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: context.borderColor),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt, size: 18, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text(
                                '${XpService.formatXp(_totalXp)} XP',
                                key: const Key('home_xp_chip_text'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textColor,
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

              const SizedBox(height: 10),

              // Full-Bleed Mascot Interactive Banner (Matching Figma prototype 1:1)
              Semantics(
                button: true,
                label: 'Open Owl Chat',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OwlChatScreen()),
                  );
                },
                child: SizedBox(
                  width: double.infinity,
                  height: 165,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Full-bleed Grey Banner Background (left-0 to width-100%, 92px height)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 92,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE2E8F0),
                            border: Border(
                              top: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                              bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                            ),
                          ),
                        ),
                      ),

                      // Giant Owl Mascot (Clipped feet, head poking 75px above banner into white space)
                      Positioned(
                        left: -60,
                        bottom: 0,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.72, // Crops lower feet/body flush with banner
                            child: Transform.rotate(
                              angle: -5 * 3.1415926535 / 180, // -5 degrees from Figma
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                width: 270,
                                height: 245,
                                child: Image.asset(
                                  AppAssets.owlDashboard,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Speech Bubble on the right (with attached pointer tail)
                      Positioned(
                        left: 140,
                        right: 20,
                        bottom: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E293B).withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Pointer Tail pointing left toward Owl
                              Positioned(
                                left: -7,
                                top: 20,
                                child: CustomPaint(
                                  size: const Size(8, 14),
                                  painter: _SpeechTailPainter(color: Colors.white),
                                ),
                              ),

                              // Text content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Owl',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Ready for your 5-min Calculus check-in?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

              const SizedBox(height: 20),

              // Padded main body sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions Header
                    Text(
                      'Quick actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2x2 Grid for Quick Actions
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.0,
                      children: [
                        _buildQuickActionCard(
                          context,
                          title: 'Take Assessment',
                          semanticLabel: 'Take Assessment',
                          icon: Icons.assignment_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizScreen(isDiagnostic: true),
                              ),
                            ).then((_) => _loadHomeData());
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'My Study Groups',
                          semanticLabel: 'Open Study Groups',
                          icon: Icons.groups_outlined,
                          onTap: () {
                            if (widget.onNavigateTab != null) {
                              widget.onNavigateTab!(2);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudyGroupsScreen(),
                                ),
                              );
                            }
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Study Schedule',
                          semanticLabel: 'Open Study Schedule',
                          icon: Icons.calendar_today_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PlannerScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'Browse Materials',
                          semanticLabel: 'Browse Materials',
                          icon: Icons.menu_book_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MaterialsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Reviews Due Section (SM-2 Spaced Repetition)
                    _buildReviewsDueCard(context),

                    const SizedBox(height: 20),

                    // For You Section
                    _buildForYouSection(context),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: Material(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: context.textColor),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsDueCard(BuildContext context) {
    final count = _dueTopics.length;
    if (count == 0) {
      return Semantics(
        label: "No reviews due — you're all caught up",
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "No reviews due — you're all caught up",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final label = '$count ${count == 1 ? 'review' : 'reviews'} due today';
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlannerScreen()),
          );
          _loadHomeData();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: context.textColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view scheduled SM-2 reviews',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'For You',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            Semantics(
              button: true,
              label: 'View all recommendations',
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationsHubScreen(),
                    ),
                  );
                },
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recommendations.isEmpty)
          _buildEmptyStateCard(context)
        else ...[
          _buildTopRecommendationCard(context, _recommendations[0]),
          if (_recommendations.length > 1) ...[
            const SizedBox(height: 12),
            _buildSecondaryRecommendationCard(context, _recommendations[1]),
          ],
        ],
      ],
    );
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 36, color: context.isDark ? AppColors.accent : AppColors.primary),
          const SizedBox(height: 10),
          Text(
            'Take your first quiz to get your study plan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete a quiz to unlock personalized topic recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: 'Take Assessment',
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuizScreen(isDiagnostic: true)),
                );
                _loadHomeData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(180, 44),
              ),
              child: const Text(
                'Take Assessment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isQuizAction(RecommendationItem rec) {
    if (rec.priority == 'Low' || (rec.mastery != null && rec.mastery! >= 0.7)) {
      return false;
    }
    return true;
  }

  void _handleRecommendationTap(BuildContext context, RecommendationItem rec) async {
    if (_isQuizAction(rec)) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            subject: rec.subject,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MaterialsScreen(),
        ),
      );
    }
    _loadHomeData();
  }

  Color _priorityColor(String priority) {
    if (priority == 'High priority') return AppColors.error;
    if (priority == 'Medium') return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildTopRecommendationCard(BuildContext context, RecommendationItem rec) {
    final isQuiz = _isQuizAction(rec);
    final semanticLabel = isQuiz ? 'Take ${rec.subject} quiz' : 'Review ${rec.subject} notes';
    final subtitle = rec.reason != null && rec.reason!.isNotEmpty
        ? rec.reason!
        : '${rec.priority} • ${rec.timeEstimate} review • Quiz ready';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () => _handleRecommendationTap(context, rec),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: _priorityColor(rec.priority),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rec.subject} — ${rec.topic}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Priority: ${rec.priority.replaceAll(' priority', '')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _priorityColor(rec.priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Icon(Icons.chevron_right, color: context.textSecondaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryRecommendationCard(BuildContext context, RecommendationItem rec) {
    final isQuiz = _isQuizAction(rec);
    final semanticLabel = isQuiz ? 'Take ${rec.subject} quiz' : 'Review ${rec.subject} notes';
    final subtitle = rec.reason != null && rec.reason!.isNotEmpty
        ? rec.reason!
        : 'Review notes • ${rec.timeEstimate}';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: () => _handleRecommendationTap(context, rec),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rec.subject} — ${rec.topic}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  final Color color;
  const _SpeechTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(8, 0)
      ..lineTo(0, 7)
      ..lineTo(8, 14)
      ..close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
