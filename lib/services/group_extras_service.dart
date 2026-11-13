import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_challenge.dart';
import '../models/group_member.dart';
import 'guest_score_service.dart';
import 'network_service.dart';
import 'supabase_service.dart';

class GroupLeaderboardEntry {
  final String userId;
  final String name;
  final String role;
  final double? averageScore;
  final int quizCount;

  const GroupLeaderboardEntry({
    required this.userId,
    required this.name,
    required this.role,
    this.averageScore,
    this.quizCount = 0,
  });

  bool get hasScores => quizCount > 0 && averageScore != null;
}

class GroupExtrasService {
  GroupExtrasService._();

  static const String _challengesPrefix = 'group_challenges_';
  static const String _memberScoresPrefix = 'member_quiz_scores_';

  /// Builds a real leaderboard for the group members.
  /// Queries real quiz scores from Supabase `quiz_scores` and local stores.
  /// Members with no scores will have `hasScores == false` (honest "No quizzes yet").
  static Future<List<GroupLeaderboardEntry>> getGroupLeaderboard(
    String groupId,
    List<GroupMember> members,
  ) async {
    final entries = <GroupLeaderboardEntry>[];
    final currentUid = SupabaseService.instance.currentUser?.id;

    for (final member in members) {
      final scores = await _getScoresForMember(member.userId, currentUid);

      if (scores.isEmpty) {
        entries.add(
          GroupLeaderboardEntry(
            userId: member.userId,
            name: member.name,
            role: member.role,
            averageScore: null,
            quizCount: 0,
          ),
        );
      } else {
        final totalScore = scores.fold<int>(0, (sum, s) => sum + s);
        final avg = totalScore / scores.length;
        entries.add(
          GroupLeaderboardEntry(
            userId: member.userId,
            name: member.name,
            role: member.role,
            averageScore: avg,
            quizCount: scores.length,
          ),
        );
      }
    }

    // Sort: Members with scores ranked descending by averageScore, then by quizCount.
    // Members without scores placed at the bottom.
    entries.sort((a, b) {
      if (a.hasScores && b.hasScores) {
        final scoreCmp = b.averageScore!.compareTo(a.averageScore!);
        if (scoreCmp != 0) return scoreCmp;
        return b.quizCount.compareTo(a.quizCount);
      }
      if (a.hasScores && !b.hasScores) return -1;
      if (!a.hasScores && b.hasScores) return 1;
      return a.name.compareTo(b.name);
    });

    return entries;
  }

  static Future<List<int>> _getScoresForMember(
    String memberUserId,
    String? currentUid,
  ) async {
    final scores = <int>[];

    // 1. Try Supabase if initialized and online
    if (SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final response = await SupabaseService.instance.client
            .from('quiz_scores')
            .select('score')
            .eq('user_id', memberUserId);

        final resList = response as List;
        if (resList.isNotEmpty) {
          for (final row in resList) {
            final s = (row as Map)['score'];
            if (s is num) scores.add(s.toInt());
          }
          if (scores.isNotEmpty) return scores;
        }
      } catch (e) {
        debugPrint('Supabase quiz_scores fetch error for $memberUserId: $e');
      }
    }

