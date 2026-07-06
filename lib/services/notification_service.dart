import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const int dailyReminderId = 100;
  static const int goalReminderId = 101;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

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

  Future<void> cancelDailyReminder() => _plugin.cancel(dailyReminderId);

  Future<void> showGoalNearCompletionNotification(String message) async {
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
