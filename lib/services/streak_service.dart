import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../utils/prefs_service.dart';
import 'gamification_service.dart';

/// Mengelola streak harian — pengguna dianggap aktif jika membuka app
/// setidaknya sekali per hari. Streak putus jika ada hari yang terlewat.
///
/// Keys yang digunakan (via PrefsService):
///   kDailyStreak      — jumlah hari berturut-turut saat ini
///   kLastActiveDate   — tanggal terakhir user dianggap aktif (dd/MM/yyyy)
///   kLongestStreak    — rekor streak terpanjang sepanjang masa
class StreakService {
  static const kDailyStreak    = 'daily_streak';
  static const kLastActiveDate = 'last_active_date';
  static const kLongestStreak  = 'longest_streak';

  /// XP yang diberikan berdasarkan panjang streak.
  /// Semakin panjang streak → bonus lebih besar.
  static int _xpForStreak(int streak) {
    if (streak >= 30) return 50;
    if (streak >= 14) return 30;
    if (streak >= 7)  return 20;
    if (streak >= 3)  return 10;
    return 5; // hari pertama / streak pendek
  }

  /// Pesan motivasi berdasarkan streak hari ini.
  static String motivationMessage(int streak) {
    if (streak == 1)  return 'Perjalanan seribu mil dimulai dari satu langkah! 🚶';
    if (streak < 3)   return 'Mulai terbentuk kebiasaan baik! Lanjutkan! 💪';
    if (streak < 7)   return '$streak hari berturut-turut! Kamu serius! 🔥';
    if (streak < 14)  return 'Satu minggu lebih! Konsistensimu luar biasa! ⚡';
    if (streak < 30)  return '$streak hari! Kamu mendekati gelar Spartan sejati! 🏆';
    return '$streak hari! SPARTAN MODE ACTIVATED! 👑';
  }

  /// Dipanggil saat app dibuka. Mengecek dan memperbarui streak.
  ///
  /// Mengembalikan [StreakResult] berisi:
  /// - streak terkini
  /// - apakah ini hari baru (perlu tampil notifikasi/dialog)
  /// - apakah streak baru dimulai setelah putus
  /// - XP yang didapat (0 jika bukan hari baru)
  Future<StreakResult> checkAndUpdate() async {
    final p = PrefsService.i.raw;
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final lastActive = p.getString(kLastActiveDate) ?? '';
    int currentStreak = p.getInt(kDailyStreak) ?? 0;
    int longestStreak = p.getInt(kLongestStreak) ?? 0;

    // Sudah dicek hari ini → tidak ada perubahan
    if (lastActive == today) {
      return StreakResult(
        streak: currentStreak,
        isNewDay: false,
        isStreakBroken: false,
        xpGained: 0,
        longestStreak: longestStreak,
      );
    }

    final bool wasStreakBroken = isStreakBroken(lastActive, today);

    if (wasStreakBroken) {
      // Streak putus — reset ke 1
      currentStreak = 1;
    } else {
      // Hari berikutnya berturut-turut
      currentStreak += 1;
    }

    // Update longest streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
      await p.setInt(kLongestStreak, longestStreak);
    }

    // Simpan state baru
    await p.setInt(kDailyStreak, currentStreak);
    await p.setString(kLastActiveDate, today);

    // Beri XP
    final xp = _xpForStreak(currentStreak);
    await GamificationService().addXP(xp);

    return StreakResult(
      streak: currentStreak,
      isNewDay: true,
      isStreakBroken: wasStreakBroken,
      xpGained: xp,
      longestStreak: longestStreak,
    );
  }

  /// Ambil streak saat ini tanpa update.
  Future<int> getCurrentStreak() async {
    return PrefsService.i.raw.getInt(kDailyStreak) ?? 0;
  }

  /// Ambil rekor streak terpanjang.
  Future<int> getLongestStreak() async {
    return PrefsService.i.raw.getInt(kLongestStreak) ?? 0;
  }

  /// Menentukan apakah streak putus berdasarkan tanggal terakhir aktif.
  /// Streak dianggap putus jika selisih > 1 hari kalender.
  /// Method ini @protected agar bisa di-override di test.
  @protected
  bool isStreakBroken(String lastDateStr, String todayStr) {
    if (lastDateStr.isEmpty) return false; // Pertama kali buka app
    try {
      final fmt = DateFormat('dd/MM/yyyy');
      final last  = fmt.parse(lastDateStr);
      final today = fmt.parse(todayStr);
      final diff  = today.difference(last).inDays;
      return diff > 1; // 1 = hari berikutnya (oke), >1 = ada hari terlewat
    } catch (_) {
      return false;
    }
  }
}

/// Hasil dari [StreakService.checkAndUpdate].
class StreakResult {
  final int streak;
  final bool isNewDay;
  final bool isStreakBroken;
  final int xpGained;
  final int longestStreak;

  const StreakResult({
    required this.streak,
    required this.isNewDay,
    required this.isStreakBroken,
    required this.xpGained,
    required this.longestStreak,
  });
}
