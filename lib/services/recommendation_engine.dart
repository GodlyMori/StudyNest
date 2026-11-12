import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ml/bkt_mastery.dart';
import '../ml/question_attempt.dart';
import 'attempt_sync_service.dart';
import 'mastery_service.dart';
import 'supabase_service.dart';

class RecommendationItem {
  final String topic;
  final String subject;
  final String priority; // 'High priority', 'Medium', 'Low'
  final String timeEstimate; // '8 min', '6 min', etc.
  final int wrongCount;
  final DateTime lastAttempt;
  final double? mastery;
  final String? reason;

  const RecommendationItem({
    required this.topic,
    required this.subject,
    required this.priority,
    required this.timeEstimate,
    required this.wrongCount,
    required this.lastAttempt,
    this.mastery,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'subject': subject,
        'priority': priority,
        'timeEstimate': timeEstimate,
        'wrongCount': wrongCount,
        'lastAttempt': lastAttempt.toIso8601String(),
        if (mastery != null) 'mastery': mastery,
        if (reason != null) 'reason': reason,
      };

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      RecommendationItem(
        topic: json['topic'] as String,
        subject: json['subject'] as String,
        priority: json['priority'] as String,
        timeEstimate: json['timeEstimate'] as String,
        wrongCount: json['wrongCount'] as int? ?? 0,
        lastAttempt: json['lastAttempt'] != null
            ? DateTime.parse(json['lastAttempt'] as String)
            : DateTime.now(),
        mastery: (json['mastery'] as num?)?.toDouble(),
        reason: json['reason'] as String?,
      );
}

class RecommendationEngine {
  static const String _storageKey = 'recommendation_topic_stats';

  /// Simple flag to switch between V2 BKT mastery ranking (`true`)
  /// and the V1 rules-engine fallback (`false`).
  static bool useBktMastery = true;

  /// Maps a BKT mastery probability `[0.0, 1.0]` to a Hub priority label:
  /// `< 0.4` -> `High priority`, `0.4–0.7` -> `Medium`, `> 0.7` -> `Low`.
  static String priorityForMastery(double mastery) {
    if (mastery < 0.4) return 'High priority';
    if (mastery <= 0.7) return 'Medium';
    return 'Low';
  }

