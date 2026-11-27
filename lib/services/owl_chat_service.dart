import 'package:shared_preferences/shared_preferences.dart';
import '../ml/bkt_mastery.dart';
import 'mastery_service.dart';
import 'recommendation_engine.dart';
import 'streak_service.dart';
import 'supabase_service.dart';
import 'xp_service.dart';

/// Snapshot of student learning state used by Owl Chat to compute data-driven replies.
class OwlStudentData {
  final String? displayName;
  final List<RecommendationItem> recommendations;
  final List<TopicMastery> dueTopics;
  final int currentStreak;
  final int totalXp;
  final int currentLevel;

  const OwlStudentData({
    this.displayName,
    this.recommendations = const [],
    this.dueTopics = const [],
    this.currentStreak = 0,
    this.totalXp = 0,
    this.currentLevel = 1,
  });

  bool get hasData => recommendations.isNotEmpty;
}

/// Service providing data loading and deterministic intent resolution for Owl Chat.
class OwlChatService {
  OwlChatService._();

  /// Loads real student progress and recommendations from on-device/remote state.
  static Future<OwlStudentData> loadStudentData({String? userId}) async {
    final effectiveUserId = userId ?? SupabaseService.instance.currentUser?.id;

    String? displayName;
    final prefs = await SharedPreferences.getInstance();
    final localName = prefs.getString('user_display_name');
    if (localName != null && localName.trim().isNotEmpty) {
      displayName = localName.trim();
    } else if (effectiveUserId != null && SupabaseService.instance.isInitialized) {
      try {
        final profile = await SupabaseService.instance.getProfile(effectiveUserId);
        final profileName = profile?['display_name'] as String?;
        if (profileName != null && profileName.trim().isNotEmpty) {
          displayName = profileName.trim();
        }
      } catch (_) {}
    }

    final recs = await RecommendationEngine.getRankedRecommendations();
    final due = await MasteryService.tracker.getDueTopics(userId: effectiveUserId);
    final streakData = await StreakService.getCurrentStreakData();
    final totalXp = await XpService.getTotalXp(userId: effectiveUserId);
    final level = XpService.levelFor(totalXp);

    return OwlStudentData(
      displayName: displayName,
      recommendations: recs,
      dueTopics: due,
      currentStreak: streakData.currentStreak,
      totalXp: totalXp,
      currentLevel: level,
    );
  }

  /// Builds the greeting string from the student's real data.
  static String buildGreeting(OwlStudentData data) {
    final prefix = (data.displayName != null && data.displayName!.trim().isNotEmpty)
        ? 'Hi ${data.displayName!.trim()}!'
        : 'Hi!';

    if (!data.hasData) {
      return '$prefix Take the diagnostic quiz first and I\'ll know what to work on.';
    }

    final weakest = data.recommendations.first;
    final dueCount = data.dueTopics.length;
    final dueWord = dueCount == 1 ? 'review' : 'reviews';
    return '$prefix Your weakest topic is ${weakest.subject} — ${weakest.topic}, and you have $dueCount $dueWord due. Ask me what to study next.';
  }

  /// Computes a data-driven reply for [message] against deterministic keyword intents.
  static String computeReply(
    String message,
    OwlStudentData data, {
    DateTime? now,
  }) {
    final text = message.toLowerCase().trim();

    // Intent 1: What to study / weakest / focus / recommend
    final isStudyIntent = text.contains('what should i study') ||
        text.contains('what do i study') ||
        text.contains('weakest') ||
        text.contains('focus') ||
        text.contains('recommend');

    if (isStudyIntent) {
      if (!data.hasData) {
        return 'Take the diagnostic quiz first and I\'ll know what to work on.';
      }
      final topRec = data.recommendations.first;
      final reason = _formatReason(topRec);
      return 'Your weakest spot right now is ${topRec.subject} — ${topRec.topic} ($reason). Want to start there?';
    }

    // Intent 2: What's due / review
    final isDueIntent = text.contains('due') ||
        text.contains('review') ||
        text.contains('revise');

    if (isDueIntent) {
      if (!data.hasData) {
        return 'Take the diagnostic quiz first and I\'ll know what to work on.';
      }
      if (data.dueTopics.isEmpty) {
        return 'No reviews due — you\'re all caught up.';
      }
      final count = data.dueTopics.length;
      final countWord = count == 1 ? 'review' : 'reviews';
      final items = data.dueTopics
          .map((t) => '• ${t.subject} — ${t.topic} (${_formatOverdue(t, now: now)})')
          .join('\n');
      return 'You have $count $countWord due:\n$items';
    }

    // Intent 3: How am I doing / progress / level / streak
    final isProgressIntent = text.contains('how am i doing') ||
        text.contains('progress') ||
        text.contains('level') ||
        text.contains('streak') ||
        RegExp(r'\bxp\b').hasMatch(text);

    if (isProgressIntent) {
      if (!data.hasData) {
        return 'Take the diagnostic quiz first and I\'ll know what to work on.';
      }
      final weakest = data.recommendations.first;
      final pct = weakest.mastery != null ? '${(weakest.mastery! * 100).round()}%' : 'N/A';
      final streakStr = '${data.currentStreak} ${data.currentStreak == 1 ? 'day' : 'days'}';
      final dueCount = data.dueTopics.length;
      final dueStr = '$dueCount ${dueCount == 1 ? 'review' : 'reviews'} due';
      final formattedXp = XpService.formatXp(data.totalXp);
      return 'Here\'s how you\'re doing:\n'
          '• Weakest topic: ${weakest.subject} — ${weakest.topic} ($pct mastery)\n'
          '• Streak: $streakStr\n'
          '• Level: Level ${data.currentLevel} ($formattedXp XP)\n'
          '• Reviews due: $dueStr';
    }

    // Intent 4: Practice / quiz / problem
    final isPracticeIntent = text.contains('practice') ||
        text.contains('quiz') ||
        text.contains('problem') ||
        text.contains('test me');

    if (isPracticeIntent) {
      if (!data.hasData) {
        return 'Take the diagnostic quiz first and I\'ll know what to work on.';
      }
      final weakest = data.recommendations.first;
      return 'Your weakest topic is ${weakest.subject} — ${weakest.topic} — open it from the For You cards on Home or the Hub and take a quiz.';
    }

    // Intent 5: Honest fallback
    return 'I can help with what to study next, what\'s due for review, and how you\'re doing — try asking one of those.';
  }

  static String _formatReason(RecommendationItem rec) {
    if (rec.reason != null && rec.reason!.trim().isNotEmpty) {
      var text = rec.reason!.replaceAll(' • ', ', ').trim();
      if (text.startsWith('Mastery ')) {
        text = 'mastery ${text.substring(8)}';
      }
      text = text.replaceAll(', Overdue', ', overdue').replaceAll(', Due', ', due');
      return text;
    }
    final pct = ((rec.mastery ?? 0) * 100).round();
    return 'mastery $pct%';
  }

  static String _formatOverdue(TopicMastery topic, {DateTime? now}) {
    if (topic.nextReviewAt == null) return 'due today';
    final effectiveNow = now ?? DateTime.now();
    final dueUtc = topic.nextReviewAt!.toUtc();
    final nowUtc = effectiveNow.toUtc();
    final diffDays = nowUtc.difference(dueUtc).inDays;
    if (diffDays <= 0) {
      return 'due today';
    }
    final dayWord = diffDays == 1 ? 'day' : 'days';
    return 'overdue by $diffDays $dayWord';
  }
}
