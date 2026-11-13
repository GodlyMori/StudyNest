import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../ml/question_attempt.dart';
import '../../ml/topic_progress_analytics.dart';
import '../../services/attempt_sync_service.dart';
import '../../services/network_service.dart';
import '../../services/streak_service.dart';
import '../../services/supabase_service.dart';
import '../../services/guest_score_service.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/topic_trend_line.dart';
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
  List<TopicProgressData> _topicProgressList = [];
  StreakData? _streakData;

  static const List<({String subject, String topic})> _coreTopics = [
    (subject: 'Calculus', topic: 'Derivatives'),
    (subject: 'Calculus', topic: 'Limits'),
    (subject: 'Calculus', topic: 'Integrals'),
    (subject: 'Biology', topic: 'Cell Structure'),
    (subject: 'Biology', topic: 'Genetics'),
    (subject: 'History', topic: 'World War II'),
    (subject: 'Physics', topic: 'Newton’s Laws'),
  ];

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

    // Load real question attempts for mastery-over-time trend lines
    var attempts = await AttemptSyncService.logger.getAttempts(userId: user?.id);
    if (attempts.isEmpty &&
        user != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = await SupabaseService.instance.client
            .from('question_attempts')
            .select()
            .eq('user_id', user.id)
            .order('answered_at', ascending: true);
        attempts = (rows as List)
            .map((r) => QuestionAttempt.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (_) {}
    }

    // Build the list of topics: include topics with real attempts first,
    // followed by core topics so zero-attempt topics display honest empty states.
    final seen = <String>{};
    final combinedTopics = <({String subject, String topic})>[];
    for (final a in attempts) {
      final key = '${a.subject.trim()}::${a.topic.trim()}';
      if (seen.add(key)) {
        combinedTopics.add((subject: a.subject.trim(), topic: a.topic.trim()));
      }
    }
    for (final core in _coreTopics) {
      final key = '${core.subject}::${core.topic}';
      if (seen.add(key)) {
        combinedTopics.add(core);
      }
    }

    const analytics = TopicProgressAnalytics();
    final progressList = combinedTopics.map((item) {
      return analytics.computeTopicProgress(
        subject: item.subject,
        topic: item.topic,
        attempts: attempts,
      );
    }).toList();

    // Compute real consecutive-day streak and daily goal progress (Task 5.4)
    final quizTimestamps = <DateTime>[];
    for (final s in scores) {
      final raw = s['created_at'] ?? s['date'];
      if (raw != null) {
        try {
          quizTimestamps.add(DateTime.parse(raw.toString()).toLocal());
        } catch (_) {}
      }
    }
    for (final a in attempts) {
      quizTimestamps.add(a.answeredAt.toLocal());
    }

    final streakData = await StreakService.computeStreakData(
      completedQuizTimestamps: quizTimestamps,
    );

    if (mounted) {
      setState(() {
        _profile = profile;
        _quizScores = scores;
        _topicProgressList = progressList;
        _streakData = streakData;
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
                        Text(
                          '${_streakData?.currentStreak ?? 0}-Day Streak • Active Goal',
                          style: const TextStyle(
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

              const SizedBox(height: 20),

              // Daily Goal & Streak Freeze Card (Task 5.4)
              _buildDailyGoalAndStreakCard(),

              const SizedBox(height: 24),

              // Topic Mastery & Analytics Section (Task 5.3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Topic mastery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Tap topic to practice',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              ..._topicProgressList.map((progress) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildTopicProgressCard(context, progress),
                  )),

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

  Widget _buildDailyGoalAndStreakCard() {
    final streak = _streakData?.currentStreak ?? 0;
    final todayDone = _streakData?.todayQuizzesCompleted ?? 0;
    final goal = _streakData?.dailyGoal ?? 1;
    final goalMet = todayDone >= goal;
    final freezes = _streakData?.freezesRemaining ?? 1;
    final canFreeze = _streakData?.canUseFreeze ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Daily Quiz Goal',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: goalMet ? AppColors.successLight : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  goalMet ? 'Goal Met' : '$todayDone / $goal done',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: goalMet ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal > 0 ? (todayDone / goal).clamp(0.0, 1.0) : 0.0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                goalMet ? AppColors.success : AppColors.accent,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$todayDone of $goal quizzes done today',
            key: const Key('daily_goal_progress_text'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1, color: AppColors.border),
          ),

          // Streak & Freeze Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak-day streak',
                        key: const Key('streak_count_text'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    freezes > 0
                        ? '$freezes freeze available this week'
                        : 'Streak freeze used this week (0 remaining)',
                    key: const Key('streak_freeze_remaining_text'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              if (canFreeze)
                ElevatedButton(
                  key: const Key('use_streak_freeze_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.backgroundDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final success = await StreakService.spendStreakFreeze();
                    if (success && mounted) {
                      await _loadProfileAndScores();
                    }
                  },
                  child: const Text(
                    'Use streak freeze',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopicProgressCard(
    BuildContext context,
    TopicProgressData data,
  ) {
    final hasAttempts = data.hasAttempts;
    final masteryPercent = (data.currentMastery * 100).round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('topic_card_${data.topic}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TopicsQuizzesScreen()),
            ).then((_) => _loadProfileAndScores());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Left: Topic title and Subject
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data.topic,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data.subject,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (hasAttempts)
                        Text(
                          '$masteryPercent% mastery • ${data.totalAttempts} ${data.totalAttempts == 1 ? 'attempt' : 'attempts'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        const Text(
                          'No attempts yet',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Sparkline Trend Line or Empty State indicator
                if (hasAttempts) ...[
                  TopicTrendLine(
                    key: Key('topic_trend_${data.topic}'),
                    points: data.points,
                    isImproving: data.isImproving,
                  ),
                  const SizedBox(width: 8),
                ],

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
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
