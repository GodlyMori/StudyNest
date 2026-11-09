import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/study_group.dart';
import '../models/group_member.dart';
import '../models/group_invite.dart';
import '../models/group_message.dart';
import '../models/user_profile_summary.dart';
import 'supabase_service.dart';

class GroupService {
  static const String _joinedGroupsKey = 'studynest_joined_groups';
  static const String _allGroupsKey = 'studynest_all_groups';
  static const String _invitesKey = 'studynest_group_invites';
  static const String _messagesPrefix = 'studynest_group_messages_';

  // Seed default groups
  static final List<StudyGroup> defaultGroups = [
    const StudyGroup(
      id: 'group_calc_crew',
      name: 'Calculus Crew',
      subject: 'Calculus',
      description: 'Daily calculus problem solving, exam prep, and peer review.',
      memberCount: 12,
      onlineCount: 3,
      isPublic: true,
      isJoined: true,
    ),
    const StudyGroup(
      id: 'group_bio_squad',
      name: 'Bio Study Squad',
      subject: 'Biology',
      description: 'Flashcard review, cell structure discussions, and biology notes.',
      memberCount: 8,
      onlineCount: 5,
      isPublic: true,
      isJoined: true,
    ),
    const StudyGroup(
      id: 'group_history_buffs',
      name: 'History Buffs',
      subject: 'History',
      description: 'WW2 timeline analysis and modern world history discussions.',
      memberCount: 15,
      onlineCount: 4,
      isPublic: true,
      isJoined: false,
    ),
    const StudyGroup(
      id: 'group_physics_pioneers',
      name: 'Physics Pioneers',
      subject: 'Physics',
      description: 'Newtonian mechanics, kinematics, and electromagnetism problem sets.',
      memberCount: 9,
      onlineCount: 2,
      isPublic: true,
      isJoined: false,
    ),
  ];

  // Seed default students for search (Figma frame 22: Maya Santos, Jonas Reyes, Sofia Cruz)
  static final List<UserProfileSummary> defaultRegisteredUsers = [
    const UserProfileSummary(
      id: 'user_maya',
      name: 'Maya Santos',
      subject: 'Calculus',
      level: 'Level 5',
    ),
    const UserProfileSummary(
      id: 'user_jonas',
      name: 'Jonas Reyes',
      subject: 'Biology',
      level: 'Level 4',
    ),
    const UserProfileSummary(
      id: 'user_sofia',
      name: 'Sofia Cruz',
      subject: 'History',
      level: 'Level 6',
    ),
  ];

  // In-memory mock/active streams for live updates
  static final Map<String, StreamController<GroupMessage>> _messageStreams = {};
  static final StreamController<GroupInvite> _inviteStreamController =
      StreamController<GroupInvite>.broadcast();

