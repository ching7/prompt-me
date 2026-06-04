import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// 本地通知：定时提示 + 常驻『今日·重要紧急』+ [太难了] 后把微习惯刷到锁屏。
/// flutter_local_notifications 21.x：show/zonedSchedule 均为命名参数。
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _todayChannel = AndroidNotificationChannel(
    'today_focus', '今日聚焦',
    importance: Importance.high,
  );
  static const _microChannel = AndroidNotificationChannel(
    'micro_habit', '微习惯提示',
    importance: Importance.max,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
        settings: const InitializationSettings(android: android));
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_todayChannel);
    await androidImpl?.createNotificationChannel(_microChannel);
    await androidImpl?.requestNotificationsPermission();
  }

  /// 常驻『今日·重要紧急』通知（显示在锁屏，不可滑掉）。
  Future<void> showTodayFocus(List<String> top3) async {
    await _plugin.show(
      id: 1001,
      title: '今日·重要紧急',
      body: top3.isEmpty ? '今天还没安排' : top3.take(3).join(' · '),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'today_focus', '今日聚焦',
          ongoing: true,
          autoCancel: false,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// [太难了] 后把 2 分钟微习惯刷到锁屏。
  Future<void> showMicroHabit(String micro) async {
    await _plugin.show(
      id: 1002,
      title: '现在只要 2 分钟',
      body: micro,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'micro_habit', '微习惯提示',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  /// 每天某时刻的定时提示。
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: when,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('today_focus', '今日聚焦',
            importance: Importance.high, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