  // Fallback defaults if user has not yet taken any quizzes
  static final List<RecommendationItem> defaultRecommendations = [
    RecommendationItem(
      topic: 'Derivatives',
      subject: 'Calculus',
      priority: 'High priority',
      timeEstimate: '8 min',
      wrongCount: 0,
      lastAttempt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    RecommendationItem(
      topic: 'Forces & Laws',
      subject: 'Physics',
      priority: 'Medium',
      timeEstimate: '6 min',
      wrongCount: 0,
      lastAttempt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    RecommendationItem(
      topic: 'WW2 Causes',
      subject: 'History',
      priority: 'Low',
      timeEstimate: '10 min',
      wrongCount: 0,
      lastAttempt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    RecommendationItem(
      topic: 'Cell Structure',
      subject: 'Biology',
      priority: 'Low',
      timeEstimate: '7 min',
      wrongCount: 0,
      lastAttempt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  /// Record question outcome for a topic
  static Future<void> recordAnswer({
    required String subject,
    required String topic,
    required bool isCorrect,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await _loadRawStats(prefs);

    final key = '$subject::$topic';
    final current = stats[key] ?? {
      'subject': subject,
      'topic': topic,
      'wrongCount': 0,
      'totalCount': 0,
      'lastAttempt': DateTime.now().toIso8601String(),
    };

    current['totalCount'] = (current['totalCount'] as int) + 1;
    if (!isCorrect) {
      current['wrongCount'] = (current['wrongCount'] as int) + 1;
    }
    current['lastAttempt'] = DateTime.now().toIso8601String();

    stats[key] = current;
    await prefs.setString(_storageKey, jsonEncode(stats));
  }

  /// Ranks topics for the ML Recommendations Hub.
  ///
  /// When [useBktMastery] is `true` and BKT mastery data is available, ranks by
  /// lowest mastery first. Falls back to the V1 rules engine when
  /// [useBktMastery] is `false` or when no BKT mastery data exists yet.
  static Future<List<RecommendationItem>> getRankedRecommendations() async {
    if (useBktMastery) {
      final masteries = await MasteryService.loadOrRebuildMasteries();
      if (masteries.isNotEmpty) {
        return rankByBktMastery(masteries);
      }
    }
    return _getRulesRankedRecommendations();
  }

  static String buildMasteryReason(
    double mastery,
    List<QuestionAttempt> topicAttempts, {
    int recentWindow = 5,
  }) {
    final pct = (mastery.clamp(0.0, 1.0) * 100).round();
    if (topicAttempts.isEmpty) {
      return 'Mastery $pct%, no recent attempts yet';
    }
    final sorted = List<QuestionAttempt>.from(topicAttempts)
      ..sort((a, b) => a.answeredAt.compareTo(b.answeredAt));
    final recent = sorted.length <= recentWindow
        ? sorted
        : sorted.sublist(sorted.length - recentWindow);
    final missed = recent.where((a) => !a.correct).length;
    final total = recent.length;
    final qWord = total == 1 ? 'question' : 'questions';
    if (missed > 0) {
      return 'Mastery $pct%, missed $missed of your last $total $qWord';
    }
    return 'Mastery $pct%, $total of your last $total $qWord correct';
  }

  /// Mastery similarity band (5%) within which overdue reviews rank ahead.
  static const double masterySimilarityBand = 0.05;

  @visibleForTesting
  static Future<List<RecommendationItem>> rankByBktMastery(
    Map<String, TopicMastery> masteries, {
    String? userId,
    DateTime? now,
  }) async {
    final currentUserId = userId ?? SupabaseService.instance.currentUser?.id;
    final refNow = (now ?? DateTime.now()).toUtc();
    final attempts = await AttemptSyncService.logger.getAttempts(
      userId: currentUserId,
    );
    final wrongCounts = <String, int>{};
    final attemptsByTopic = <String, List<QuestionAttempt>>{};
    for (final a in attempts) {
      final key = TopicMastery.topicKey(a.subject, a.topic);
      attemptsByTopic.putIfAbsent(key, () => []).add(a);
      if (!a.correct) {
        wrongCounts[key] = (wrongCounts[key] ?? 0) + 1;
      }
    }

    final sorted = masteries.values.toList()
      ..sort((a, b) {
        // Primary: lowest mastery band first (5% buckets for transitivity).
        final bandA = (a.mastery / masterySimilarityBand).floor();
        final bandB = (b.mastery / masterySimilarityBand).floor();
        if (bandA != bandB) return bandA.compareTo(bandB);

        // Secondary within similar mastery: most overdue review first.
        final dueCmp = _compareOverdue(a.nextReviewAt, b.nextReviewAt, refNow);
        if (dueCmp != 0) return dueCmp;

        // Tertiary: exact lowest mastery, then oldest update.
        final masteryCmp = a.mastery.compareTo(b.mastery);
        if (masteryCmp != 0) return masteryCmp;
        return a.updatedAt.compareTo(b.updatedAt);
      });

    return sorted.map((m) {
      final key = TopicMastery.topicKey(m.subject, m.topic);
      final topicAttempts = attemptsByTopic[key] ?? const [];
      return RecommendationItem(
        topic: m.topic,
        subject: m.subject,
        priority: priorityForMastery(m.mastery),
        timeEstimate: _estimateTime(m.topic),
        wrongCount: wrongCounts[key] ?? 0,
        lastAttempt: m.updatedAt,
        mastery: m.mastery,
        reason: buildMasteryReason(m.mastery, topicAttempts),
      );
    }).toList();
  }

  /// Compares two `nextReviewAt` timestamps so the most overdue comes first.
  /// Scheduled reviews (especially overdue ones) rank ahead of unscheduled (`null`).
  static int _compareOverdue(DateTime? a, DateTime? b, DateTime now) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    // Earlier nextReviewAt = more overdue (or due sooner) -> comes first.
    return a.toUtc().compareTo(b.toUtc());
  }

  /// V1 Rules Engine fallback:
  /// 1. Weakest topic first (highest wrongCount descending).
  /// 2. Longest since last attempt ascending.
  static Future<List<RecommendationItem>> _getRulesRankedRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = await _loadRawStats(prefs);

    if (stats.isEmpty) {
      return defaultRecommendations;
    }

    final List<Map<String, dynamic>> list = stats.values.toList();

    // Sort: primary = wrongCount descending, secondary = lastAttempt ascending (oldest first)
    list.sort((a, b) {
      final int wrongA = a['wrongCount'] as int? ?? 0;
      final int wrongB = b['wrongCount'] as int? ?? 0;
      if (wrongA != wrongB) {
        return wrongB.compareTo(wrongA); // Weakest first
      }
      final DateTime dateA = DateTime.tryParse(a['lastAttempt'] as String? ?? '') ??
          DateTime.now();
      final DateTime dateB = DateTime.tryParse(b['lastAttempt'] as String? ?? '') ??
          DateTime.now();
      return dateA.compareTo(dateB); // Oldest attempt first
    });

    final List<RecommendationItem> ranked = [];
    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      final wrong = item['wrongCount'] as int? ?? 0;
      final String priority;
      if (wrong >= 2 || (i == 0 && wrong > 0)) {
        priority = 'High priority';
      } else if (wrong == 1 || i == 1) {
        priority = 'Medium';
      } else {
        priority = 'Low';
      }

      final date = DateTime.tryParse(item['lastAttempt'] as String? ?? '') ??
          DateTime.now();
      final subject = item['subject'] as String;
      final topic = item['topic'] as String;

      ranked.add(RecommendationItem(
        topic: topic,
        subject: subject,
        priority: priority,
        timeEstimate: _estimateTime(topic),
        wrongCount: wrong,
        lastAttempt: date,
      ));
    }

    return ranked;
  }

  static String _estimateTime(String topic) {
    final lower = topic.toLowerCase();
    if (lower.contains('derivative') || lower.contains('integral')) return '8 min';
    if (lower.contains('force') || lower.contains('mechanic')) return '6 min';
    if (lower.contains('world') || lower.contains('war')) return '10 min';
    if (lower.contains('cell') || lower.contains('genetics')) return '7 min';
    return '5 min';
  }

  static Future<Map<String, Map<String, dynamic>>> _loadRawStats(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final Map<String, Map<String, dynamic>> res = {};
      decoded.forEach((k, v) {
        res[k] = Map<String, dynamic>.from(v as Map);
      });
      return res;
    } catch (e) {
      debugPrint('Error loading recommendation stats: $e');
      return {};
    }
  }

  static Future<void> clearStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
