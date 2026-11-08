import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'group_chat_screen.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  int _selectedTab = 0; // 0: My Groups, 1: Discover

  void _showCreateGroupDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Study Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Group name (e.g. Physics Prep)',
          ),
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
                SnackBar(content: Text('Created "${controller.text.isEmpty ? "New Group" : controller.text}"!')),
              );
            },
            child: const Text('Create'),
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
                    'Study Groups',
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
                        AppAssets.owlWaving,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Segment Tabs: My Groups / Discover
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.backgroundDark : Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: _selectedTab == 0 ? Colors.transparent : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'My Groups',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 0 ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.backgroundDark : Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: _selectedTab == 1 ? Colors.transparent : AppColors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedTab == 1 ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Group Card 1: Calculus Crew
              _buildGroupCard(
                title: 'Calculus Crew',
                subtitle: '12 members • 3 online',
                statusColor: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupChatScreen(groupName: 'Calculus Crew'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Group Card 2: Bio Study Squad
              _buildGroupCard(
                title: 'Bio Study Squad',
                subtitle: '8 members • 5 online',
                statusColor: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupChatScreen(groupName: 'Bio Study Squad'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Chat Preview Box
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GroupChatScreen(groupName: 'Calculus Crew'),
                    ),
                  );
                },
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
                      const Text(
                        'Calculus Crew — Chat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Maya: Did anyone solve Q4?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Owl: Hint — try the chain rule',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(19),
                        ),
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Message…',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // + Create Study Group Button (Primary Amber)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _showCreateGroupDialog,
                  child: const Text(
                    '+ Create Study Group',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Find Users to Invite
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.textDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening user search...')),
                    );
                  },
                  child: const Text(
                    'Find Users to Invite',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // View Invites (2)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.textDark),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('2 invitations pending')),
                    );
                  },
                  child: const Text(
                    'View Invites (2)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
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

  Widget _buildGroupCard({
    required String title,
    required String subtitle,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
