import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';

class PlannerService {
  static const String _sessionsKey = 'study_planner_sessions';

  static final List<StudySession> _defaultWednesdaySessions = [
    const StudySession(
      id: 'session_calc_checkin',
      time: '2:00 PM – 2:30 PM',
      subject: 'Calculus — Derivatives Check-in',
      type: 'Review & 5-min Quiz',
      duration: '30 min',
      status: 'Upcoming',
      date: 'Wed',
      title: 'Calculus — Derivatives Check-in',
    ),
    const StudySession(
      id: 'session_bio_flashcards',
      time: '4:30 PM – 5:15 PM',
      subject: 'Biology — Cell Structure Flashcards',
      type: 'Notes & Memorization',
      duration: '45 min',
      status: 'Scheduled',
      date: 'Wed',
      title: 'Biology — Cell Structure Flashcards',
    ),
    const StudySession(
      id: 'session_calc_crew',
      time: '7:00 PM – 8:00 PM',
      subject: 'Calculus Crew — Group Study Session',
      type: 'Peer Discussion',
      duration: '60 min',
      status: 'Group Call',
      date: 'Wed',
      title: 'Calculus Crew — Group Study Session',
    ),
  ];

  /// Retrieve all stored sessions or initialize with defaults if empty
  static Future<List<StudySession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_sessionsKey);
    if (data == null) {
      // Initialize with Wednesday default sessions
      await _saveAllSessions(_defaultWednesdaySessions);
      return List<StudySession>.from(_defaultWednesdaySessions);
    }
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((item) => StudySession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List<StudySession>.from(_defaultWednesdaySessions);
    }
  }

  /// Get sessions for a given day (e.g. dayName 'Wed', dayDate '6')
  static Future<List<StudySession>> getSessionsForDay(
    String dayName,
    String dayDate,
  ) async {
    final all = await getAllSessions();
    return all.where((session) {
      final d = session.date.trim().toLowerCase();
      return d == dayName.toLowerCase() ||
          d == dayDate.toLowerCase() ||
          d.contains(dayName.toLowerCase()) ||
          d.contains(dayDate.toLowerCase());
    }).toList();
  }

  /// Add or update a session
  static Future<void> saveSession(StudySession session) async {
    final all = await getAllSessions();
    final index = all.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      all[index] = session;
    } else {
      all.add(session);
    }
    await _saveAllSessions(all);
  }

  /// Delete a session by id
  static Future<void> deleteSession(String sessionId) async {
    final all = await getAllSessions();
    all.removeWhere((s) => s.id == sessionId);
    await _saveAllSessions(all);
  }

  /// Internal save helper
  static Future<void> _saveAllSessions(List<StudySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  /// Reset to defaults (for tests)
  static Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}
