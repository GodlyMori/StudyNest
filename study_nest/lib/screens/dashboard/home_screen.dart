import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../quiz/topics_quizzes_screen.dart';
import '../quiz/quiz_screen.dart';
import '../groups/study_groups_screen.dart';
import '../planner/planner_screen.dart';
import '../materials/materials_screen.dart';
import '../owl_chat/owl_chat_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                      children: const [
                        Text(
                          'Good afternoon,',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Alvin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        if (onNavigateTab != null) {
                          onNavigateTab!(3); // Profile tab
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
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.local_fire_department, size: 18, color: AppColors.textDark),
                            SizedBox(width: 6),
                            Text(
                              '5-Day Streak',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.bolt, size: 18, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              '1,240 XP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Full-Bleed Mascot Interactive Banner (Matching Figma prototype 1:1)
              GestureDetector(
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

              const SizedBox(height: 20),

              // Padded main body sections
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions Header
                    const Text(
                      'Quick actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
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
                          icon: Icons.assignment_outlined,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizScreen(),
                              ),
                            );
                          },
                        ),
                        _buildQuickActionCard(
                          context,
                          title: 'My Study Groups',
                          icon: Icons.groups_outlined,
                          onTap: () {
                            if (onNavigateTab != null) {
                              onNavigateTab!(2);
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

                    const SizedBox(height: 24),

                    // For You Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'For You',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TopicsQuizzesScreen(),
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
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recommendation Card 1: Calculus
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(subject: 'Calculus'),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 6,
                                color: AppColors.success,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Calculus — Derivatives',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Weak topic • 8-min review • Quiz ready',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Priority: High',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 14.0),
                                child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Recommendation Card 2: Biology
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaterialsScreen(),
                          ),
                        );
                      },
                      child: Container(
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
                              children: const [
                                Text(
                                  'Biology — Cell Structure',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review notes • 5 min',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),

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
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.textDark),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
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