    // 2. Check local member store
    final prefs = await SharedPreferences.getInstance();
    final memberRaw = prefs.getString('$_memberScoresPrefix$memberUserId');
    if (memberRaw != null && memberRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(memberRaw) as List;
        for (final item in decoded) {
          if (item is num) scores.add(item.toInt());
          if (item is Map && item['score'] is num) {
            scores.add((item['score'] as num).toInt());
          }
        }
      } catch (e) {
        debugPrint('Error decoding local member scores: $e');
      }
    }

    // 3. If member is current user (or guest 'u1'/'current_user'), include current user / guest scores
    final isCurrentUser = memberUserId == currentUid ||
        (currentUid == null && (memberUserId == 'current_user' || memberUserId == 'u1'));
    if (isCurrentUser) {
      final userScores = await GuestScoreService.getScoresForUser(userId: currentUid);
      for (final s in userScores) {
        if (s['score'] is num) {
          scores.add((s['score'] as num).toInt());
        }
      }
    }

    return scores;
  }

  /// Records a score for a specific member / user in local store and Supabase.
  static Future<void> recordMemberScore({
    required String userId,
    required String subject,
    required int score,
    String grade = 'A',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_memberScoresPrefix$userId';
    final raw = prefs.getString(key);
    var existing = <int>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        existing = decoded.map((e) => (e as num).toInt()).toList();
      } catch (_) {}
    }
    existing.add(score);
    await prefs.setString(key, jsonEncode(existing));

    if (SupabaseService.instance.isInitialized &&
        SupabaseService.instance.currentUser?.id == userId &&
        await NetworkService.isOnline()) {
      try {
        await SupabaseService.instance.client.from('quiz_scores').insert({
          'user_id': userId,
          'subject': subject,
          'score': score,
          'grade': grade,
        });
      } catch (e) {
        debugPrint('Supabase recordMemberScore error: $e');
      }
    }
  }

  // ---------------------------------------------------------
  // Shared Quiz Challenges
  // ---------------------------------------------------------

  /// Loads all challenges for a study group.
  static Future<List<GroupChallenge>> getChallenges(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_challengesPrefix$groupId';
    final raw = prefs.getString(key);

    var localChallenges = <GroupChallenge>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        localChallenges = decoded
            .map((item) => GroupChallenge.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } catch (e) {
        debugPrint('Error decoding local challenges: $e');
      }
    }

    // Try syncing from Supabase
    if (SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final cRes = await SupabaseService.instance.client
            .from('group_challenges')
            .select()
            .eq('group_id', groupId)
            .order('created_at', ascending: false);

        final remoteChallenges = <GroupChallenge>[];
        for (final row in cRes as List) {
          final cMap = Map<String, dynamic>.from(row as Map);
          final cId = cMap['id'] as String;

          // Load attempts for this challenge
          final aRes = await SupabaseService.instance.client
              .from('challenge_attempts')
              .select()
              .eq('challenge_id', cId)
              .order('score', ascending: false);

          final attemptsList = aRes as List;
          cMap['attempts'] = attemptsList;
          remoteChallenges.add(GroupChallenge.fromJson(cMap));
        }

        // Merge: remote wins on conflict
        final map = {for (final c in localChallenges) c.id: c};
        for (final rc in remoteChallenges) {
          map[rc.id] = rc;
        }
        final merged = map.values.toList();
        await _saveChallengesLocally(groupId, merged);
        return merged;
      } catch (e) {
        debugPrint('Supabase challenges load failed (using local): $e');
      }
    }

    return localChallenges;
  }

  /// Creates a new challenge in the study group.
  static Future<GroupChallenge> createChallenge({
    required String groupId,
    required String subject,
    required int questionCount,
    String? creatorId,
    String? creatorName,
  }) async {
    final now = DateTime.now().toUtc();
    final uid = creatorId ??
        SupabaseService.instance.currentUser?.id ??
        'current_user';
    final name = creatorName ??
        SupabaseService.instance.currentUser?.userMetadata?['display_name'] ??
        'You';

    final challenge = GroupChallenge(
      id: 'challenge_${groupId}_${now.millisecondsSinceEpoch}',
      groupId: groupId,
      creatorId: uid,
      creatorName: name,
      subject: subject,
      questionCount: questionCount,
      createdAt: now,
      attempts: const [],
    );

    final all = await getChallenges(groupId);
    all.insert(0, challenge);
    await _saveChallengesLocally(groupId, all);

    if (SupabaseService.instance.isInitialized &&
        SupabaseService.instance.currentUser != null &&
        await NetworkService.isOnline()) {
      try {
        await SupabaseService.instance.client.from('group_challenges').insert({
          'id': challenge.id,
          'group_id': challenge.groupId,
          'creator_id': challenge.creatorId,
          'creator_name': challenge.creatorName,
          'subject': challenge.subject,
          'question_count': challenge.questionCount,
          'created_at': challenge.createdAt.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase createChallenge error: $e');
      }
    }

    return challenge;
  }

  /// Records an attempt at a challenge and ranks it on the challenge board.
  static Future<ChallengeAttempt> recordChallengeAttempt({
    required String groupId,
    required String challengeId,
    required int score,
    required int total,
    String? userId,
    String? userName,
    DateTime? completedAt,
  }) async {
    final now = (completedAt ?? DateTime.now()).toUtc();
    final uid = userId ??
        SupabaseService.instance.currentUser?.id ??
        'current_user';
    final name = userName ??
        SupabaseService.instance.currentUser?.userMetadata?['display_name'] ??
        'You';
    final percentage = total > 0 ? ((score / total) * 100).round() : 0;

    final attempt = ChallengeAttempt(
      id: 'attempt_${challengeId}_${now.millisecondsSinceEpoch}',
      challengeId: challengeId,
      userId: uid,
      userName: name,
      score: score,
      total: total,
      percentage: percentage,
      completedAt: now,
    );

    final all = await getChallenges(groupId);
    final index = all.indexWhere((c) => c.id == challengeId);
    if (index != -1) {
      final currentChallenge = all[index];
      final updatedAttempts = List<ChallengeAttempt>.from(currentChallenge.attempts)
        ..add(attempt);

      // Rank attempts descending by percentage/score
      updatedAttempts.sort((a, b) => b.percentage.compareTo(a.percentage));

      all[index] = currentChallenge.copyWith(attempts: updatedAttempts);
      await _saveChallengesLocally(groupId, all);
    }

    // Also record score for the member's personal score history
    if (index != -1) {
      await recordMemberScore(
        userId: uid,
        subject: all[index].subject,
        score: percentage,
      );
    }

    if (SupabaseService.instance.isInitialized &&
        SupabaseService.instance.currentUser != null &&
        await NetworkService.isOnline()) {
      try {
        await SupabaseService.instance.client.from('challenge_attempts').insert({
          'id': attempt.id,
          'challenge_id': attempt.challengeId,
          'user_id': attempt.userId,
          'user_name': attempt.userName,
          'score': attempt.score,
          'total': attempt.total,
          'percentage': attempt.percentage,
          'completed_at': attempt.completedAt.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Supabase recordChallengeAttempt error: $e');
      }
    }

    return attempt;
  }

  static Future<void> _saveChallengesLocally(
    String groupId,
    List<GroupChallenge> challenges,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_challengesPrefix$groupId';
    final raw = jsonEncode(challenges.map((c) => c.toJson()).toList());
    await prefs.setString(key, raw);
  }

  @visibleForTesting
  static Future<void> clearAll(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_challengesPrefix$groupId');
  }
}
