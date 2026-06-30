import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../utils/database_helper.dart';
import '../utils/prefs_service.dart';

/// Smart Notification Service — mengirim notifikasi yang dipersonalisasi
/// berdasarkan data asli user (kalori, air, protein, workout) hari ini.
///
/// Tiga slot notifikasi:
///   07:00 — Pagi: selamat pagi + motivasi berdasarkan streak & goal
///   12:30 — Siang: cek progres kalori & air setengah hari
///   20:00 — Malam: evaluasi hari ini + saran konkret untuk besok
///
/// Setiap pesan dibangun saat notifikasi dijadwalkan ulang (bukan saat
/// dikirim), sehingga mencerminkan data terkini. Untuk data real-time
/// saat notifikasi tiba, gunakan [refreshAndReschedule] dari background
/// task / onResume.
class SmartNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ID notifikasi
  static const int _idMorning   = 201;
  static const int _idAfternoon = 202;
  static const int _idEvening   = 203;
  static const int _idWater     = 204; // one-shot air

  static const _channelId   = 'smart_fitness_channel';
  static const _channelName = 'Smart Fitness Reminders';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Reminder personal berdasarkan progres kalori & air',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Jadwalkan ulang semua notifikasi berdasarkan data hari ini.
  /// Panggil saat: app dibuka, profile berubah, atau data makan/air signifikan.
  static Future<void> refreshAndReschedule() async {
    if (!PrefsService.i.notificationsEnabled) {
      await cancelAll();
      return;
    }

    final context = await _buildContext();

    await cancelAll();
    await _scheduleMorning(context);
    await _scheduleAfternoon(context);
    await _scheduleEvening(context);
    await _scheduleWaterReminder(context);

    debugPrint('[SmartNotif] Dijadwalkan ulang. Konteks: '
        'kalori=${context.consumedCalories}/${context.targetCalories}, '
        'air=${context.consumedWaterMl}ml, '
        'workout=${context.hasWorkoutToday}');
  }

  /// Cancel semua notifikasi smart.
  static Future<void> cancelAll() async {
    for (final id in [_idMorning, _idAfternoon, _idEvening, _idWater]) {
      await _plugin.cancel(id);
    }
  }

  // ─── Context builder ──────────────────────────────────────────────────────

  static Future<_NotifContext> _buildContext() async {
    final p   = PrefsService.i;
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final db  = DatabaseHelper.instance;

    final consumed  = await db.getTotalCaloriesByDate(today);
    final macros    = await db.getTotalMacrosByDate(today);
    final water     = await db.getTotalWaterByDate(today);
    final workouts  = await db.getWorkoutsByDate(today);
    final streak    = p.raw.getInt('daily_streak') ?? 0;

    return _NotifContext(
      name: p.name,
      goal: p.goal,
      activityLevel: p.activityLevel,
      targetCalories: p.targetCalories,
      targetProtein: p.targetProtein,
      targetWater: p.targetWater,
      consumedCalories: consumed,
      consumedProtein: macros['protein'] ?? 0,
      consumedWaterMl: water,
      hasWorkoutToday: workouts.isNotEmpty,
      streak: streak,
    );
  }

  // ─── Morning (07:00) ─────────────────────────────────────────────────────

  static Future<void> _scheduleMorning(_NotifContext ctx) async {
    final msg = _morningMessage(ctx);
    await _scheduleDaily(
      id: _idMorning, hour: 7, minute: 0,
      title: msg.title, body: msg.body,
    );
  }

  static _Msg _morningMessage(_NotifContext ctx) {
    final name = ctx.name.split(' ').first;

    if (ctx.streak >= 7) {
      return _Msg(
        '🔥 $name — ${ctx.streak} Hari Streak!',
        'Konsistensimu luar biasa! Mulai hari ini dengan sarapan '
        'bergizi untuk jaga momentum. Target kalori: ${ctx.targetCalories} kcal.',
      );
    }

    switch (ctx.goal) {
      case 'Bulking':
        return _Msg(
          '💪 Selamat Pagi, $name!',
          'Hari Bulking dimulai! Pastikan sarapanmu kaya protein & kalori. '
          'Target hari ini: ${ctx.targetCalories} kcal | ${ctx.targetProtein}g protein.',
        );
      case 'Cutting':
        return _Msg(
          '⚡ Pagi, $name! Jaga Defisit Hari Ini',
          'Cutting butuh konsistensi. Mulai dengan sarapan tinggi protein & '
          'rendah kalori. Target: ${ctx.targetCalories} kcal hari ini.',
        );
      default:
        return _Msg(
          '🌅 Selamat Pagi, $name!',
          'Hari baru, kesempatan baru! Target harianmu: '
          '${ctx.targetCalories} kcal & ${ctx.targetProtein}g protein. '
          'Mulai catat sarapanmu 🍳',
        );
    }
  }

  // ─── Afternoon (12:30) ───────────────────────────────────────────────────

  static Future<void> _scheduleAfternoon(_NotifContext ctx) async {
    final msg = _afternoonMessage(ctx);
    await _scheduleDaily(
      id: _idAfternoon, hour: 12, minute: 30,
      title: msg.title, body: msg.body,
    );
  }

  static _Msg _afternoonMessage(_NotifContext ctx) {
    final remaining = (ctx.targetCalories - ctx.consumedCalories).clamp(0, ctx.targetCalories);
    final waterGelas = (ctx.consumedWaterMl / 250).floor();
    final targetGelas = (ctx.targetWater / 250).round();
    final waterSisa = (targetGelas - waterGelas).clamp(0, targetGelas);

    // Kalori belum dicatat sama sekali
    if (ctx.consumedCalories == 0) {
      return _Msg(
        '📋 Belum Ada Catatan Hari Ini',
        'Kamu belum mencatat makanan apapun hari ini. '
        'Buka aplikasi dan mulai catat sekarang — '
        'sisa target: $remaining kcal.',
      );
    }

    // Progress sudah bagus (>40% tercapai di siang hari)
    final pct = ctx.consumedCalories / ctx.targetCalories;
    if (pct >= 0.4 && pct <= 0.65) {
      return _Msg(
        '✅ Progress Siang Bagus!',
        '${ctx.consumedCalories} kcal tercatat. Sisa $remaining kcal & '
        '$waterSisa gelas air untuk hari ini. '
        '${ctx.hasWorkoutToday ? "Workout sudah ✓" : "Workout belum dijadwalkan hari ini."}',
      );
    }

    // Terlalu banyak kalori di siang hari
    if (pct > 0.65) {
      return _Msg(
        '⚠️ Perhatian: Kalori Siang Tinggi',
        '${ctx.consumedCalories} kcal sudah masuk — itu ${(pct * 100).round()}% dari target harian. '
        'Seimbangkan makan malam agar total tetap on track.',
      );
    }

    // Air kurang
    if (waterGelas < 3) {
      return _Msg(
        '💧 Jangan Lupa Minum Air!',
        'Baru $waterGelas gelas dari $targetGelas gelas target air hari ini. '
        'Dehidrasi menurunkan performa gym. Minum sekarang! 💦',
      );
    }

    return _Msg(
      '🏋️ Siang Hari — Cek Progress!',
      '${ctx.consumedCalories} kcal tercatat, sisa $remaining kcal. '
      'Air: $waterGelas/$targetGelas gelas. '
      'Protein: ${ctx.consumedProtein}/${ctx.targetProtein}g.',
    );
  }

  // ─── Evening (20:00) ─────────────────────────────────────────────────────

  static Future<void> _scheduleEvening(_NotifContext ctx) async {
    final msg = _eveningMessage(ctx);
    await _scheduleDaily(
      id: _idEvening, hour: 20, minute: 0,
      title: msg.title, body: msg.body,
    );
  }

  static _Msg _eveningMessage(_NotifContext ctx) {
    final remaining  = (ctx.targetCalories - ctx.consumedCalories).clamp(0, ctx.targetCalories);
    final pct        = ctx.targetCalories > 0
        ? ctx.consumedCalories / ctx.targetCalories
        : 0.0;
    final proteinGap = (ctx.targetProtein - ctx.consumedProtein).clamp(0, ctx.targetProtein);
    final waterGelas = (ctx.consumedWaterMl / 250).floor();
    final targetGelas = (ctx.targetWater / 250).round();

    // Belum ada data sama sekali
    if (ctx.consumedCalories == 0) {
      return _Msg(
        '📵 Tidak Ada Catatan Hari Ini',
        'Hari hampir selesai tapi belum ada makanan tercatat. '
        'Jangan biarkan harimu berlalu tanpa data — buka aplikasi sekarang!',
      );
    }

    // Target hampir tercapai (90–110%)
    if (pct >= 0.9 && pct <= 1.1) {
      return _Msg(
        '🎯 Target Kalori Hampir Sempurna!',
        '${ctx.consumedCalories}/${ctx.targetCalories} kcal. '
        '${proteinGap > 0 ? "Protein masih kurang ${proteinGap}g — tambah sumber protein malam ini." : "Protein juga on track ✓"} '
        '${!ctx.hasWorkoutToday ? "Besok jangan lupa workout!" : ""}',
      );
    }

    // Kurang banyak — cutting bisa oke, bulking perlu tambah
    if (pct < 0.75) {
      if (ctx.goal == 'Cutting') {
        return _Msg(
          '✂️ Defisit Tercapai, ${ ctx.name.split(" ").first}!',
          'Hanya ${ctx.consumedCalories} kcal hari ini — defisit berjalan baik. '
          'Pastikan protein tetap tinggi ($proteinGap g lagi) untuk jaga otot.',
        );
      }
      return _Msg(
        '⚠️ Kalori Masih Kurang ${remaining} kcal',
        'Baru ${ctx.consumedCalories} kcal dari ${ctx.targetCalories} kcal. '
        'Untuk ${ctx.goal == "Bulking" ? "bulking" : "maintenance"}, coba tambah '
        'camilan protein sebelum tidur seperti Greek yogurt atau cottage cheese.',
      );
    }

    // Terlalu banyak
    if (pct > 1.15) {
      return _Msg(
        '🚨 Kalori Melebihi Target',
        '${ctx.consumedCalories} kcal — ${ctx.consumedCalories - ctx.targetCalories} kcal di atas target. '
        'Besok mulai lebih terkontrol dan catat dari pagi.',
      );
    }

    // Air masih kurang di malam hari
    if (waterGelas < targetGelas - 2) {
      return _Msg(
        '💧 Minum Air Dulu Sebelum Tidur!',
        'Baru $waterGelas/$targetGelas gelas hari ini. '
        'Minum 1-2 gelas lagi sebelum tidur untuk recovery otot.',
      );
    }

    // Default: ringkasan positif
    return _Msg(
      '📊 Evaluasi Hari Ini',
      '${ctx.consumedCalories}/${ctx.targetCalories} kcal | '
      '${ctx.consumedProtein}/${ctx.targetProtein}g protein | '
      '$waterGelas/$targetGelas gelas air. '
      '${ctx.hasWorkoutToday ? "Workout ✓ — kerja bagus!" : "Rest day — pulihkan tubuhmu."}',
    );
  }

  // ─── Water reminder (one-shot, jika air < 50% target pukul 15:00) ────────

  static Future<void> _scheduleWaterReminder(_NotifContext ctx) async {
    final waterGelas  = (ctx.consumedWaterMl / 250).floor();
    final targetGelas = (ctx.targetWater / 250).round();

    // Hanya kirim jika air < 50% target (bisa diketahui dari data siang)
    if (waterGelas >= targetGelas ~/ 2) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 15, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idWater,
      '💧 Reminder: Minum Air Sekarang!',
      'Baru $waterGelas dari $targetGelas gelas hari ini. '
      'Dehidrasi menurunkan performa & fokus. Minum segelas sekarang! 💦',
      scheduled,
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Core scheduler ───────────────────────────────────────────────────────

  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id, title, body, scheduled, _notifDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

// ─── Internal types ───────────────────────────────────────────────────────────

class _NotifContext {
  final String name;
  final String goal;
  final String activityLevel;
  final int targetCalories;
  final int targetProtein;
  final int targetWater;
  final int consumedCalories;
  final int consumedProtein;
  final int consumedWaterMl;
  final bool hasWorkoutToday;
  final int streak;

  const _NotifContext({
    required this.name,
    required this.goal,
    required this.activityLevel,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetWater,
    required this.consumedCalories,
    required this.consumedProtein,
    required this.consumedWaterMl,
    required this.hasWorkoutToday,
    required this.streak,
  });
}

class _Msg {
  final String title;
  final String body;
  const _Msg(this.title, this.body);
}
