import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendationItem {
  final String topic;
  final String subject;
  final String priority; // 'High priority', 'Medium', 'Low'
  final String timeEstimate; // '8 min', '6 min', etc.
  final int wrongCount;
  final DateTime lastAttempt;

  const RecommendationItem({
    required this.topic,
    required this.subject,
    required this.priority,
    required this.timeEstimate,
    required this.wrongCount,
    required this.lastAttempt,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'subject': subject,
        'priority': priority,
        'timeEstimate': timeEstimate,
        'wrongCount': wrongCount,
        'lastAttempt': lastAttempt.toIso8601String(),
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
      );
}

class RecommendationEngine {
  static const String _storageKey = 'recommendation_topic_stats';

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

  /// Rules Engine Ranking:
  /// 1. Weakest topic first (highest wrongCount descending).
  /// 2. Longest since last attempt ascending (spaced repetition).
  static Future<List<RecommendationItem>> getRankedRecommendations() async {
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