  // Test reset helper
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_joinedGroupsKey);
    await prefs.remove(_allGroupsKey);
    await prefs.remove(_invitesKey);
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_messagesPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Get groups joined by the user (My Groups)
  static Future<List<StudyGroup>> getMyGroups() async {
    final all = await _loadAllGroups();
    return all.where((g) => g.isJoined).toList();
  }

  /// Get public groups available to join (Discover)
  static Future<List<StudyGroup>> getDiscoverGroups() async {
    final all = await _loadAllGroups();
    return all.where((g) => !g.isJoined && g.isPublic).toList();
  }

  /// Join a group
  static Future<void> joinGroup(String groupId) async {
    final all = await _loadAllGroups();
    final index = all.indexWhere((g) => g.id == groupId);
    if (index >= 0) {
      all[index] = all[index].copyWith(
        isJoined: true,
        memberCount: all[index].memberCount + 1,
      );
      await _saveAllGroups(all);
    }

    // Attempt to persist to Supabase if connected
    if (SupabaseService.instance.isInitialized) {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        try {
          await SupabaseService.instance.client.from('group_members').insert({
            'group_id': groupId,
            'user_id': user.id,
            'role': 'member',
          });
        } catch (e) {
          debugPrint('Supabase joinGroup note: $e');
        }
      }
    }
  }

  /// Create a new study group
  static Future<StudyGroup> createGroup({
    required String name,
    required String subject,
    required String description,
  }) async {
    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    final currentUserId = SupabaseService.instance.currentUser?.id;

    final newGroup = StudyGroup(
      id: groupId,
      name: name,
      subject: subject,
      description: description,
      createdBy: currentUserId,
      memberCount: 1,
      onlineCount: 1,
      isPublic: true,
      isJoined: true, // Creator is immediately joined
    );

    final all = await _loadAllGroups();
    all.insert(0, newGroup);
    await _saveAllGroups(all);

    // Save to Supabase if available
    if (SupabaseService.instance.isInitialized && currentUserId != null) {
      try {
        await SupabaseService.instance.client.from('groups').insert({
          'id': groupId,
          'name': name,
          'subject': subject,
          'description': description,
          'created_by': currentUserId,
          'is_public': true,
        });

        await SupabaseService.instance.client.from('group_members').insert({
          'group_id': groupId,
          'user_id': currentUserId,
          'role': 'admin',
        });
      } catch (e) {
        debugPrint('Supabase createGroup note: $e');
      }
    }

    return newGroup;
  }

  /// Get Group details (members, shared materials, recent messages)
  static Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    final all = await _loadAllGroups();
    final group = all.firstWhere(
      (g) => g.id == groupId,
      orElse: () => StudyGroup(id: groupId, name: 'Study Group', subject: 'General'),
    );

    // Default members for display
    final members = [
      const GroupMember(
        id: 'm1',
        groupId: 'group_calc_crew',
        userId: 'u1',
        name: 'Maya Lin',
        role: 'Admin',
      ),
      const GroupMember(
        id: 'm2',
        groupId: 'group_calc_crew',
        userId: 'u2',
        name: 'Lucas Vance',
        role: 'Member',
      ),
      const GroupMember(
        id: 'm3',
        groupId: 'group_calc_crew',
        userId: 'u3',
        name: 'Sarah Connor',
        role: 'Member',
      ),
    ];

    final messages = await getGroupMessages(groupId);

    return {
      'group': group,
      'members': members,
      'messages': messages,
    };
  }

  /// Search registered users by partial name (e.g. "May" -> "Maya Santos")
  static Future<List<UserProfileSummary>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Try Supabase first if available
    if (SupabaseService.instance.isInitialized) {
      try {
        final res = await SupabaseService.instance.client
            .from('profiles')
            .select('id, display_name, subjects, level')
            .ilike('display_name', '%$q%')
            .limit(20);

        if (res.isNotEmpty) {
          return res
              .map((row) => UserProfileSummary.fromJson(row))
              .toList();
        }
      } catch (e) {
        debugPrint('Supabase searchUsers note: $e');
      }
    }

    // Default/fallback search against registered users list
    return defaultRegisteredUsers
        .where((u) => u.name.toLowerCase().contains(q))
        .toList();
  }

  /// Send an invite to a user for a group
  static Future<void> inviteUser({
    required String groupId,
    required String groupName,
    required String inviteeId,
    required String inviteeName,
  }) async {
    final inviteId = 'inv_${DateTime.now().millisecondsSinceEpoch}';
    final inviterId = SupabaseService.instance.currentUser?.id ?? 'current_user';
    final inviterName = SupabaseService.instance.currentUser?.email ?? 'You';

    final invite = GroupInvite(
      id: inviteId,
      groupId: groupId,
      groupName: groupName,
      inviterId: inviterId,
      inviterName: inviterName,
      inviteeId: inviteeId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_invitesKey);
    List<Map<String, dynamic>> list = [];
    if (data != null) {
      list = (jsonDecode(data) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    }
    list.add(invite.toJson());
    await prefs.setString(_invitesKey, jsonEncode(list));

    _inviteStreamController.add(invite);

    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.client.from('group_invites').insert({
          'id': inviteId,
          'group_id': groupId,
          'inviter_id': inviterId,
          'invitee_id': inviteeId,
          'status': 'pending',
        });
      } catch (e) {
        debugPrint('Supabase inviteUser note: $e');
      }
    }
  }

  /// Subscribe to Realtime invites for current user or broadcast
  static Stream<GroupInvite> getInviteStream({String? userId}) {
    if (SupabaseService.instance.isInitialized) {
      try {
        final targetId = userId ?? SupabaseService.instance.currentUser?.id;
        final channelName = targetId != null
            ? 'public:group_invites:$targetId'
            : 'public:group_invites:all';

        SupabaseService.instance.client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'group_invites',
              filter: targetId != null
                  ? PostgresChangeFilter(
                      type: PostgresChangeFilterType.eq,
                      column: 'invitee_id',
                      value: targetId,
                    )
                  : null,
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  final invite = GroupInvite.fromJson(newRecord);
                  _inviteStreamController.add(invite);
                } catch (e) {
                  debugPrint('Realtime invite payload parse note: $e');
                }
              },
            )
            .subscribe();
      } catch (e) {
        debugPrint('Realtime invite channel subscribe note: $e');
      }
    }

    return _inviteStreamController.stream;
  }

  /// Get pending invites for current user
  static Future<List<GroupInvite>> getPendingInvites() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_invitesKey);
    List<GroupInvite> result = [];

    if (data == null) {
      // Seed 2 default invites matching Figma frame 23 ("View Invites (2)")
      result = [
        GroupInvite(
          id: 'inv_default_1',
          groupId: 'group_history_buffs',
          groupName: 'History Buffs',
          inviterId: 'user_david',
          inviterName: 'David Kim',
          inviteeId: 'current_user',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        GroupInvite(
          id: 'inv_default_2',
          groupId: 'group_physics_pioneers',
          groupName: 'Physics Pioneers',
          inviterId: 'user_sarah',
          inviterName: 'Sarah Connor',
          inviteeId: 'current_user',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
      await prefs.setString(_invitesKey, jsonEncode(result.map((i) => i.toJson()).toList()));
      return result;
    }

    try {
      final list = jsonDecode(data) as List<dynamic>;
      result = list
          .map((e) => GroupInvite.fromJson(e as Map<String, dynamic>))
          .where((i) => i.status == 'pending')
          .toList();
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Respond to a group invitation (Accept / Decline)
  static Future<void> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_invitesKey);
    if (data == null) return;

    final list = (jsonDecode(data) as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final index = list.indexWhere((e) => e['id'] == inviteId);
    if (index >= 0) {
      final targetInvite = list[index];
      targetInvite['status'] = accept ? 'accepted' : 'declined';
      await prefs.setString(_invitesKey, jsonEncode(list));

      if (accept) {
        // Add member to group
        final groupId = targetInvite['group_id'] as String;
        await joinGroup(groupId);
      }
    }

    if (SupabaseService.instance.isInitialized) {
      try {
        await SupabaseService.instance.client.from('group_invites').update({
          'status': accept ? 'accepted' : 'declined',
        }).eq('id', inviteId);
      } catch (e) {
        debugPrint('Supabase respondToInvite note: $e');
      }
    }
  }

  /// Get messages for a study group
  static Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_messagesPrefix$groupId');

    if (data == null) {
      // Seed default messages matching Figma Frame 26
      final initial = [
        GroupMessage(
          id: 'msg_1',
          groupId: groupId,
          senderId: 'user_maya',
          senderName: 'Maya',
          content: 'Did anyone solve Q4 on the derivative of x²?',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          isMe: false,
          isOwl: false,
        ),
        GroupMessage(
          id: 'msg_2',
          groupId: groupId,
          senderId: 'owl_bot',
          senderName: 'Owl (Study Buddy)',
          content: 'Hint: Use the power rule! Bring the exponent down: d/dx(x²) = 2x.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
          isMe: false,
          isOwl: true,
        ),
        GroupMessage(
          id: 'msg_3',
          groupId: groupId,
          senderId: 'user_lucas',
          senderName: 'Lucas',
          content: 'Ah that makes sense now! Thanks Owl 🦉',
          createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
          isMe: false,
          isOwl: false,
        ),
      ];
      await prefs.setString(
        '$_messagesPrefix$groupId',
        jsonEncode(initial.map((m) => m.toJson()).toList()),
      );
      return initial;
    }

    try {
      final list = jsonDecode(data) as List<dynamic>;
      final myId = SupabaseService.instance.currentUser?.id;
      return list
          .map((m) => GroupMessage.fromJson(m as Map<String, dynamic>, currentUserId: myId))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Send message to a study group
  static Future<GroupMessage> sendMessage({
    required String groupId,
    required String content,
  }) async {
    final user = SupabaseService.instance.currentUser;
    final myId = user?.id ?? 'my_user_id';
    final myName = user?.email?.split('@').first ?? 'You';

    final message = GroupMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      groupId: groupId,
      senderId: myId,
      senderName: myName,
      content: content,
      createdAt: DateTime.now(),
      isMe: true,
      isOwl: false,
    );

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    final messages = await getGroupMessages(groupId);
    messages.add(message);
    await prefs.setString(
      '$_messagesPrefix$groupId',
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );

    // Notify local Realtime stream listeners
    if (_messageStreams.containsKey(groupId)) {
      _messageStreams[groupId]!.add(message);
    }

    // Persist to Supabase if connected
    if (SupabaseService.instance.isInitialized && user != null) {
      try {
        await SupabaseService.instance.client.from('group_messages').insert({
          'group_id': groupId,
          'sender_id': user.id,
          'content': content,
        });
      } catch (e) {
        debugPrint('Supabase sendMessage note: $e');
      }
    }

    return message;
  }

  /// Subscribe to Realtime messages for a group
  static Stream<GroupMessage> getMessageStream(String groupId) {
    if (!_messageStreams.containsKey(groupId)) {
      _messageStreams[groupId] = StreamController<GroupMessage>.broadcast();
    }

    // Connect to Supabase Realtime Channel if available
    if (SupabaseService.instance.isInitialized) {
      try {
        SupabaseService.instance.client
            .channel('group_messages_$groupId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'group_messages',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'group_id',
                value: groupId,
              ),
              callback: (payload) {
                final newRecord = payload.newRecord;
                final myId = SupabaseService.instance.currentUser?.id;
                final msg = GroupMessage.fromJson(newRecord, currentUserId: myId);
                _messageStreams[groupId]?.add(msg);
              },
            )
            .subscribe();
      } catch (e) {
        debugPrint('Realtime channel subscribe note: $e');
      }
    }

    return _messageStreams[groupId]!.stream;
  }

  // Helper internal storage
  static Future<List<StudyGroup>> _loadAllGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_allGroupsKey);
    if (data == null) {
      await _saveAllGroups(defaultGroups);
      return List<StudyGroup>.from(defaultGroups);
    }
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((g) => StudyGroup.fromJson(g as Map<String, dynamic>)).toList();
    } catch (_) {
      return List<StudyGroup>.from(defaultGroups);
    }
  }

  static Future<void> _saveAllGroups(List<StudyGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(groups.map((g) => g.toJson()).toList());
    await prefs.setString(_allGroupsKey, data);
  }
}
