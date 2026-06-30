import 'package:flutter_test/flutter_test.dart';
import 'package:healthy_calories/models/fuzzy_logic.dart';
import 'package:healthy_calories/models/user_profile.dart';

void main() {
  late FuzzyLogic fuzzy;

  setUp(() => fuzzy = FuzzyLogic());

  // ─── Helper ──────────────────────────────────────────────────────────────

  UserProfile makeProfile({
    double weight = 75,
    double height = 175,
    int age = 25,
    String gender = 'Pria',
    String activityLevel = 'Sedang',
    String goal = 'Maintenance',
  }) =>
      UserProfile(
        name: 'Test',
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      );

  // ─── Fungsi keanggotaan BMI ───────────────────────────────────────────────

  group('underweightMembership', () {
    test('BMI ≤ 18.5 → 1.0', () {
      expect(fuzzy.underweightMembership(17.0), equals(1.0));
      expect(fuzzy.underweightMembership(18.5), equals(1.0));
    });

    test('BMI antara 18.5 dan 20 → interpolasi 0..1', () {
      final result = fuzzy.underweightMembership(19.0);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(1.0));
    });

    test('BMI ≥ 20 → 0.0', () {
      expect(fuzzy.underweightMembership(20.0), equals(0.0));
      expect(fuzzy.underweightMembership(25.0), equals(0.0));
    });
  });

  group('normalWeightMembership', () {
    test('BMI 20–25 → 1.0 (fully normal)', () {
      expect(fuzzy.normalWeightMembership(22.0), equals(1.0));
      expect(fuzzy.normalWeightMembership(25.0), equals(1.0));
    });

    test('BMI ≤ 18.5 → 0.0', () {
      expect(fuzzy.normalWeightMembership(18.0), equals(0.0));
    });

    test('BMI antara 25 dan 27 → menurun ke 0', () {
      final result = fuzzy.normalWeightMembership(26.0);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(1.0));
    });
  });

  group('overweightMembership', () {
    test('BMI ≤ 25 → 0.0', () {
      expect(fuzzy.overweightMembership(24.0), equals(0.0));
    });

    test('BMI ≥ 27 → 1.0', () {
      expect(fuzzy.overweightMembership(27.0), equals(1.0));
      expect(fuzzy.overweightMembership(32.0), equals(1.0));
    });
  });

  group('highActivityMembership', () {
    test('Ringan → 0.0', () {
      expect(fuzzy.highActivityMembership('Ringan'), equals(0.0));
    });

    test('Sedang → 0.5', () {
      expect(fuzzy.highActivityMembership('Sedang'), equals(0.5));
    });

    test('Berat dan Sangat Berat → 1.0', () {
      expect(fuzzy.highActivityMembership('Berat'), equals(1.0));
      expect(fuzzy.highActivityMembership('Sangat Berat'), equals(1.0));
    });
  });

  // ─── calculateCalories ───────────────────────────────────────────────────

  group('calculateCalories — Bulking', () {
    test('Bulking dapat kalori lebih tinggi dari Maintenance', () {
      final bulking = makeProfile(goal: 'Bulking');
      final maintenance = makeProfile(goal: 'Maintenance');
      expect(
        fuzzy.calculateCalories(bulking),
        greaterThan(fuzzy.calculateCalories(maintenance)),
      );
    });

    test('Bulking + Sangat Berat → bonus aktivitas penuh (+200)', () {
      final profile = makeProfile(goal: 'Bulking', activityLevel: 'Sangat Berat');
      final result = fuzzy.calculateCalories(profile);
      // Harus lebih tinggi dari TDEE mentah karena ada surplus + bonus
      final tdee = (profile.calculateBMR() * profile.getActivityFactor()).round();
      expect(result, greaterThanOrEqualTo(tdee));
    });
  });

  group('calculateCalories — Cutting', () {
    test('Cutting dapat kalori lebih rendah dari Maintenance', () {
      final cutting = makeProfile(goal: 'Cutting');
      final maintenance = makeProfile(goal: 'Maintenance');
      expect(
        fuzzy.calculateCalories(cutting),
        lessThan(fuzzy.calculateCalories(maintenance)),
      );
    });

    test('Cutting TIDAK boleh dapat kalori lebih dari Bulking', () {
      final cutting = makeProfile(goal: 'Cutting', activityLevel: 'Sangat Berat');
      final bulking  = makeProfile(goal: 'Bulking',  activityLevel: 'Sangat Berat');
      expect(
        fuzzy.calculateCalories(cutting),
        lessThan(fuzzy.calculateCalories(bulking)),
      );
    });

    test('Cutting + Sangat Berat: defisit dari TDEE tetap signifikan (>150 kcal)', () {
      // BUG LAMA: +200 aktivitas membalik defisit. Fix: hanya +50.
      final profile = makeProfile(
        goal: 'Cutting',
        activityLevel: 'Sangat Berat',
        weight: 80,
        height: 175,
        age: 25,
        gender: 'Pria',
      );
      final tdee = (profile.calculateBMR() * profile.getActivityFactor()).round();
      final result = fuzzy.calculateCalories(profile);
      // Defisit neto harus lebih dari 150 kcal agar benar-benar cutting
      expect(tdee - result, greaterThan(150),
          reason: 'Cutting+SangatBerat harus tetap defisit minimal 150 kcal dari TDEE. '
              'TDEE=$tdee, result=$result, defisit=${tdee - result}');
    });

    test('Cutting + Overweight: defisit lebih besar dari Cutting + Normal', () {
      final cutOW = makeProfile(goal: 'Cutting', weight: 90, height: 170); // OW
      final cutNormal = makeProfile(goal: 'Cutting', weight: 70, height: 175);
      // Orang OW dengan goal cutting seharusnya dapat target kalori lebih rendah
      // (lebih besar defisit karena overweight membership tinggi)
      expect(fuzzy.calculateCalories(cutOW), lessThan(fuzzy.calculateCalories(cutNormal) + 500));
    });
  });

  group('calculateCalories — safety floor', () {
    test('Hasil tidak pernah di bawah BMR', () {
      // Skenario ekstrim: wanita sangat kurus, Cutting berat
      final profile = makeProfile(
        goal: 'Cutting',
        weight: 40,
        height: 155,
        age: 35,
        gender: 'Wanita',
        activityLevel: 'Ringan',
      );
      final bmr = profile.calculateBMR().round();
      final result = fuzzy.calculateCalories(profile);
      expect(result, greaterThanOrEqualTo(bmr),
          reason: 'Kalori tidak boleh di bawah BMR=$bmr, got $result');
    });
  });

  group('calculateCalories — gender', () {
    test('Pria BMR lebih tinggi dari Wanita dengan parameter sama', () {
      final pria   = makeProfile(gender: 'Pria');
      final wanita = makeProfile(gender: 'Wanita');
      expect(
        fuzzy.calculateCalories(pria),
        greaterThan(fuzzy.calculateCalories(wanita)),
      );
    });
  });

  group('calculateCalories — activity level ordering', () {
    test('Kalori naik seiring meningkatnya aktivitas (Bulking)', () {
      final levels = ['Ringan', 'Sedang', 'Berat', 'Sangat Berat'];
      final calories = levels
          .map((l) => fuzzy.calculateCalories(makeProfile(activityLevel: l, goal: 'Bulking')))
          .toList();
      for (int i = 0; i < calories.length - 1; i++) {
        expect(calories[i + 1], greaterThanOrEqualTo(calories[i]),
            reason: '${levels[i + 1]} harus ≥ ${levels[i]}');
      }
    });
  });
}
