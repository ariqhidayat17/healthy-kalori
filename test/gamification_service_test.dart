import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_calories/services/gamification_service.dart';

/// Test untuk GamificationService.
///
/// Method yang bergantung PrefsService (addXP, getCurrentXP, getUserStats)
/// tidak di-test di sini karena memerlukan SharedPreferences mock —
/// itu masuk integration test. Di sini kita test pure logic:
/// getCurrentRank, getRankProgress, determineFoodRarity, getCurrentLevel.
void main() {
  late GamificationService service;

  setUp(() => service = GamificationService());

  // ─── getCurrentRank ───────────────────────────────────────────────────────

  group('getCurrentRank', () {
    test('0 XP → Bronze', () {
      expect(service.getCurrentRank(0), equals('Bronze'));
    });

    test('499 XP → masih Bronze', () {
      expect(service.getCurrentRank(499), equals('Bronze'));
    });

    test('500 XP → Silver', () {
      expect(service.getCurrentRank(500), equals('Silver'));
    });

    test('1499 XP → masih Silver', () {
      expect(service.getCurrentRank(1499), equals('Silver'));
    });

    test('1500 XP → Gold', () {
      expect(service.getCurrentRank(1500), equals('Gold'));
    });

    test('2999 XP → masih Gold', () {
      expect(service.getCurrentRank(2999), equals('Gold'));
    });

    test('3000 XP → Diamond', () {
      expect(service.getCurrentRank(3000), equals('Diamond'));
    });

    test('4999 XP → masih Diamond', () {
      expect(service.getCurrentRank(4999), equals('Diamond'));
    });

    test('5000 XP → Spartan', () {
      expect(service.getCurrentRank(5000), equals('Spartan'));
    });

    test('XP sangat tinggi → Spartan', () {
      expect(service.getCurrentRank(99999), equals('Spartan'));
    });
  });

  // ─── getRankProgress ──────────────────────────────────────────────────────

  group('getRankProgress', () {
    test('Bronze: min=0, max=500', () {
      final p = service.getRankProgress(250);
      expect(p['min_xp'], equals(0));
      expect(p['max_xp'], equals(500));
      expect(p['current_xp'], equals(250));
    });

    test('Silver: min=500, max=1500', () {
      final p = service.getRankProgress(1000);
      expect(p['min_xp'], equals(500));
      expect(p['max_xp'], equals(1500));
    });

    test('Gold: min=1500, max=3000', () {
      final p = service.getRankProgress(2000);
      expect(p['min_xp'], equals(1500));
      expect(p['max_xp'], equals(3000));
    });

    test('Diamond: min=3000, max=5000', () {
      final p = service.getRankProgress(4000);
      expect(p['min_xp'], equals(3000));
      expect(p['max_xp'], equals(5000));
    });

    test('Spartan: min=5000, max=current (tidak ada next rank)', () {
      final p = service.getRankProgress(7000);
      expect(p['min_xp'], equals(5000));
      expect(p['max_xp'], equals(7000)); // Spartan: max = current XP
    });

    test('Tepat di batas rank baru: XP=500 → Silver progress', () {
      final p = service.getRankProgress(500);
      expect(p['min_xp'], equals(500));
      expect(p['max_xp'], equals(1500));
    });
  });

  // ─── determineFoodRarity ─────────────────────────────────────────────────

  group('determineFoodRarity', () {
    test('0 kalori → Common (guard terhadap division by zero)', () {
      expect(GamificationService.determineFoodRarity(0, 30), equals('Common'));
    });

    test('Protein sangat tinggi (rasio > 0.6) → Legendary', () {
      // 200 kcal, 40g protein → (40*4)/200 = 0.8 > 0.6 → Legendary
      expect(GamificationService.determineFoodRarity(200, 40), equals('Legendary'));
    });

    test('Protein tinggi (rasio > 0.3 dan ≤ 0.6) → Epic', () {
      // 200 kcal, 20g protein → (20*4)/200 = 0.4 → Epic
      expect(GamificationService.determineFoodRarity(200, 20), equals('Epic'));
    });

    test('Protein sedang (rasio > 0.15 dan ≤ 0.3) → Rare', () {
      // 400 kcal, 15g protein → (15*4)/400 = 0.15 → tepat batas Rare
      expect(GamificationService.determineFoodRarity(400, 16), equals('Rare'));
    });

    test('Protein rendah (rasio ≤ 0.15) → Common', () {
      // 500 kcal, 5g protein → (5*4)/500 = 0.04 → Common
      expect(GamificationService.determineFoodRarity(500, 5), equals('Common'));
    });

    test('Makanan tinggi lemak rendah protein (fast food) → Common', () {
      // 600 kcal, 10g protein → (10*4)/600 ≈ 0.067 → Common
      expect(GamificationService.determineFoodRarity(600, 10), equals('Common'));
    });

    test('Dada ayam tanpa kulit → Epic atau Legendary', () {
      // ~165 kcal, 31g protein → (31*4)/165 ≈ 0.75 → Legendary
      expect(
        GamificationService.determineFoodRarity(165, 31),
        anyOf(equals('Legendary'), equals('Epic')),
      );
    });
  });

  // ─── getCurrentLevel ─────────────────────────────────────────────────────

  group('getCurrentLevel', () {
    test('0 XP → Level 1', () {
      expect(GamificationService.getCurrentLevel(0), equals(1));
    });

    test('149 XP → Level 1', () {
      expect(GamificationService.getCurrentLevel(149), equals(1));
    });

    test('150 XP → Level 2', () {
      expect(GamificationService.getCurrentLevel(150), equals(2));
    });

    test('300 XP → Level 3', () {
      expect(GamificationService.getCurrentLevel(300), equals(3));
    });

    test('5000 XP → Level 34', () {
      // (5000 / 150).floor() + 1 = 33 + 1 = 34
      expect(GamificationService.getCurrentLevel(5000), equals(34));
    });

    test('Level selalu ≥ 1', () {
      expect(GamificationService.getCurrentLevel(0), greaterThanOrEqualTo(1));
    });
  });

  // ─── rankThresholds ───────────────────────────────────────────────────────

  group('rankThresholds', () {
    test('Semua 5 rank terdefinisi', () {
      expect(GamificationService.rankThresholds.keys,
          containsAll(['Bronze', 'Silver', 'Gold', 'Diamond', 'Spartan']));
    });

    test('Threshold naik secara monoton', () {
      final thresholds = GamificationService.rankThresholds.values.toList();
      for (int i = 0; i < thresholds.length - 1; i++) {
        expect(thresholds[i + 1], greaterThan(thresholds[i]));
      }
    });

    test('Bronze dimulai dari 0', () {
      expect(GamificationService.rankThresholds['Bronze'], equals(0));
    });
  });
}
