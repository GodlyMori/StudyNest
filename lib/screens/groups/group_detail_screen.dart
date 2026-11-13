import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../data/study_materials.dart';
import '../../models/group_challenge.dart';
import '../../models/study_group.dart';
import '../../models/group_member.dart';
import '../../models/group_message.dart';
import '../../services/group_extras_service.dart';
import '../../services/group_service.dart';
import '../materials/material_detail_screen.dart';
import '../quiz/quiz_screen.dart';
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
  List<GroupLeaderboardEntry> _leaderboard = [];
  List<GroupChallenge> _challenges = [];
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
    final members = (detail['members'] as List<GroupMember>?) ?? [];
    final leaderboard =
        await GroupExtrasService.getGroupLeaderboard(_group.id, members);
    final challenges = await GroupExtrasService.getChallenges(_group.id);

    if (mounted) {
      setState(() {
        _group = (detail['group'] as StudyGroup?) ?? _group;
        _leaderboard = leaderboard;
        _challenges = challenges;
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

  void _showCreateChallengeDialog() {
    String selectedSubject = ['Calculus', 'Biology', 'History', 'Physics']
            .contains(_group.subject)
        ? _group.subject
        : 'Calculus';
    int selectedCount = 5;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start a Quiz Challenge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Subject',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedSubject,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Calculus', child: Text('Calculus')),
                  DropdownMenuItem(value: 'Biology', child: Text('Biology')),
                  DropdownMenuItem(value: 'History', child: Text('History')),
                  DropdownMenuItem(value: 'Physics', child: Text('Physics')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => selectedSubject = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Number of Questions',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [5, 10, 15].map((cnt) {
                  final isSelected = selectedCount == cnt;
                  return ChoiceChip(
                    label: Text('$cnt Questions'),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    onSelected: (sel) {
                      if (sel) {
                        setModalState(() => selectedCount = cnt);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('confirm_create_challenge_button'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    await GroupExtrasService.createChallenge(
                      groupId: _group.id,
                      subject: selectedSubject,
                      questionCount: selectedCount,
                    );
                    if (!mounted) return;
                    await _loadGroupData();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Challenge created! Share it with your group.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Create Challenge',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takeChallenge(GroupChallenge challenge) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          subject: challenge.subject,
          targetQuestionCount: challenge.questionCount,
          isAdaptive: false,
          onQuizCompleted: (score, total) async {
            await GroupExtrasService.recordChallengeAttempt(
              groupId: _group.id,
              challengeId: challenge.id,
              score: score,
              total: total,
            );
          },
        ),
      ),
    );
    await _loadGroupData();
  }

  Widget _buildLeaderboardRow(GroupLeaderboardEntry entry, int rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 26,
            alignment: Alignment.center,
            child: entry.hasScores
                ? Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: rank == 1 ? AppColors.accentDark : AppColors.textSecondary,
                    ),
                  )
                : const Text(
                    '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              entry.name.isNotEmpty ? entry.name[0] : 'S',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  entry.role,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (entry.hasScores)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${entry.averageScore!.toStringAsFixed(0)}% avg (${entry.quizCount} quiz${entry.quizCount > 1 ? 'zes' : ''})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            )
          else
            const Text(
              'No quizzes yet',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(GroupChallenge challenge) {
    return Container(
      key: Key('challenge_card_${challenge.id}'),
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${challenge.subject} • ${challenge.questionCount} Questions',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ElevatedButton(
                key: Key('take_challenge_button_${challenge.id}'),
                onPressed: () => _takeChallenge(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Take Challenge',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Created by ${challenge.creatorName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ranked Board',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          if (challenge.attempts.isEmpty)
            const Text(
              'No attempts yet. Be the first to complete this challenge!',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: challenge.attempts.map((attempt) {
                final rankIdx = challenge.attempts.indexOf(attempt) + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text(
                        '#$rankIdx',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attempt.userName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${attempt.percentage}% (${attempt.score}/${attempt.total})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
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

                    // Members & Leaderboard Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Members (${_group.memberCount})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Leaderboard',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
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
                      key: const Key('group_leaderboard_container'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _leaderboard.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'No members found.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < _leaderboard.length; i++) ...[
                                  _buildLeaderboardRow(_leaderboard[i], i + 1),
                                  if (i < _leaderboard.length - 1)
                                    const Divider(height: 12, color: AppColors.border),
                                ],
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Shared Quiz Challenges Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quiz Challenges',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        TextButton.icon(
                          key: const Key('create_challenge_button'),
                          onPressed: _showCreateChallengeDialog,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.accentDark),
                          label: const Text(
                            '+ Challenge',
                            style: TextStyle(
                              color: AppColors.accentDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_challenges.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'No active challenges yet. Start one to compete with your study group!',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ..._challenges.map((challenge) => _buildChallengeCard(challenge)),

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
