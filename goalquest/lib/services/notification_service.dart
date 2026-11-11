import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'profile_service.dart';

/// Local reminders, scheduled on the device (no push server needed):
///  - a daily mission reminder at the time the user picks;
///  - an evening "your streak ends tonight" nudge, only on days the user
///    has a streak and hasn't been active yet.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _dailyId = 1;
  static const _streakId = 2;
  static const _enabledKey = 'reminders_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';

  /// Time of the streak nudge (local time).
  static const streakNudgeTime = TimeOfDay(hour: 20, minute: 0);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  final ValueNotifier<bool> enabled = ValueNotifier(false);
  final ValueNotifier<TimeOfDay> dailyTime = ValueNotifier(const TimeOfDay(hour: 17, minute: 0));

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Daily mission reminders and streak nudges',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Call once at startup. Safe to call where notifications are unsupported.
  Future<void> init() async {
    if (kIsWeb || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          // Ask for permission only when the user turns reminders on.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;

      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_enabledKey) ?? false;
      dailyTime.value = TimeOfDay(
        hour: prefs.getInt(_hourKey) ?? 17,
        minute: prefs.getInt(_minuteKey) ?? 0,
      );
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  Future<bool> _requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: false, sound: true) ?? false;
    }
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  /// Turns reminders on (asking for permission) or off. Returns whether
  /// reminders are now on.
  Future<bool> setEnabled(bool on) async {
    if (!_ready) return false;
    if (on && !await _requestPermission()) on = false;
    enabled.value = on;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, on);
    await reschedule();
    return on;
  }

  Future<void> setDailyTime(TimeOfDay time) async {
    dailyTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
    await reschedule();
  }

  /// Re-plans both notifications from current settings and progress.
  /// Call after completing a mission or game and when the app resumes.
  Future<void> reschedule() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _dailyId);
      await _plugin.cancel(id: _streakId);
      if (!enabled.value) return;

      final now = tz.TZDateTime.now(tz.local);
      final profile = ProfileService.instance.currentProfile;
      final activeToday = _isToday(profile?.lastActive, now);

      // Daily reminder; skip today if the user has already been active.
      var daily = _at(now, dailyTime.value);
      if (!daily.isAfter(now) || activeToday) daily = daily.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _dailyId,
        title: "Today's missions are ready",
        body: 'Five small actions for the Global Goals. Pick one – it only takes a few minutes.',
        scheduledDate: daily,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Streak nudge tonight, only if there's a streak to lose.
      final streak = profile?.streak ?? 0;
      final nudge = _at(now, streakNudgeTime);
      if (streak > 0 && !activeToday && nudge.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: _streakId,
          title: 'Your $streak-day streak ends tonight',
          body: 'Complete one quick mission to keep it going.',
          scheduledDate: nudge,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('NotificationService.reschedule failed: $e');
    }
  }

  static tz.TZDateTime _at(tz.TZDateTime now, TimeOfDay t) =>
      tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);

  static bool _isToday(DateTime? d, tz.TZDateTime now) =>
      d != null && d.year == now.year && d.month == now.month && d.day == now.day;
}
