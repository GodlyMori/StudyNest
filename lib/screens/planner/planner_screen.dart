import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../ml/bkt_mastery.dart';
import '../../models/flashcard.dart';
import '../../models/study_session.dart';
import '../../services/flashcard_service.dart';
import '../../services/mastery_service.dart';
import '../../services/notification_service.dart';
import '../../services/planner_service.dart';
import '../../widgets/empty_state_view.dart';
import '../materials/flashcard_study_screen.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'add_study_session_screen.dart';
import 'notifications_list_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _selectedDayIndex = 2; // Wednesday (starting data)

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _dates = ['4', '5', '6', '7', '8', '9', '10'];

  List<StudySession> _sessions = [];
  List<TopicMastery> _dueReviews = [];
  List<Flashcard> _dueFlashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final dayName = _days[_selectedDayIndex];
    final dayDate = _dates[_selectedDayIndex];
    final sessions = await PlannerService.getSessionsForDay(dayName, dayDate);
    final due = await MasteryService.tracker.getDueTopics();
    final dueCards = await FlashcardService.getDueFlashcards();
    final filteredDue = due.where((m) {
      final expectedTitle = 'Review: ${m.topic}';
      return !sessions.any((s) => s.title == expectedTitle);
    }).toList();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _dueReviews = filteredDue;
        _dueFlashcards = dueCards;
        _isLoading = false;
      });
    }
  }

  Future<void> _openDueFlashcardReview() async {
    if (_dueFlashcards.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardStudyScreen(
          title: 'Due Flashcards',
          cards: _dueFlashcards,
        ),
      ),
    );
    await _loadSessions();
  }

  Future<void> _scheduleDueReview(TopicMastery review) async {
    final selectedDate = DateTime(2026, 11, 4 + _selectedDayIndex);
    final reminderGranted = await NotificationService.isPermissionGranted();
    final title = 'Review: ${review.topic}';

    await AddStudySessionScreen.createAndSaveSession(
      title: title,
      subject: review.subject,
      scheduledDate: selectedDate,
      scheduledTime: const TimeOfDay(hour: 16, minute: 0),
      reminderEnabled: reminderGranted,
      type: 'Spaced Review',
      dayOverride: _days[_selectedDayIndex],
    );

    await _loadSessions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled $title for ${_days[_selectedDayIndex]}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDayIndex = index;
      _isLoading = true;
    });
    _loadSessions();
  }

  Future<void> _openAddSessionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudySessionScreen(
          initialDay: _days[_selectedDayIndex],
        ),
      ),
    );

    if (result == true) {
      await _loadSessions();
    }
  }

  void _openNotificationsList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsListScreen(),
      ),
    );
  }

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
              // Header with Title, Notifications Bell Icon, and Owl Mascot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Study Schedule',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Scheduled Reminders',
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.textDark,
                          size: 24,
                        ),
                        onPressed: _openNotificationsList,
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OwlChatScreen(),
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Image.asset(
                            AppAssets.owlSitting,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Calendar Days Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_days.length, (index) {
                    final isSelected = _selectedDayIndex == index;
                    return GestureDetector(
                      onTap: () => _onDaySelected(index),
                      child: Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dates[index],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Target / Goal Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Daily Goal: 45 min studied',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '30 min completed so far • 15 min left',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLightMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.alarm_on, color: AppColors.accent, size: 28),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SM-2 Reviews Due Section
              if (_dueReviews.isNotEmpty || _dueFlashcards.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reviews due',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '${_dueReviews.length + (_dueFlashcards.isNotEmpty ? 1 : 0)} due',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_dueFlashcards.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      key: const Key('due_flashcards_card'),
                      borderRadius: BorderRadius.circular(16),
                      onTap: _openDueFlashcardReview,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Flashcards (${_dueFlashcards.length} due)',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'SM-2 review ready • Tap to practice',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ..._dueReviews.map((review) {
                  final masteryPct = (review.mastery * 100).round();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _scheduleDueReview(review),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${review.subject} — ${review.topic}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mastery $masteryPct% • Review due (interval ${review.intervalDays}d)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '+ Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Sessions list
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_days[_selectedDayIndex]}\'s Plan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${_sessions.length} ${_sessions.length == 1 ? "session" : "sessions"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_sessions.isEmpty)
                EmptyStateView(
                  icon: Icons.event_busy_rounded,
                  title: 'No sessions for ${_days[_selectedDayIndex]}',
                  message:
                      'Plan your day by adding study sessions and setting reminders.',
                  actionLabel: 'Add Study Session',
                  onAction: _openAddSessionScreen,
                )
              else
                ..._sessions.map((session) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                session.time,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentDark,
                                ),
                              ),
                              Row(
                                children: [
                                  if (session.reminderEnabled)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6.0),
                                      child: Icon(
                                        Icons.alarm_on,
                                        size: 14,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      session.status,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.title.contains(session.subject)
                                ? '${session.type} • ${session.duration}'
                                : '${session.subject} • ${session.type} • ${session.duration}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),

              // + Add Study Session Button (opens full screen)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openAddSessionScreen,
                  child: const Text(
                    '+ Add Study Session',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
