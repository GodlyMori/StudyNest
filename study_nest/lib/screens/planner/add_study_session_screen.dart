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

  @override
  State<AddStudySessionScreen> createState() => _AddStudySessionScreenState();
}

class _AddStudySessionScreenState extends State<AddStudySessionScreen> {
  final _titleController = TextEditingController();
  String _selectedSubject = 'Calculus';
  final List<String> _subjects = ['Calculus', 'Biology', 'History', 'Physics'];

  DateTime _selectedDate = DateTime(2026, 11, 7); // Defaults to Thursday
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0); // 2:00 PM
  bool _reminderEnabled = false;

  final List<String> _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (widget.initialDay != null) {
      final index = _weekDays.indexOf(widget.initialDay!);
      if (index >= 0) {
        // Map to November 2026 dates (Mon 4 .. Sun 10)
        _selectedDate = DateTime(2026, 11, 4 + index);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatDisplayDate(DateTime date) {
    final dayName = _weekDays[date.weekday - 1];
    return '$dayName, ${date.day} Nov ${date.year}';
  }

  String _getDayName(DateTime date) {
    return _weekDays[date.weekday - 1];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
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
    final startTimeStr = _formatTimeOfDay(_selectedTime);
    // End time 30 mins later
    final endMinute = (_selectedTime.minute + 30) % 60;
    final endHour = _selectedTime.hour + ((_selectedTime.minute + 30) ~/ 60);
    final endTime = TimeOfDay(hour: endHour % 24, minute: endMinute);
    final endTimeStr = _formatTimeOfDay(endTime);
    final timeRangeStr = '$startTimeStr – $endTimeStr';

    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final notificationId = sessionId.hashCode & 0x7FFFFFFF;

    final session = StudySession(
      id: sessionId,
      title: title,
      subject: _selectedSubject,
      date: dayName,
      time: timeRangeStr,
      type: 'Self Study',
      duration: '30 min',
      status: 'Scheduled',
      reminderEnabled: _reminderEnabled,
      notificationId: _reminderEnabled ? notificationId : null,
    );

    // Save session to local SharedPreferences
    await PlannerService.saveSession(session);

    // If reminder enabled, schedule notification
    if (_reminderEnabled) {
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await NotificationService.scheduleSessionReminder(
        id: notificationId,
        title: title,
        body: 'Starts at $startTimeStr for $_selectedSubject',
        scheduledDateTime: scheduledDateTime,
        dateStr: _formatDisplayDate(_selectedDate),
        timeStr: startTimeStr,
      );
    }

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Study Session',
          style: TextStyle(
            color: AppColors.textDark,
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
              const Text(
                'Session Title',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Physics Prep & Formulas',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Subject Dropdown
              const Text(
                'Subject',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSubject,
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
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textDark,
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
              const Text(
                'Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDisplayDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
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

              const SizedBox(height: 20),

              // Time Field (Figma frame 44 picker)
              const Text(
                'Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_selectedTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
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

              const SizedBox(height: 24),

              // Reminder Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
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
                          children: const [
                            Text(
                              'Remind Me',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
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
                    Switch(
                      value: _reminderEnabled,
                      activeColor: AppColors.accent,
                      onChanged: _onReminderToggleChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
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
            ],
          ),
        ),
      ),
    );
  }
}
