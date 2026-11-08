import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../owl_chat/owl_chat_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  int _selectedDayIndex = 2; // Wednesday

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _dates = ['4', '5', '6', '7', '8', '9', '10'];

  final List<Map<String, String>> _sessions = [
    {
      'time': '2:00 PM – 2:30 PM',
      'subject': 'Calculus — Derivatives Check-in',
      'type': 'Review & 5-min Quiz',
      'duration': '30 min',
      'status': 'Upcoming',
    },
    {
      'time': '4:30 PM – 5:15 PM',
      'subject': 'Biology — Cell Structure Flashcards',
      'type': 'Notes & Memorization',
      'duration': '45 min',
      'status': 'Scheduled',
    },
    {
      'time': '7:00 PM – 8:00 PM',
      'subject': 'Calculus Crew — Group Study Session',
      'type': 'Peer Discussion',
      'duration': '60 min',
      'status': 'Group Call',
    },
  ];

  void _showAddSessionDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Study Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Session Title (e.g. Physics Prep)',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select date & time for your calendar notifications.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textDark,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Study session scheduled!')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
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
              // Header
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OwlChatScreen()),
                      );
                    },
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Image.asset(
                        AppAssets.owlSitting,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
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
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
                        });
                      },
                      child: Container(
                        width: 42,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.textDark : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dates[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.textDark : AppColors.textDark,
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
                    const Icon(Icons.alarm_on, color: AppColors.primary, size: 28),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sessions list
              const Text(
                'Today\'s Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

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
                              session['time']!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                session['status']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          session['subject']!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session['type']} • ${session['duration']}',
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

              // + Add Study Session Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _showAddSessionDialog,
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
