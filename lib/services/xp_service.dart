import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quiz_questions.dart';
import '../ml/question_attempt.dart';
import 'attempt_sync_service.dart';
import 'network_service.dart';
import 'supabase_service.dart';

/// Local-first service computing XP and player Level by replaying [QuestionAttempt]s
/// in chronological order, with SharedPreferences caching and remote Level synchronization.
class XpService {
  XpService._();

  static const String guestXpKey = 'guest_total_xp';
  static const String userXpPrefix = 'user_total_xp_';

  static String _keyForUser(String? userId) =>
      userId == null ? guestXpKey : '$userXpPrefix$userId';

  /// Resolves the question difficulty:
  /// 1 = Easy, 2 = Medium, 3 = Hard.
  static int resolveDifficulty(QuestionAttempt attempt) {
    if (attempt.difficulty != null &&
        attempt.difficulty! >= 1 &&
        attempt.difficulty! <= 3) {
      return attempt.difficulty!;
    }
    final bankDiff = QuizQuestionBank.lookupDifficulty(attempt.questionId);
    if (bankDiff != null) return bankDiff;

    final lowerId = attempt.questionId.toLowerCase();
    if (lowerId.contains('hard') || lowerId.contains('diff_3')) return 3;
    if (lowerId.contains('med') || lowerId.contains('diff_2')) return 2;
    if (lowerId.contains('easy') || lowerId.contains('diff_1')) return 1;

    return 1; // Default to Easy
  }

  /// Calculates XP earned for an individual question attempt:
  /// - Wrong = 0 at any difficulty
  /// - Easy (1) correct = 10 XP
  /// - Medium (2) correct = 15 XP
  /// - Hard (3) correct = 20 XP
  static int xpForAttempt(QuestionAttempt attempt) {
    if (!attempt.correct) return 0;
    final diff = resolveDifficulty(attempt);
    switch (diff) {
      case 3:
        return 20;
      case 2:
        return 15;
      case 1:
      default:
        return 10;
    }
  }

  /// Derives student level from total accumulated XP using the flat rule:
  /// Level = (totalXp < 0 ? 0 : totalXp) ~/ 100 + 1 (flat 100 XP per level, no cap).
  /// - 0..99    -> Level 1
  /// - 100..199 -> Level 2
  /// - 200..299 -> Level 3
  /// - 400..499 -> Level 5
  /// - 1000..1099 -> Level 11
  /// - 1100..1199 -> Level 12
  /// - and so on, with no cap.
  static int levelFor(int totalXp) {
    final sanitized = totalXp < 0 ? 0 : totalXp;
    return sanitized ~/ 100 + 1;
  }

