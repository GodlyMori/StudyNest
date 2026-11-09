import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../services/guest_score_service.dart';
import '../../widgets/empty_state_view.dart';
import '../auth/welcome_screen.dart';
import 'settings_screen.dart';
import '../quiz/quiz_screen.dart';
import '../quiz/topics_quizzes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _quizScores = [];

  @override
  void initState() {
    super.initState();
    _loadProfileAndScores();
  }

  Future<void> _loadProfileAndScores() async {
    final user = SupabaseService.instance.currentUser;
    Map<String, dynamic>? profile;
    if (user != null && SupabaseService.instance.isInitialized) {
      try {
        profile = await SupabaseService.instance.getProfile(user.id);
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final localName = prefs.getString('user_display_name');
    if (localName != null && localName.isNotEmpty) {
      final parts = localName.trim().split(RegExp(r'\s+'));
      final initials = parts.length == 1
          ? parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase()
          : '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      profile = {
        ...?profile,
        'display_name': localName,
        'avatar_initials': initials,
      };
    }

    final scores = await GuestScoreService.getScoresForUser(userId: user?.id);

    if (mounted) {
      setState(() {
        _profile = profile;
        _quizScores = scores;
      });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out of StudyNest?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await SupabaseService.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final isGuest = user == null;
    final displayName = _profile?['display_name'] ?? (isGuest ? 'Guest Student' : 'Alvin Legarbes');
    final initials = _profile?['avatar_initials'] ?? (isGuest ? 'G' : 'AL');
    final level = _profile?['level'] ?? (isGuest ? 1 : 6);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title + Settings Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile & Progress',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) => _loadProfileAndScores());
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // User Info Row
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGuest ? 'Guest • Level $level' : 'Student • Level $level',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '5-Day Streak • 1,240 XP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Subject Mastery Header
              const Text(
                'Subject mastery',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              _buildSubjectProgress(
                subject: 'Calculus',
                percentage: 78,
                barColor: AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildSubjectProgress(
                subject: 'Biology',
                percentage: 62,
                barColor: AppColors.accent,
              ),
              const SizedBox(height: 12),
              _buildSubjectProgress(
                subject: 'History',
                percentage: 45,
                barColor: AppColors.backgroundDark,
              ),

              const SizedBox(height: 28),

              // Quiz History Section
              const Text(
                'Quiz history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              if (_quizScores.isNotEmpty)
                ..._quizScores.reversed.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildQuizHistoryItem(
                        context,
                        title: s['subject'] ?? 'Calculus',
                        subtitle: 'Recent • ${s['score']}% • ${s['grade'] ?? 'Grade B'}',
                      ),
                    ))
              else
                EmptyStateView(
                  icon: Icons.quiz_outlined,
                  title: 'No quiz history yet',
                  message: 'Complete your first quiz to track your scores, mastery, and streaks.',
                  actionLabel: 'Take a Quiz',
                  onAction: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TopicsQuizzesScreen()),
                    );
                  },
                ),

              const SizedBox(height: 32),

              // Log Out Button (Figma Frame 09 Profile for Log Out)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _confirmLogout,
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectProgress({
    required String subject,
    required int percentage,
    required Color barColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHistoryItem(
    BuildContext context, {
    required String title,
    required String subtitle,
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizScreen(subject: title),
                ),
              ).then((_) => _loadProfileAndScores());
            },
            child: const Text(
              'Retake',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
