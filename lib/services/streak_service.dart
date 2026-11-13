import 'package:shared_preferences/shared_preferences.dart';
import '../ml/question_attempt.dart';
import 'attempt_sync_service.dart';
import 'guest_score_service.dart';
import 'network_service.dart';
import 'supabase_service.dart';

/// Data structure encapsulating current study streak, freeze availability,
/// and daily quiz goal progress.
class StreakData {
  final int currentStreak;
  final int freezesRemaining; // 0 or 1
  final bool canUseFreeze;
  final String? lastFreezeUsedDate;
  final List<String> frozenDates;
  final int todayQuizzesCompleted;
  final int dailyGoal;

  const StreakData({
    required this.currentStreak,
    required this.freezesRemaining,
    required this.canUseFreeze,
    required this.lastFreezeUsedDate,
    required this.frozenDates,
    required this.todayQuizzesCompleted,
    required this.dailyGoal,
  });

  bool get isGoalMet => todayQuizzesCompleted >= dailyGoal;
}

/// Service managing real streak computation, streak freeze allowance (1/week),
/// and daily quiz goals (stored durably in SharedPreferences).
class StreakService {
  static const String keyFrozenDates = 'study_streak_frozen_dates';
  static const String keyLastFreezeUsed = 'study_streak_last_freeze_used';
  static const String keyDailyGoal = 'settings_daily_quiz_goal';
  static const int defaultDailyGoal = 1;

  /// Formats [date] to 'YYYY-MM-DD' in local time.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns the Monday start of the calendar week for [date].
  static DateTime startOfCalendarWeek(DateTime date) {
    final localMidnight = DateTime(date.year, date.month, date.day);
    return localMidnight.subtract(Duration(days: date.weekday - 1));
  }

  /// Checks whether two dates fall within the same calendar week (Monday–Sunday).
  static bool isSameCalendarWeek(DateTime a, DateTime b) {
    final startA = startOfCalendarWeek(a);
    final startB = startOfCalendarWeek(b);
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }

