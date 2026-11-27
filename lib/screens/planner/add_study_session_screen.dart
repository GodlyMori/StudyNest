import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/study_session.dart';
import '../../services/notification_service.dart';
import '../../services/planner_service.dart';
import '../../widgets/notification_permission_dialog.dart';

class AddStudySessionScreen extends StatefulWidget {
  final String? initialDay;

  const AddStudySessionScreen({
    super.key,
    this.initialDay,
  });

  static const List<String> _weekDaysList = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _monthAbbrs = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  static String formatDisplayDate(DateTime date) {
    final dayName = _weekDaysList[date.weekday - 1];
    final monthAbbr = _monthAbbrs[date.month - 1];
    return '$dayName, ${date.day} $monthAbbr ${date.year}';
  }

  /// Shared session-creation helper used by both the Add Study Session form
  /// and one-tap SM-2 due-review suggestions on the Planner screen.
  static Future<StudySession> createAndSaveSession({
    required String title,
    required String subject,
    required DateTime scheduledDate,
    required TimeOfDay scheduledTime,
    required bool reminderEnabled,
    String type = 'Self Study',
    String? dayOverride,
  }) async {
    final dayName = dayOverride ?? _weekDaysList[scheduledDate.weekday - 1];
    final startTimeStr = formatTimeOfDay(scheduledTime);
    final endMinute = (scheduledTime.minute + 30) % 60;
    final endHour = scheduledTime.hour + ((scheduledTime.minute + 30) ~/ 60);
    final endTime = TimeOfDay(hour: endHour % 24, minute: endMinute);
    final endTimeStr = formatTimeOfDay(endTime);
    final timeRangeStr = '$startTimeStr – $endTimeStr';

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final notificationId = sessionId.hashCode & 0x7FFFFFFF;

    final session = StudySession(
      id: sessionId,
      title: title,
      subject: subject,
      date: dayName,
      time: timeRangeStr,
      type: type,
      duration: '30 min',
      status: 'Scheduled',
      reminderEnabled: reminderEnabled,
      notificationId: reminderEnabled ? notificationId : null,
    );

    await PlannerService.saveSession(session);

    if (reminderEnabled) {
      final scheduledDateTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );

      await NotificationService.scheduleSessionReminder(
        id: notificationId,
        title: title,
        body: 'Starts at $startTimeStr for $subject',
        scheduledDateTime: scheduledDateTime,
        dateStr: formatDisplayDate(scheduledDate),
        timeStr: startTimeStr,
      );
    }

    return session;
  }

  @override
  State<AddStudySessionScreen> createState() => _AddStudySessionScreenState();
}

class _AddStudySessionScreenState extends State<AddStudySessionScreen> {
  final _titleController = TextEditingController();
  String _selectedSubject = 'Calculus';
  final List<String> _subjects = ['Calculus', 'Biology', 'History', 'Physics'];

  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0); // 2:00 PM
  bool _reminderEnabled = false;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    if (widget.initialDay != null) {
      final index = _weekDays.indexOf(widget.initialDay!);
      if (index >= 0) {
        _selectedDate = monday.add(Duration(days: index));
      } else {
        _selectedDate = today;
      }
    } else {
      _selectedDate = monday.add(const Duration(days: 3)); // Defaults to Thursday of current week
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    return AddStudySessionScreen.formatTimeOfDay(tod);
  }

  String _formatDisplayDate(DateTime date) {
    return AddStudySessionScreen.formatDisplayDate(date);
  }

  String _getDayName(DateTime date) {
    return _weekDays[date.weekday - 1];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_selectedDate.year - 1, 1, 1),
      lastDate: DateTime(_selectedDate.year + 1, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _onReminderToggleChanged(bool value) async {
    if (value) {
      final granted = await NotificationPermissionDialog.requestIfNeeded(context);
      if (mounted) {
        setState(() {
          _reminderEnabled = granted;
        });
      }
    } else {
      setState(() {
        _reminderEnabled = false;
      });
    }
  }

  Future<void> _saveSession() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a session title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final dayName = _getDayName(_selectedDate);
    await AddStudySessionScreen.createAndSaveSession(
      title: title,
      subject: _selectedSubject,
      scheduledDate: _selectedDate,
      scheduledTime: _selectedTime,
      reminderEnabled: _reminderEnabled,
      dayOverride: dayName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session scheduled for $dayName!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Study Session',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Title
              Text(
                'Session Title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Session Title',
                    hintText: 'e.g. Physics Prep & Formulas',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subject Dropdown
              Text(
                'Subject',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
                    dropdownColor: context.cardColor,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textSecondary,
                    ),
                    isExpanded: true,
                    items: _subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(
                          subject,
                          style: TextStyle(
                            fontSize: 15,
                            color: context.textColor,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSubject = val;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Date Field (Figma frame 43 picker)
              Text(
                'Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Pick date',
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDisplayDate(_selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textColor,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time Field (Figma frame 44 picker)
              Text(
                'Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Pick time',
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimeOfDay(_selectedTime),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textColor,
                          ),
                        ),
                        const Icon(
                          Icons.access_time_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Reminder Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _reminderEnabled
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.border.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _reminderEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            size: 20,
                            color: _reminderEnabled
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Remind Me',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Send notification at session start time',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Semantics(
                      label: 'Remind me notification toggle',
                      child: Switch(
                        value: _reminderEnabled,
                        activeColor: AppColors.accent,
                        onChanged: _onReminderToggleChanged,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Semantics(
                  button: true,
                  label: 'Save study session',
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _saveSession,
                    child: const Text(
                      'Save Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
