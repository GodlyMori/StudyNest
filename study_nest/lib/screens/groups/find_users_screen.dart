import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user_profile_summary.dart';
import '../../services/group_service.dart';

class FindUsersScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const FindUsersScreen({
    super.key,
    this.groupId,
    this.groupName,
  });

  @override
  State<FindUsersScreen> createState() => _FindUsersScreenState();
}

class _FindUsersScreenState extends State<FindUsersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<UserProfileSummary> _users = [];
  final Set<String> _invitedUserIds = {};
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isLoading = true);
    final results = await GroupService.searchUsers('a'); // initial suggestions
    if (mounted) {
      setState(() {
        _users = results.isNotEmpty ? results : GroupService.defaultRegisteredUsers;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    setState(() {
      _lastQuery = q;
      _isLoading = true;
    });

    if (q.isEmpty) {
      final initial = await GroupService.searchUsers('a');
      if (mounted) {
        setState(() {
          _users = initial.isNotEmpty ? initial : GroupService.defaultRegisteredUsers;
          _isLoading = false;
        });
      }
      return;
    }

    final results = await GroupService.searchUsers(q);
    if (mounted) {
      setState(() {
        _users = results;
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  Future<void> _inviteUser(UserProfileSummary user) async {
    final gId = widget.groupId ?? 'group_calc_crew';
    final gName = widget.groupName ?? 'Calculus Crew';

    await GroupService.inviteUser(
      groupId: gId,
      groupName: gName,
      inviteeId: user.id,
      inviteeName: user.name,
    );

    if (mounted) {
      setState(() {
        _invitedUserIds.add(user.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invited ${user.name} to $gName!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
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
          'Find Users',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field (debounced ~300ms)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.white,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search by student name…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _clearSearch,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Results List or Empty State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _users.isEmpty && _lastQuery.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.border.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No students match your search',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'We couldn\'t find any registered student named "$_lastQuery".',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _clearSearch,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text('Clear search'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isInvited = _invitedUserIds.contains(user.id);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.accent.withOpacity(0.18),
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0] : 'U',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${user.subject} • ${user.level}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    isInvited
                                        ? OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: const BorderSide(color: AppColors.border),
                                            ),
                                            onPressed: null,
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, size: 14, color: AppColors.success),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Invited',
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.accent,
                                              foregroundColor: AppColors.textDark,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                            ),
                                            onPressed: () => _inviteUser(user),
                                            child: const Text(
                                              'Invite',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
