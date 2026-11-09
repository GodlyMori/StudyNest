import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../data/study_materials.dart';
import '../../models/study_group.dart';
import '../../models/group_member.dart';
import '../../models/group_message.dart';
import '../../services/group_service.dart';
import '../materials/material_detail_screen.dart';
import 'find_users_screen.dart';
import 'group_chat_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final StudyGroup group;

  const GroupDetailScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late StudyGroup _group;
  List<GroupMember> _members = [];
  List<GroupMessage> _recentMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final detail = await GroupService.getGroupDetail(_group.id);
    if (mounted) {
      setState(() {
        _group = (detail['group'] as StudyGroup?) ?? _group;
        _members = (detail['members'] as List<GroupMember>?) ?? [];
        _recentMessages = (detail['messages'] as List<GroupMessage>?) ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoin() async {
    await GroupService.joinGroup(_group.id);
    if (mounted) {
      setState(() {
        _group = _group.copyWith(isJoined: true, memberCount: _group.memberCount + 1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${_group.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Per Figma frame 17: Join leads to Group Chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(
            groupId: _group.id,
            groupName: _group.name,
          ),
        ),
      );
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          groupId: _group.id,
          groupName: _group.name,
        ),
      ),
    );
  }

  void _openInviteUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FindUsersScreen(
          groupId: _group.id,
          groupName: _group.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sharedMaterials = StudyMaterialBank.getMaterials();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _group.name,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Invite Members',
            icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.textDark),
            onPressed: _openInviteUsers,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Overview Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _group.subject,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentDark,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_group.onlineCount} online',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _group.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _group.description.isNotEmpty
                                ? _group.description
                                : 'A collaborative study group for learning and problem solving.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Join or Open Chat button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _group.isJoined
                                    ? AppColors.primary
                                    : AppColors.accent,
                                foregroundColor: _group.isJoined
                                    ? Colors.white
                                    : AppColors.textDark,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _group.isJoined ? _openChat : _handleJoin,
                              icon: Icon(
                                _group.isJoined ? Icons.chat_bubble_outline : Icons.group_add,
                                size: 18,
                              ),
                              label: Text(
                                _group.isJoined ? 'Open Group Chat' : 'Join Group',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Members Section (avatars + names per Figma frame 17)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Members (${_group.memberCount})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: _openInviteUsers,
                          child: const Text(
                            '+ Invite',
                            style: TextStyle(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: _members.map((member) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary.withOpacity(0.12),
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0] : 'S',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: member.role == 'Admin'
                                        ? AppColors.accent.withOpacity(0.15)
                                        : AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    member.role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: member.role == 'Admin'
                                          ? AppColors.accentDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Shared Materials Section
                    const Text(
                      'Shared Materials',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...sharedMaterials.take(2).map((material) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MaterialDetailScreen(material: material),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          material.meta,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Chat Preview Section (tapping opens GroupChatScreen)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chat Preview',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: _openChat,
                          child: const Text(
                            'Open Full Chat →',
                            style: TextStyle(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: _openChat,
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
                            if (_recentMessages.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No messages yet. Tap to start the conversation!',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              )
                            else
                              ..._recentMessages.take(2).map((msg) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${msg.senderName}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          msg.content,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            const SizedBox(height: 12),
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(19),
                              ),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                'Tap to send a message…',
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

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}