  /// Groups attempts into individual quiz sessions.
  /// If attempts share an explicit [QuestionAttempt.quizId], groups by that ID;
  /// otherwise groups consecutive attempts within 5 minutes on the same subject.
  static List<List<QuestionAttempt>> groupAttemptsIntoQuizzes(
      List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return [];

    final sorted = List<QuestionAttempt>.from(attempts)
      ..sort((a, b) {
        final cmp = a.answeredAt.toUtc().compareTo(b.answeredAt.toUtc());
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

    final quizzes = <List<QuestionAttempt>>[];
    List<QuestionAttempt> current = [];

    for (final attempt in sorted) {
      if (current.isEmpty) {
        current.add(attempt);
        continue;
      }

      final prev = current.last;
      final sameQuizId = attempt.quizId != null &&
          prev.quizId != null &&
          attempt.quizId == prev.quizId;
      final diffQuizId = attempt.quizId != null &&
          prev.quizId != null &&
          attempt.quizId != prev.quizId;

      final timeDiff = attempt.answeredAt.difference(prev.answeredAt).abs();
      final sameSubject = attempt.subject == prev.subject;

      final shouldSplit = diffQuizId ||
          (!sameQuizId &&
              (timeDiff > const Duration(minutes: 5) || !sameSubject));

      if (shouldSplit) {
        quizzes.add(current);
        current = [attempt];
      } else {
        current.add(attempt);
      }
    }

    if (current.isNotEmpty) {
      quizzes.add(current);
    }

    return quizzes;
  }

  /// Pure replay: Computes total XP by replaying [question_attempts] in chronological order.
  /// - Easy correct = 10, Medium correct = 15, Hard correct = 20, Wrong = 0
  /// - Perfect quiz adds +20 bonus; imperfect quiz adds no bonus (+0)
  /// - Attempts that do not exist earn nothing (0 XP)
  static int computeTotalXp(List<QuestionAttempt> attempts) {
    if (attempts.isEmpty) return 0;

    final quizzes = groupAttemptsIntoQuizzes(attempts);
    var total = 0;

    for (final quiz in quizzes) {
      var allCorrect = quiz.isNotEmpty;
      for (final a in quiz) {
        total += xpForAttempt(a);
        if (!a.correct) {
          allCorrect = false;
        }
      }
      if (allCorrect) {
        total += 20; // Perfect quiz bonus
      }
    }

    return total;
  }

  /// Returns total XP from SharedPreferences cache, or recomputes from attempts
  /// if the cache is missing.
  static Future<int> getTotalXp({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.instance.currentUser?.id;
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForUser(effectiveUserId);

    final cached = prefs.getInt(key);
    if (cached != null) {
      return cached;
    }

    return await recomputeAndSave(userId: effectiveUserId);
  }

  /// Recomputes total XP from local (and remote if fresh install) attempts,
  /// writes result to SharedPreferences cache, and returns it.
  static Future<int> recomputeAndSave({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.instance.currentUser?.id;
    var attempts =
        await AttemptSyncService.logger.getAttempts(userId: effectiveUserId);

    if (attempts.isEmpty &&
        effectiveUserId != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = await SupabaseService.instance.client
            .from('question_attempts')
            .select()
            .eq('user_id', effectiveUserId)
            .order('answered_at', ascending: true);
        attempts = (rows as List)
            .map((r) =>
                QuestionAttempt.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        if (attempts.isNotEmpty) {
          await AttemptSyncService.logger.storage
              .saveUserAttempts(effectiveUserId, attempts);
        }
      } catch (e) {
        debugPrint('Error fetching remote attempts for XP replay: $e');
      }
    }

    final totalXp = computeTotalXp(attempts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyForUser(effectiveUserId), totalXp);

    return totalXp;
  }

  /// Hook invoked upon quiz completion.
  /// Recomputes local XP, caches it, and if signed in, syncs the new level
  /// to Supabase `profiles.level` if it changed.
  static Future<int> recordQuizFinish({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.instance.currentUser?.id;
    final total = await recomputeAndSave(userId: effectiveUserId);

    if (effectiveUserId != null) {
      final newLevel = levelFor(total);
      await syncLevelToRemote(effectiveUserId, newLevel);
    }

    return total;
  }

  /// Syncs derived level to `profiles.level` in Supabase when different.
  /// Wrapped in try/catch to ensure remote failures NEVER break quiz finish flow.
  static Future<void> syncLevelToRemote(String userId, int newLevel) async {
    if (!SupabaseService.instance.isInitialized) return;
    try {
      final profile = await SupabaseService.instance.getProfile(userId);
      final currentStoredLevel = profile?['level'] as int? ?? 1;
      if (currentStoredLevel != newLevel) {
        final displayName = profile?['display_name'] ?? 'Student';
        final initials = profile?['avatar_initials'] ?? 'SN';
        final subjects = profile?['subjects'] ?? ['Calculus', 'Biology'];
        await SupabaseService.instance.client.from('profiles').upsert({
          'id': userId,
          'display_name': displayName,
          'subjects': subjects,
          'level': newLevel,
          'avatar_initials': initials,
        });
        debugPrint(
            'Synced updated level $newLevel to Supabase profile for $userId');
      }
    } catch (e) {
      debugPrint('Level sync to remote profiles ignored on network error: $e');
    }
  }

  /// Migrates guest XP to registered user on registration.
  static Future<int> migrateGuestXp(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final total = await recomputeAndSave(userId: userId);
    await prefs.remove(guestXpKey);

    final newLevel = levelFor(total);
    await syncLevelToRemote(userId, newLevel);

    return total;
  }

  /// Formats XP with thousands separator (e.g. 1240 -> "1,240").
  static String formatXp(int xp) {
    return xp.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
