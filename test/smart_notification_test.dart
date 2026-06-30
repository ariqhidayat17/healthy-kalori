import 'package:flutter_test/flutter_test.dart';

/// Test untuk logika pesan SmartNotificationService.
///
/// Karena _morningMessage, _afternoonMessage, _eveningMessage adalah
/// static private, kita mirror logikanya di sini sebagai pure function
/// dan test semua skenario kondisional.
///
/// Ini memastikan pesan yang dikirim ke user selalu masuk akal
/// dan tidak ada kondisi yang menghasilkan pesan kosong/crash.

// ── Mirror dari _NotifContext (public version untuk test) ────────────────────

class NotifContext {
  final String name;
  final String goal;
  final int targetCalories;
  final int targetProtein;
  final int targetWater;
  final int consumedCalories;
  final int consumedProtein;
  final int consumedWaterMl;
  final bool hasWorkoutToday;
  final int streak;

  const NotifContext({
    this.name = 'Budi',
    this.goal = 'Bulking',
    this.targetCalories = 2500,
    this.targetProtein = 180,
    this.targetWater = 4000,
    this.consumedCalories = 0,
    this.consumedProtein = 0,
    this.consumedWaterMl = 0,
    this.hasWorkoutToday = false,
    this.streak = 0,
  });

  NotifContext copyWith({
    String? goal,
    int? consumedCalories,
    int? consumedProtein,
    int? consumedWaterMl,
    bool? hasWorkoutToday,
    int? streak,
  }) =>
      NotifContext(
        name: name,
        goal: goal ?? this.goal,
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetWater: targetWater,
        consumedCalories: consumedCalories ?? this.consumedCalories,
        consumedProtein: consumedProtein ?? this.consumedProtein,
        consumedWaterMl: consumedWaterMl ?? this.consumedWaterMl,
        hasWorkoutToday: hasWorkoutToday ?? this.hasWorkoutToday,
        streak: streak ?? this.streak,
      );
}

// ── Mirror dari _morningMessage ───────────────────────────────────────────────

({String title, String body}) morningMessage(NotifContext ctx) {
  final name = ctx.name.split(' ').first;
  if (ctx.streak >= 7) {
    return (
      title: '🔥 $name — ${ctx.streak} Hari Streak!',
      body: 'Konsistensimu luar biasa! Mulai hari ini dengan sarapan '
          'bergizi untuk jaga momentum. Target kalori: ${ctx.targetCalories} kcal.',
    );
  }
  switch (ctx.goal) {
    case 'Bulking':
      return (
        title: '💪 Selamat Pagi, $name!',
        body: 'Hari Bulking dimulai! Pastikan sarapanmu kaya protein & kalori.',
      );
    case 'Cutting':
      return (
        title: '⚡ Pagi, $name! Jaga Defisit Hari Ini',
        body: 'Cutting butuh konsistensi.',
      );
    default:
      return (
        title: '🌅 Selamat Pagi, $name!',
        body: 'Hari baru, kesempatan baru!',
      );
  }
}

// ── Mirror dari _afternoonMessage ─────────────────────────────────────────────

({String title, String body}) afternoonMessage(NotifContext ctx) {
  final remaining = (ctx.targetCalories - ctx.consumedCalories).clamp(0, ctx.targetCalories);
  final waterGelas = (ctx.consumedWaterMl / 250).floor();
  final targetGelas = (ctx.targetWater / 250).round();

  if (ctx.consumedCalories == 0) {
    return (
      title: '📋 Belum Ada Catatan Hari Ini',
      body: 'Kamu belum mencatat makanan apapun hari ini. '
          'Sisa target: $remaining kcal.',
    );
  }

  final pct = ctx.consumedCalories / ctx.targetCalories;
  if (pct >= 0.4 && pct <= 0.65) {
    return (
      title: '✅ Progress Siang Bagus!',
      body: '${ctx.consumedCalories} kcal tercatat.',
    );
  }
  if (pct > 0.65) {
    return (
      title: '⚠️ Perhatian: Kalori Siang Tinggi',
      body: '${ctx.consumedCalories} kcal sudah masuk.',
    );
  }
  if (waterGelas < 3) {
    return (
      title: '💧 Jangan Lupa Minum Air!',
      body: 'Baru $waterGelas gelas dari $targetGelas gelas target.',
    );
  }
  return (
    title: '🏋️ Siang Hari — Cek Progress!',
    body: '${ctx.consumedCalories} kcal tercatat.',
  );
}

// ── Mirror dari _eveningMessage ───────────────────────────────────────────────

