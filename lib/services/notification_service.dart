import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const int dailyReminderId = 100;
  static const int goalReminderId = 101;

  /// Attach this to `MaterialApp(navigatorKey: ...)` so the desktop
  /// fallback below can reach a [BuildContext] to show an in-app SnackBar.
  static final navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// `flutter_local_notifications` has no Windows implementation at all in
  /// the pinned version (no native plugin, no `WindowsNotificationDetails`),
  /// and `zonedSchedule()` throws `UnimplementedError` on Linux too. Desktop
  /// instead gets a plain in-process [Timer] that shows an in-app SnackBar
  /// and reschedules itself for the next day; it only fires while the app
  /// is running/foregrounded, unlike the native OS scheduling used elsewhere.
  bool get _needsDesktopFallback => !kIsWeb && (Platform.isWindows || Platform.isLinux);
  Timer? _desktopReminderTimer;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // `tz.local` defaults to UTC until told otherwise — without this, every
    // scheduled reminder fires at the wrong wall-clock time for anyone
    // outside UTC (e.g. an 18:00 reminder would actually fire at 01:00 the
    // next day in Vietnam, UTC+7).
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // Falls back to UTC if the platform timezone can't be resolved.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macosImpl = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await androidImpl?.requestNotificationsPermission();
    final iosGranted = await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
    final macosGranted = await macosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    return (androidGranted ?? true) && (iosGranted ?? true) && (macosGranted ?? true);
  }

  /// Schedules a daily repeating reminder at [hour]:[minute].
  Future<void> scheduleDailyReminder({required int hour, required int minute}) async {
    if (_needsDesktopFallback) {
      _scheduleDesktopDailyReminder(hour: hour, minute: minute);
      return;
    }

    await requestPermission();
    await _plugin.zonedSchedule(
      dailyReminderId,
      'Đến giờ chạy bộ rồi!',
      'Ra ngoài vận động một chút để giữ streak nhé.',
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc nhở hằng ngày',
          channelDescription: 'Nhắc nhở chạy bộ mỗi ngày',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _scheduleDesktopDailyReminder({required int hour, required int minute}) {
    _desktopReminderTimer?.cancel();

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));

    _desktopReminderTimer = Timer(next.difference(now), () {
      _showDesktopBanner('⏰ Đến giờ chạy bộ rồi! Ra ngoài vận động một chút để giữ streak nhé.');
      _scheduleDesktopDailyReminder(hour: hour, minute: minute);
    });
  }

  void _showDesktopBanner(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  Future<void> cancelDailyReminder() {
    _desktopReminderTimer?.cancel();
    _desktopReminderTimer = null;
    return _plugin.cancel(dailyReminderId);
  }

  Future<void> showGoalNearCompletionNotification(String message) async {
    if (_needsDesktopFallback) {
      _showDesktopBanner('🎯 $message');
      return;
    }
    await _plugin.show(
      goalReminderId,
      'Sắp đạt mục tiêu!',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_reminder',
          'Nhắc mục tiêu',
          channelDescription: 'Thông báo khi gần đạt mục tiêu tuần/tháng',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
