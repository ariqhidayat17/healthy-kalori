import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _breakfastId = 101;
  static const int _lunchTrainingId = 102;
  static const int _eveningEvalId = 103;

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
  }

  static Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Jadwalkan 3 notifikasi pengingat harian:
  /// - 07:00 → Sarapan & catat kalori pagi
  /// - 16:00 → Pengingat latihan di gym
  /// - 20:00 → Evaluasi kalori malam hari
  static Future<void> scheduleDailyNotifications() async {
    await cancelAllNotifications();

    await _scheduleDailyAt(
      id: _breakfastId,
      hour: 7,
      minute: 0,
      title: '🍳 Sarapan & Kalori Pagi!',
      body:
          'Jangan lupa catat sarapanmu dan mulai harimu dengan bertenaga! 💪',
    );

    await _scheduleDailyAt(
      id: _lunchTrainingId,
      hour: 16,
      minute: 0,
      title: '🏋️ Waktunya Latihan!',
      body:
          'Gym time! Pastikan kalori & proteinmu sudah tercukupi sebelum angkat beban.',
    );

    await _scheduleDailyAt(
      id: _eveningEvalId,
      hour: 20,
      minute: 0,
      title: '📊 Evaluasi Kalori Malam',
      body:
          'Cek progres harianmu! Sudahkah target kalori & makronutrisimu terpenuhi?',
    );

    debugPrint('[NotificationHelper] 3 jadwal notifikasi harian aktif.');
  }

  static Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika jam sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'bodybuilder_calorie_channel',
      'Pengingat Kalori & Latihan',
      channelDescription:
          'Notifikasi harian untuk pelacakan kalori dan jadwal latihan',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationHelper] Semua notifikasi dibatalkan.');
  }
}