({String title, String body}) eveningMessage(NotifContext ctx) {
  final remaining = (ctx.targetCalories - ctx.consumedCalories).clamp(0, ctx.targetCalories);
  final pct = ctx.targetCalories > 0 ? ctx.consumedCalories / ctx.targetCalories : 0.0;
  final proteinGap = (ctx.targetProtein - ctx.consumedProtein).clamp(0, ctx.targetProtein);
  final waterGelas = (ctx.consumedWaterMl / 250).floor();
  final targetGelas = (ctx.targetWater / 250).round();

  if (ctx.consumedCalories == 0) {
    return (
      title: '📵 Tidak Ada Catatan Hari Ini',
      body: 'Hari hampir selesai tapi belum ada makanan tercatat.',
    );
  }
  if (pct >= 0.9 && pct <= 1.1) {
    return (
      title: '🎯 Target Kalori Hampir Sempurna!',
      body: '${ctx.consumedCalories}/${ctx.targetCalories} kcal.',
    );
  }
  if (pct < 0.75) {
    if (ctx.goal == 'Cutting') {
      return (
        title: '✂️ Defisit Tercapai, ${ctx.name.split(" ").first}!',
        body: 'Hanya ${ctx.consumedCalories} kcal hari ini.',
      );
    }
    return (
      title: '⚠️ Kalori Masih Kurang $remaining kcal',
      body: 'Baru ${ctx.consumedCalories} dari ${ctx.targetCalories} kcal.',
    );
  }
  if (pct > 1.15) {
    return (
      title: '🚨 Kalori Melebihi Target',
      body: '${ctx.consumedCalories} kcal melebihi target.',
    );
  }
  if (waterGelas < targetGelas - 2) {
    return (
      title: '💧 Minum Air Dulu Sebelum Tidur!',
      body: 'Baru $waterGelas/$targetGelas gelas hari ini.',
    );
  }
  return (
    title: '📊 Evaluasi Hari Ini',
    body: '${ctx.consumedCalories}/${ctx.targetCalories} kcal | '
        '${ctx.consumedProtein}/${ctx.targetProtein}g protein.',
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {

  // ─── Morning message ───────────────────────────────────────────────────────

  group('morningMessage', () {
    test('Streak ≥7 → pesan streak (override goal)', () {
      final ctx = NotifContext(streak: 7, goal: 'Cutting');
      final msg = morningMessage(ctx);
      expect(msg.title, contains('Streak'));
      expect(msg.title, contains('7'));
    });

    test('Streak <7, Bulking → pesan bulking', () {
      final msg = morningMessage(NotifContext(goal: 'Bulking'));
      expect(msg.title, contains('Pagi'));
      expect(msg.body, contains('protein'));
    });

    test('Streak <7, Cutting → pesan defisit', () {
      final msg = morningMessage(NotifContext(goal: 'Cutting'));
      expect(msg.title, contains('Defisit').or(contains('Jaga')));
    });

    test('Streak <7, Maintenance → pesan default', () {
      final msg = morningMessage(NotifContext(goal: 'Maintenance'));
      expect(msg.title, isNotEmpty);
      expect(msg.body, isNotEmpty);
    });

    test('Nama multi-kata hanya pakai nama depan', () {
      final ctx = NotifContext(name: 'Budi Santoso');
      final msg = morningMessage(ctx);
      expect(msg.title, contains('Budi'));
      expect(msg.title, isNot(contains('Santoso')));
    });

    test('Semua pesan non-empty', () {
      for (final goal in ['Bulking', 'Cutting', 'Maintenance']) {
        for (final streak in [0, 3, 7, 30]) {
          final msg = morningMessage(NotifContext(goal: goal, streak: streak));
          expect(msg.title, isNotEmpty);
          expect(msg.body, isNotEmpty);
        }
      }
    });
  });

  // ─── Afternoon message ────────────────────────────────────────────────────

  group('afternoonMessage', () {
    test('Kalori 0 → pesan belum catat', () {
      final msg = afternoonMessage(NotifContext(consumedCalories: 0));
      expect(msg.title, contains('Belum Ada Catatan'));
    });

    test('40-65% target → pesan progress bagus', () {
      // 40% dari 2500 = 1000
      final msg = afternoonMessage(NotifContext(consumedCalories: 1000));
      expect(msg.title, contains('Bagus').or(contains('Progress')));
    });

    test('>65% target di siang hari → pesan peringatan tinggi', () {
      // 70% dari 2500 = 1750
      final msg = afternoonMessage(NotifContext(consumedCalories: 1750));
      expect(msg.title, contains('Perhatian').or(contains('Tinggi')));
    });

    test('Air < 3 gelas → pesan minum air', () {
      // Kalori rendah (10% target), air < 3 gelas (500ml = 2 gelas)
      final msg = afternoonMessage(NotifContext(
        consumedCalories: 250,
        consumedWaterMl: 500,
      ));
      expect(msg.title, contains('Air'));
    });

    test('Default → pesan cek progress', () {
      // Kalori 30% target, air cukup (4 gelas)
      final msg = afternoonMessage(NotifContext(
        consumedCalories: 750,
        consumedWaterMl: 1000,
      ));
      expect(msg.title, isNotEmpty);
      expect(msg.body, isNotEmpty);
    });
  });

  // ─── Evening message ──────────────────────────────────────────────────────

  group('eveningMessage', () {
    test('Kalori 0 → pesan tidak ada catatan', () {
      final msg = eveningMessage(NotifContext(consumedCalories: 0));
      expect(msg.title, contains('Tidak Ada Catatan'));
    });

    test('90-110% target → pesan hampir sempurna', () {
      // 95% dari 2500 = 2375
      final msg = eveningMessage(NotifContext(consumedCalories: 2375));
      expect(msg.title, contains('Sempurna').or(contains('Target')));
    });

    test('<75% target + Cutting → pesan defisit tercapai (positif)', () {
      final msg = eveningMessage(NotifContext(
        consumedCalories: 1500, // 60% dari 2500
        goal: 'Cutting',
      ));
      expect(msg.title, contains('Defisit'));
    });

    test('<75% target + Bulking → pesan kalori kurang (negatif)', () {
      final msg = eveningMessage(NotifContext(
        consumedCalories: 1500,
        goal: 'Bulking',
      ));
      expect(msg.title, contains('Kurang'));
    });

    test('>115% target → pesan kalori melebihi', () {
      // 120% dari 2500 = 3000
      final msg = eveningMessage(NotifContext(consumedCalories: 3000));
      expect(msg.title, contains('Melebihi'));
    });

    test('Air sangat kurang di malam hari → pesan minum air', () {
      // 90% kalori OK, air hanya 500ml (2 gelas dari 16 target)
      final msg = eveningMessage(NotifContext(
        consumedCalories: 2250,
        consumedWaterMl: 500,
      ));
      expect(msg.title, contains('Air'));
    });

    test('Default (on-track semua) → pesan evaluasi positif', () {
      final msg = eveningMessage(NotifContext(
        consumedCalories: 2000, // 80% — lebih dari 75%, kurang dari 90%
        consumedWaterMl: 3000,  // 12 gelas — targetGelas=16, gap=4 (bukan <targetGelas-2=14)
        hasWorkoutToday: true,
      ));
      expect(msg.title, isNotEmpty);
      expect(msg.body, isNotEmpty);
    });

    test('Semua skenario goal × progress menghasilkan pesan non-empty', () {
      final scenarios = [
        (cal: 0,    goal: 'Bulking'),
        (cal: 1500, goal: 'Bulking'),
        (cal: 1500, goal: 'Cutting'),
        (cal: 2375, goal: 'Bulking'),
        (cal: 3000, goal: 'Maintenance'),
        (cal: 2000, goal: 'Maintenance'),
      ];
      for (final s in scenarios) {
        final msg = eveningMessage(NotifContext(
          consumedCalories: s.cal,
          goal: s.goal,
        ));
        expect(msg.title, isNotEmpty,
            reason: 'cal=${s.cal}, goal=${s.goal} → title kosong');
        expect(msg.body, isNotEmpty,
            reason: 'cal=${s.cal}, goal=${s.goal} → body kosong');
      }
    });
  });

  // ─── Edge cases ───────────────────────────────────────────────────────────

  group('Edge cases', () {
    test('targetCalories = 0 tidak crash', () {
      final ctx = NotifContext(targetCalories: 0, consumedCalories: 0);
      expect(() => eveningMessage(ctx), returnsNormally);
    });

    test('consumedCalories > targetCalories tidak crash', () {
      final ctx = NotifContext(
          targetCalories: 2000, consumedCalories: 5000);
      expect(() => eveningMessage(ctx), returnsNormally);
    });

    test('consumedWaterMl > targetWater tidak crash', () {
      final ctx = NotifContext(
          targetWater: 4000, consumedWaterMl: 8000, consumedCalories: 2000);
      expect(() => afternoonMessage(ctx), returnsNormally);
    });
  });
}

// ── Matcher helper ────────────────────────────────────────────────────────────

extension StringMatcherExt on Matcher {
  Matcher or(Matcher other) => anyOf([this, other]);
}
