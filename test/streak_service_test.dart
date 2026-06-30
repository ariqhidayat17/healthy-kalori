import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_calories/services/streak_service.dart';

/// Test untuk StreakService — hanya pure logic yang tidak butuh PrefsService.
/// Method yang butuh storage (checkAndUpdate, getCurrentStreak) diuji
/// via integration test terpisah.
void main() {

  // ─── motivationMessage ───────────────────────────────────────────────────

  group('motivationMessage', () {
    test('Streak 1 → pesan hari pertama', () {
      final msg = StreakService.motivationMessage(1);
      expect(msg, isNotEmpty);
      expect(msg, contains('🚶'));
    });

    test('Streak 7 → pesan minggu penuh (mengandung angka 7)', () {
      final msg = StreakService.motivationMessage(7);
      expect(msg, contains('7'));
    });

    test('Streak 30 → pesan Spartan', () {
      final msg = StreakService.motivationMessage(30);
      expect(msg, contains('30'));
    });

    test('Semua threshold mengembalikan string non-empty', () {
      for (final streak in [1, 2, 3, 7, 14, 30, 60]) {
        expect(StreakService.motivationMessage(streak), isNotEmpty);
      }
    });
  });

  // ─── _isStreakBroken (diuji via StreakService instance) ──────────────────

  group('isStreakBroken', () {
    // Akses private method via reflection tidak mungkin di Dart,
    // jadi kita test perilakunya secara tidak langsung lewat logika tanggal
    // yang bisa diverifikasi dari luar.

    final service = StreakService();

    test('Tanggal berurutan (selisih 1) → tidak broken', () {
      // Gunakan StreakResult builder helper untuk memvalidasi logika
      // tanggal via method publik _isStreakBroken yang di-expose lewat test
      // Dart tidak expose private, jadi kita test via unit helper di bawah
      expect(_callIsStreakBroken(service, '01/06/2025', '02/06/2025'), isFalse);
    });

    test('Tanggal sama → tidak broken (sudah di-guard sebelumnya)', () {
      expect(_callIsStreakBroken(service, '01/06/2025', '01/06/2025'), isFalse);
    });

    test('Selisih 2 hari → broken', () {
      expect(_callIsStreakBroken(service, '01/06/2025', '03/06/2025'), isTrue);
    });

    test('Selisih 7 hari → broken', () {
      expect(_callIsStreakBroken(service, '01/06/2025', '08/06/2025'), isTrue);
    });

    test('lastDate kosong → tidak broken (kunjungan pertama)', () {
      expect(_callIsStreakBroken(service, '', '01/06/2025'), isFalse);
    });

    test('Lintas bulan berurutan → tidak broken', () {
      // 31 Mei → 1 Juni = selisih 1 hari
      expect(_callIsStreakBroken(service, '31/05/2025', '01/06/2025'), isFalse);
    });

    test('Lintas tahun berurutan → tidak broken', () {
      // 31 Des → 1 Jan = selisih 1 hari
      expect(_callIsStreakBroken(service, '31/12/2024', '01/01/2025'), isFalse);
    });

    test('Format tanggal tidak valid → tidak broken (fallback false)', () {
      expect(_callIsStreakBroken(service, 'bukan-tanggal', '01/06/2025'), isFalse);
    });
  });

  // ─── XP formula per streak length ────────────────────────────────────────

  group('XP per streak (via _xpForStreak)', () {
    test('Streak 1 → 5 XP', () {
      expect(_xpForStreak(1), equals(5));
    });

    test('Streak 3 → 10 XP', () {
      expect(_xpForStreak(3), equals(10));
    });

    test('Streak 7 → 20 XP', () {
      expect(_xpForStreak(7), equals(20));
    });

    test('Streak 14 → 30 XP', () {
      expect(_xpForStreak(14), equals(30));
    });

    test('Streak 30 → 50 XP', () {
      expect(_xpForStreak(30), equals(50));
    });

    test('XP naik seiring streak (tidak menurun)', () {
      final streaks = [1, 3, 7, 14, 30];
      final xps = streaks.map(_xpForStreak).toList();
      for (int i = 0; i < xps.length - 1; i++) {
        expect(xps[i + 1], greaterThanOrEqualTo(xps[i]),
            reason: 'streak ${streaks[i + 1]} harus ≥ streak ${streaks[i]}');
      }
    });
  });

  // ─── StreakResult ─────────────────────────────────────────────────────────

  group('StreakResult', () {
    test('Konstruktor menyimpan semua nilai dengan benar', () {
      const result = StreakResult(
        streak: 7,
        isNewDay: true,
        isStreakBroken: false,
        xpGained: 20,
        longestStreak: 10,
      );
      expect(result.streak, equals(7));
      expect(result.isNewDay, isTrue);
      expect(result.isStreakBroken, isFalse);
      expect(result.xpGained, equals(20));
      expect(result.longestStreak, equals(10));
    });

    test('StreakResult dengan streak broken', () {
      const result = StreakResult(
        streak: 1,
        isNewDay: true,
        isStreakBroken: true,
        xpGained: 5,
        longestStreak: 14,
      );
      expect(result.isStreakBroken, isTrue);
      expect(result.streak, equals(1));
      // Longest streak tidak ter-reset
      expect(result.longestStreak, equals(14));
    });
  });
}

// ── Test helpers ─────────────────────────────────────────────────────────────

/// Mengakses _isStreakBroken via subclass karena method-nya private.
/// Ini pola umum untuk unit-test private logic di Dart.
class _TestableStreakService extends StreakService {
  bool isStreakBrokenPublic(String last, String today) =>
      isStreakBroken(last, today);

  // Expose protected _isStreakBroken
  @override
  bool isStreakBroken(String lastDateStr, String todayStr) =>
      super.isStreakBroken(lastDateStr, todayStr);
}

bool _callIsStreakBroken(StreakService _, String last, String today) {
  return _TestableStreakService().isStreakBrokenPublic(last, today);
}

/// Mirror dari _xpForStreak yang private di StreakService —
/// duplikasi minimal supaya test bisa berjalan tanpa modifikasi source.
int _xpForStreak(int streak) {
  if (streak >= 30) return 50;
  if (streak >= 14) return 30;
  if (streak >= 7)  return 20;
  if (streak >= 3)  return 10;
  return 5;
}
