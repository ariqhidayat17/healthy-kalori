import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _morningId = 101;
  static const int _afternoonId = 102;
  static const int _eveningId = 103;

  // ── POOL PESAN PAGI (07:00) ───────────────────────────────────────────────
  static const List<Map<String, String>> _morningMessages = [
    {
      'title': '🌅 Selamat Pagi, Atletik!',
      'body': 'Mulai hari dengan sarapan bergizi tinggi protein. Catat sekarang! 💪',
    },
    {
      'title': '🍳 Sarapan Dulu, Baru Taklukkan Dunia!',
      'body': 'Tubuhmu butuh bahan bakar pagi ini. Sudah sarapan? Catat di aplikasi yuk!',
    },
    {
      'title': '☀️ Pagi yang Produktif Dimulai dari Meja Makan',
      'body': 'Target kalori harianmu menunggu. Catat sarapanmu sekarang!',
    },
    {
      'title': '🥚 Protein Pagi = Energi Seharian',
      'body': 'Riset ACSM: sarapan kaya protein membantu jaga massa otot. Jangan dilewat!',
    },
    {
      'title': '💪 Rise & Grind!',
      'body': 'Binaragawan sejati tidak melewatkan sarapan. Catat makro pagimu!',
    },
  ];

  // ── POOL PESAN SORE (15:30) ───────────────────────────────────────────────
  static const List<Map<String, String>> _afternoonMessages = [
    {
      'title': '🏋️ Sudah Makan Sebelum Gym?',
      'body': 'Pre-workout meal itu penting! Pastikan karbohidrat & protein sudah cukup.',
    },
    {
      'title': '⚡ Waktunya Charge Energi!',
      'body': 'Latihan sore butuh bahan bakar. Cek sisa kalori harianmu sekarang.',
    },
    {
      'title': '🥗 Jangan Lupa Catat Makan Siang!',
      'body': 'Sudah catat makan siangmu? Update di aplikasi agar makromu terpantau.',
    },
    {
      'title': '🏃 Sore Ini Gym atau Rest Day?',
      'body': 'Kalau gym: pastikan protein cukup. Kalau rest: jaga kalori tetap on track!',
    },
    {
      'title': '💡 Reminder: Catat Makananmu!',
      'body': 'Konsistensi pencatatan = hasil yang lebih akurat. Yuk update sekarang!',
    },
  ];

  // ── POOL PESAN MALAM (20:30) ──────────────────────────────────────────────
  static const List<Map<String, String>> _eveningMessages = [
    {
      'title': '📊 Evaluasi Harimu Sekarang!',
      'body': 'Sudah berapa kalori hari ini? Cek apakah target makromu tercapai.',
    },
    {
      'title': '🌙 Review Malam: Sudah On Track?',
      'body': 'Tinjau asupan protein, karbo, dan lemakmu hari ini sebelum tidur.',
    },
    {
      'title': '✅ Recap Harian — 2 Menit Saja!',
      'body': 'Buka aplikasi, cek totalmu, dan siapkan strategi makan untuk besok!',
    },
    {
      'title': '🎯 Seberapa Dekat Kamu Dengan Target?',
      'body': 'Lihat progress harianmu dan pastikan kalori malam tidak berlebihan.',
    },
    {
      'title': '😴 Sebelum Tidur: Cek Makromu!',
      'body': 'Apakah protein harianmu sudah tercukupi? Itu kunci recovery otot malam ini.',
    },
  ];

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

  /// Jadwalkan 3 notifikasi harian dengan pesan acak yang sesuai waktu:
  /// - 07:00 → Pengingat sarapan pagi
  /// - 15:30 → Pengingat sore / pre-workout
  /// - 20:30 → Evaluasi kalori malam
  static Future<void> scheduleDailyNotifications() async {
    await cancelAllNotifications();
    final rng = Random();

    // Pagi: 07:00
    final morning = _morningMessages[rng.nextInt(_morningMessages.length)];
    await _scheduleDailyAt(
      id: _morningId,
      hour: 7,
      minute: 0,
      title: morning['title']!,
      body: morning['body']!,
    );

    // Sore: 15:30
    final afternoon = _afternoonMessages[rng.nextInt(_afternoonMessages.length)];
    await _scheduleDailyAt(
      id: _afternoonId,
      hour: 15,
      minute: 30,
      title: afternoon['title']!,
      body: afternoon['body']!,
    );

    // Malam: 20:30
    final evening = _eveningMessages[rng.nextInt(_eveningMessages.length)];
    await _scheduleDailyAt(
      id: _eveningId,
      hour: 20,
      minute: 30,
      title: evening['title']!,
      body: evening['body']!,
    );

    debugPrint('[NotificationHelper] 3 notifikasi harian (acak) dijadwalkan.');
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
