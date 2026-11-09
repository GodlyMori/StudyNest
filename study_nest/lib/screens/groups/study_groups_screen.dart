import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_assets.dart';
import '../../models/study_group.dart';
import '../../services/group_service.dart';
import '../../services/network_service.dart';
import '../../widgets/empty_state_view.dart';
import '../owl_chat/owl_chat_screen.dart';
import 'create_group_screen.dart';
import 'find_users_screen.dart';
import 'group_chat_screen.dart';
import 'group_detail_screen.dart';
import 'group_invites_screen.dart';

class StudyGroupsScreen extends StatefulWidget {
  const StudyGroupsScreen({super.key});

  @override
  State<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

class _StudyGroupsScreenState extends State<StudyGroupsScreen> {
  int _selectedTab = 0; // 0: My Groups, 1: Discover
  List<StudyGroup> _myGroups = [];
  List<StudyGroup> _discoverGroups = [];
  int _pendingInvitesCount = 0;
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final online = await NetworkService.isOnline();
    if (!online) {
      if (mounted) {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
      return;
    }

    _isOffline = false;
    final my = await GroupService.getMyGroups();
    final disc = await GroupService.getDiscoverGroups();
    final invites = await GroupService.getPendingInvites();

    if (mounted) {
      setState(() {
        _myGroups = my;
        _discoverGroups = disc;
        _pendingInvitesCount = invites.length;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoin(StudyGroup group) async {
    await GroupService.joinGroup(group.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined "${group.name}"! Added to My Groups.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openGroupDetail(StudyGroup group) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(group: group),
      ),
    );
    if (updated == true) {
      await _loadData();
    }
  }

  void _openCreateGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
    await _loadData();
  }

  void _openFindUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindUsersScreen(),
      ),
    );
  }

  void _openInvites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupInvitesScreen(),
      ),
    );
    await _loadData();
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

              // Segment Tabs: My Groups / Discover (Figma frame 24)
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

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_isOffline)
                EmptyStateView(
                  icon: Icons.wifi_off_rounded,
                  title: 'No Internet Connection',
                  message:
                      'Study groups need an active internet connection to load. Please check your connection and retry.',
                  actionLabel: 'Retry',
                  onAction: () {
                    setState(() => _isLoading = true);
                    _loadData();
                  },
                )
              // Tab 0: My Groups
              else if (_selectedTab == 0) ...[
                if (_myGroups.isEmpty)
                  EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: 'No groups joined yet',
                    message:
                        'Join a public study group to share materials and chat with peers.',
                    actionLabel: 'Discover Groups',
                    onAction: () {
                      setState(() => _selectedTab = 1);
                    },
                  )
                else
                  ..._myGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildGroupCard(
                        title: group.name,
                        subtitle: '${group.memberCount} members • ${group.onlineCount} online',
                        statusColor: AppColors.success,
                        onTap: () => _openGroupDetail(group),
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Chat Preview Box for My Groups
                if (_myGroups.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      final primaryGroup = _myGroups.first;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupChatScreen(
                            groupId: primaryGroup.id,
                            groupName: primaryGroup.name,
                          ),
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
                          Text(
                            '${_myGroups.first.name} — Chat',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Maya: Did anyone solve Q4?',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Owl: Hint — try the chain rule',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              ]
              // Tab 1: Discover Groups (Figma frame 24)
              else ...[
                if (_discoverGroups.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.check_circle_outline, size: 40, color: AppColors.success),
                        SizedBox(height: 12),
                        Text(
                          'You\'ve joined all public groups!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check My Groups to chat and study with your classmates.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._discoverGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups,
                                color: AppColors.accentDark,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${group.subject} • ${group.memberCount} members',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.textDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () => _handleJoin(group),
                              child: const Text(
                                'Join',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],

              const SizedBox(height: 24),

              // + Create Study Group Button (Figma frame 16)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _openCreateGroup,
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

              // Find Users to Invite (Figma frames 22, 31, 32)
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
                  onPressed: _openFindUsers,
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

              // View Invites (Figma frame 23)
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
                  onPressed: _openInvites,
                  child: Text(
                    'View Invites ($_pendingInvitesCount)',
                    style: const TextStyle(
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