  /// Pure computation of consecutive active streak days from real dates.
  static int calculateStreak({
    required Set<String> activeDates,
    required Set<String> frozenDates,
    required DateTime today,
  }) {
    final todayStr = formatDate(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = formatDate(yesterday);

    final hasToday = activeDates.contains(todayStr);
    final hasYesterday = activeDates.contains(yesterdayStr) ||
        frozenDates.contains(yesterdayStr);

    // If no activity today and yesterday was missed with no freeze, streak is broken.
    if (!hasToday && !hasYesterday) {
      return 0;
    }

    // Start checking backward: from today if active today, otherwise from yesterday.
    var checkDate = hasToday ? today : yesterday;
    var streak = 0;

    while (true) {
      final dateStr = formatDate(checkDate);
      final isActive = activeDates.contains(dateStr);
      final isFrozen = frozenDates.contains(dateStr);

      if (isActive || isFrozen) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Loads the persisted daily goal (default: 1 quiz).
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyDailyGoal) ?? defaultDailyGoal;
  }

  /// Persists a new daily goal.
  static Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyDailyGoal, goal < 1 ? 1 : goal);
  }

  /// Loads list of dates protected by streak freeze.
  static Future<Set<String>> getFrozenDates() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(keyFrozenDates) ?? [];
    return list.toSet();
  }

  /// Loads timestamp string of last spent freeze.
  static Future<DateTime?> getLastFreezeUsedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyLastFreezeUsed);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Computes full [StreakData] for the given student activity records.
  static Future<StreakData> computeStreakData({
    required List<DateTime> completedQuizTimestamps,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final todayStr = formatDate(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = formatDate(yesterday);

    final activeDates = completedQuizTimestamps.map(formatDate).toSet();
    final frozenDates = await getFrozenDates();
    final lastFreezeDate = await getLastFreezeUsedDate();
    final dailyGoal = await getDailyGoal();

    // Today's completed quizzes
    final todayQuizzesCompleted = completedQuizTimestamps
        .where((ts) => formatDate(ts) == todayStr)
        .length;

    // Check weekly freeze allowance (1 freeze per calendar week)
    final freezeUsedThisWeek = lastFreezeDate != null &&
        isSameCalendarWeek(lastFreezeDate, today);
    final freezesRemaining = freezeUsedThisWeek ? 0 : 1;

    // Streak can use freeze if:
    // 1. Freeze is available this week.
    // 2. Yesterday was missed and is not yet frozen.
    // 3. User had activity before yesterday (so spending a freeze protects a real streak).
    final yesterdayMissed = !activeDates.contains(yesterdayStr) &&
        !frozenDates.contains(yesterdayStr);

    // Rule: Activity must exist before yesterday to protect an actual streak
    final hasActivityBeforeYesterday =
        activeDates.any((d) => d.compareTo(yesterdayStr) < 0);

    final canUseFreeze =
        freezesRemaining > 0 && yesterdayMissed && hasActivityBeforeYesterday;

    final currentStreak = calculateStreak(
      activeDates: activeDates,
      frozenDates: frozenDates,
      today: today,
    );

    return StreakData(
      currentStreak: currentStreak,
      freezesRemaining: freezesRemaining,
      canUseFreeze: canUseFreeze,
      lastFreezeUsedDate: lastFreezeDate != null ? formatDate(lastFreezeDate) : null,
      frozenDates: frozenDates.toList()..sort(),
      todayQuizzesCompleted: todayQuizzesCompleted,
      dailyGoal: dailyGoal,
    );
  }

  /// Resolves active dates from local storage (guest scores, user scores, and attempts).
  static Future<Set<String>> getActiveDatesFromStorage() async {
    final user = SupabaseService.instance.currentUser;
    final scores = await GuestScoreService.getScoresForUser(userId: user?.id);
    var attempts = await AttemptSyncService.logger.getAttempts(userId: user?.id);
    if (attempts.isEmpty &&
        user != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = await SupabaseService.instance.client
            .from('question_attempts')
            .select()
            .eq('user_id', user.id)
            .order('answered_at', ascending: true);
        attempts = (rows as List)
            .map((r) => QuestionAttempt.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (_) {}
    }

    final dates = <String>{};
    for (final s in scores) {
      final raw = s['created_at'] ?? s['date'];
      if (raw != null) {
        try {
          dates.add(formatDate(DateTime.parse(raw.toString()).toLocal()));
        } catch (_) {}
      }
    }
    for (final a in attempts) {
      dates.add(formatDate(a.answeredAt.toLocal()));
    }
    return dates;
  }

  /// Convenience method resolving all real activity from storage to compute [StreakData].
  static Future<StreakData> getCurrentStreakData([DateTime? now]) async {
    final user = SupabaseService.instance.currentUser;
    final scores = await GuestScoreService.getScoresForUser(userId: user?.id);
    var attempts = await AttemptSyncService.logger.getAttempts(userId: user?.id);
    if (attempts.isEmpty &&
        user != null &&
        SupabaseService.instance.isInitialized &&
        await NetworkService.isOnline()) {
      try {
        final rows = await SupabaseService.instance.client
            .from('question_attempts')
            .select()
            .eq('user_id', user.id)
            .order('answered_at', ascending: true);
        attempts = (rows as List)
            .map((r) => QuestionAttempt.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
      } catch (_) {}
    }

    final timestamps = <DateTime>[];
    for (final s in scores) {
      final raw = s['created_at'] ?? s['date'];
      if (raw != null) {
        try {
          timestamps.add(DateTime.parse(raw.toString()).toLocal());
        } catch (_) {}
      }
    }
    for (final a in attempts) {
      timestamps.add(a.answeredAt.toLocal());
    }

    return computeStreakData(completedQuizTimestamps: timestamps, now: now);
  }

  /// Spends a weekly streak freeze for yesterday (or the specified [targetDate]).
  /// Returns `true` if freeze was successfully spent, `false` if not allowed.
  static Future<bool> spendStreakFreeze({
    Set<String>? activeDates,
    List<DateTime>? completedQuizTimestamps,
    DateTime? targetDate,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final lastFreezeDate = await getLastFreezeUsedDate();

    // Check weekly allowance
    if (lastFreezeDate != null && isSameCalendarWeek(lastFreezeDate, today)) {
      return false; // Already used this week
    }

    final dateToFreeze = targetDate ?? today.subtract(const Duration(days: 1));
    final freezeDateStr = formatDate(dateToFreeze);

    // Enforce freeze guard: must have activity before the date being frozen
    final Set<String> dates;
    if (activeDates != null) {
      dates = activeDates;
    } else if (completedQuizTimestamps != null) {
      dates = completedQuizTimestamps.map(formatDate).toSet();
    } else {
      dates = await getActiveDatesFromStorage();
    }

    final hasActivityBefore = dates.any((d) => d.compareTo(freezeDateStr) < 0);
    if (!hasActivityBefore) {
      return false; // Cannot spend freeze without prior activity to protect
    }

    final prefs = await SharedPreferences.getInstance();
    final existingFrozen = prefs.getStringList(keyFrozenDates) ?? [];
    if (!existingFrozen.contains(freezeDateStr)) {
      existingFrozen.add(freezeDateStr);
      await prefs.setStringList(keyFrozenDates, existingFrozen);
    }

    await prefs.setString(keyLastFreezeUsed, today.toIso8601String());
    return true;
  }
}
