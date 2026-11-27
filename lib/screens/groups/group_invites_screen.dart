import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/group_invite.dart';
import '../../services/group_service.dart';

class GroupInvitesScreen extends StatefulWidget {
  const GroupInvitesScreen({super.key});

  @override
  State<GroupInvitesScreen> createState() => _GroupInvitesScreenState();
}

class _GroupInvitesScreenState extends State<GroupInvitesScreen> {
  List<GroupInvite> _invites = [];
  bool _isLoading = true;
  StreamSubscription<GroupInvite>? _inviteSubscription;

  @override
  void initState() {
    super.initState();
    _loadInvites();
    _inviteSubscription = GroupService.getInviteStream().listen((_) {
      if (mounted) {
        _loadInvites();
      }
    });
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInvites() async {
    final list = await GroupService.getPendingInvites();
    if (mounted) {
      setState(() {
        _invites = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResponse(GroupInvite invite, bool accept) async {
    await GroupService.respondToInvite(inviteId: invite.id, accept: accept);
    await _loadInvites();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Accepted invitation to join "${invite.groupName}"!'
                : 'Declined invitation.',
          ),
          backgroundColor: accept ? AppColors.success : AppColors.textSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
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
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Group Invites',
          style: TextStyle(
            color: context.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _invites.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: context.borderColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mail_outline_rounded,
                              size: 44,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pending invitations',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'When classmates or study groups invite you, they\'ll appear right here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _invites.length,
                    itemBuilder: (context, index) {
                      final invite = _invites[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.group_outlined,
                                      color: AppColors.accentDark,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invite.groupName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Invited by ${invite.inviterName}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: BorderSide(color: context.borderColor),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => _handleResponse(invite, false),
                                      child: Semantics(
                                        button: true,
                                        label: 'Decline invite to ${invite.groupName}',
                                        child: const Text(
                                          'Decline',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: AppColors.textDark,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => _handleResponse(invite, true),
                                      child: Semantics(
                                        button: true,
                                        label: 'Accept invite to ${invite.groupName}',
                                        child: const Text(
                                          'Accept',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
