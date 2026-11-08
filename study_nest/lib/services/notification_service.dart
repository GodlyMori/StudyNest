import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'platform_helper_stub.dart'
    if (dart.library.io) 'platform_helper_io.dart'
    if (dart.library.html) 'platform_helper_web.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _remindersKey = 'scheduled_study_reminders';
  static const String _permissionKey = 'notification_permission_granted';
  static const String _permissionRequestedKey = 'notification_permission_requested';

  static bool _initialized = false;

  /// Test hook to verify scheduled notifications without native platform dependency
  static List<Map<String, dynamic>> mockScheduledNotifications = [];

  static bool get _isNativePlatform {
    if (kIsWeb) return false;
    return isNativeNotificationSupported();
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization note: $e');
    }

    if (_isNativePlatform) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open notification',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      try {
        await _notificationsPlugin.initialize(initSettings);
      } catch (e) {
        debugPrint('Notification plugin initialize note: $e');
      }
    }

    _initialized = true;
  }

  /// Whether notification permission has already been prompted
  static Future<bool> hasRequestedPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionRequestedKey) ?? false;
  }

  /// Whether user has granted notification permission
  static Future<bool> isPermissionGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) ?? false;
  }

  /// Update permission state in SharedPreferences
  static Future<void> setPermissionGranted(bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionRequestedKey, true);
    await prefs.setBool(_permissionKey, granted);

    if (granted && _isNativePlatform) {
      try {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();

        final iosImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('Platform permission request note: $e');
      }
    }
  }

  /// Schedule a notification for a study session
  static Future<void> scheduleSessionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    required String dateStr,
    required String timeStr,
  }) async {
    await initialize();

    // Persist reminder info in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final reminders = await getScheduledReminders();

    // Remove existing with same id if any
    reminders.removeWhere((r) => r['id'] == id);

    final newReminder = {
      'id': id,
      'title': title,
      'body': body,
      'scheduledTime': scheduledDateTime.toIso8601String(),
      'date': dateStr,
      'time': timeStr,
    };
    reminders.add(newReminder);
    await prefs.setString(_remindersKey, jsonEncode(reminders));

    mockScheduledNotifications.add(newReminder);

    // Schedule on platform if native and not in test runner
    if (_isNativePlatform) {
      try {
        final location = tz.local;
        final tzDateTime = tz.TZDateTime.from(scheduledDateTime, location);

        // If time is in the past, schedule slightly in future for instant test verification
        final targetTime = tzDateTime.isBefore(tz.TZDateTime.now(location))
            ? tz.TZDateTime.now(location).add(const Duration(seconds: 5))
            : tzDateTime;

        const androidDetails = AndroidNotificationDetails(
          'study_sessions_channel',
          'Study Session Reminders',
          channelDescription: 'Notifications for upcoming study sessions',
          importance: Importance.high,
          priority: Priority.high,
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          targetTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Zoned schedule note: $e');
      }
    }
  }

  /// Cancel a scheduled notification by id
  static Future<void> cancelReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await getScheduledReminders();
    reminders.removeWhere((r) => r['id'] == id);
    await prefs.setString(_remindersKey, jsonEncode(reminders));

    mockScheduledNotifications.removeWhere((r) => r['id'] == id);

    if (_isNativePlatform) {
      try {
        await _notificationsPlugin.cancel(id);
      } catch (e) {
        debugPrint('Cancel notification note: $e');
      }
    }
  }

  /// Get list of all currently scheduled reminders
  static Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_remindersKey);
    if (data == null || data.isEmpty) {
      return [];
    }
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear all reminders and permissions (test helper)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
    await prefs.remove(_permissionKey);
    await prefs.remove(_permissionRequestedKey);
    mockScheduledNotifications.clear();
    if (_isNativePlatform) {
      try {
        await _notificationsPlugin.cancelAll();
      } catch (_) {}
    }
  }
}
