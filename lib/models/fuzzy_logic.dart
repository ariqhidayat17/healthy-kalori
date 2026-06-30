import '../models/user_profile.dart';

/// Fuzzy Logic untuk menghitung target kalori harian.
///
/// Perubahan dari versi sebelumnya:
/// - Adjustment aktivitas tinggi kini mempertimbangkan goal user.
///   Sebelumnya +200 kcal selalu diterapkan terlepas dari goal,
///   sehingga user Cutting + Sangat Berat mendapat kalori ekstra
///   yang kontraproduktif terhadap tujuan defisit kalorinya.
///
/// Logika baru:
///   Bulking      → +200 kcal (butuh surplus untuk muscle gain)
///   Maintenance  → +100 kcal (imbangi pembakaran ekstra)
///   Cutting      → +50  kcal (perlunak defisit agar tidak kehilangan massa otot,
///                              tapi tetap dalam zona defisit)
class FuzzyLogic {
  // ── Fungsi keanggotaan BMI ──────────────────────────────────────────────

  double underweightMembership(double bmi) {
    if (bmi <= 18.5) return 1.0;
    if (bmi < 20) return (20 - bmi) / 1.5;
    return 0.0;
  }

  double normalWeightMembership(double bmi) {
    if (bmi <= 18.5) return 0.0;
    if (bmi < 20) return (bmi - 18.5) / 1.5;
    if (bmi <= 25) return 1.0;
    if (bmi < 27) return (27 - bmi) / 2;
    return 0.0;
  }

  double overweightMembership(double bmi) {
    if (bmi <= 25) return 0.0;
    if (bmi < 27) return (bmi - 25) / 2;
    return 1.0;
  }

  // ── Fungsi keanggotaan aktivitas ────────────────────────────────────────

  double lowActivityMembership(String activityLevel) {
    if (activityLevel == 'Ringan') return 1.0;
    if (activityLevel == 'Sedang') return 0.5;
    return 0.0;
  }

  double mediumActivityMembership(String activityLevel) {
    if (activityLevel == 'Ringan') return 0.3;
    if (activityLevel == 'Sedang') return 1.0;
    if (activityLevel == 'Berat') return 0.3;
    return 0.0;
  }

  double highActivityMembership(String activityLevel) {
    if (activityLevel == 'Sedang') return 0.5;
    if (activityLevel == 'Berat' || activityLevel == 'Sangat Berat') return 1.0;
    return 0.0;
  }

  // ── Kalkulasi utama ─────────────────────────────────────────────────────

  int calculateCalories(UserProfile profile) {
    final double bmr = profile.calculateBMR();
    final double activityFactor = profile.getActivityFactor();
    final double tdee = bmr * activityFactor;

    final double bmi =
        profile.weight / ((profile.height / 100) * (profile.height / 100));

    final double underweight  = underweightMembership(bmi);
    final double normal       = normalWeightMembership(bmi);
    final double overweight   = overweightMembership(bmi);
    final double highActivity = highActivityMembership(profile.activityLevel);

    double calorieAdjustment = 0;

    // ── Rule 1: Penyesuaian berdasarkan BMI × Goal ──────────────────────
    switch (profile.goal) {
      case 'Bulking':
        // Ingin menambah massa → surplus kalori, lebih besar jika underweight
        calorieAdjustment += underweight * 500;
        calorieAdjustment += normal      * 300;
        calorieAdjustment += overweight  * 100;
        break;

      case 'Cutting':
        // Ingin membakar lemak → defisit kalori, lebih besar jika overweight
        calorieAdjustment -= underweight * 100; // Defisit kecil, jaga otot
        calorieAdjustment -= normal      * 300;
        calorieAdjustment -= overweight  * 500; // Defisit besar
        break;

      default: // Maintenance
        calorieAdjustment += underweight *  100;
        calorieAdjustment += overweight  * -100;
        break;
    }

    // ── Rule 2: Penyesuaian aktivitas tinggi (goal-aware) ──────────────
    //
    // SEBELUMNYA: highActivity * 200 diterapkan tanpa melihat goal →
    //   user Cutting + Sangat Berat mendapat +200 kcal di atas defisit,
    //   yang mengurangi atau bahkan membalik efek cutting.
    //
    // SEKARANG: bonus aktivitas disesuaikan per goal:
    //   • Bulking     → +200 kcal (penuh, perlu surplus untuk recovery & growth)
    //   • Maintenance → +100 kcal (imbangi pembakaran ekstra)
    //   • Cutting     → +50  kcal (sedikit perlunak defisit untuk jaga massa otot,
    //                               tapi defisit neto tetap terjaga)
    final double activityBonus = switch (profile.goal) {
      'Bulking'     => highActivity * 200,
      'Cutting'     => highActivity * 50,
      _             => highActivity * 100, // Maintenance
    };

    calorieAdjustment += activityBonus;

    // Batas bawah: tidak boleh di bawah BMR (berbahaya secara medis)
    final int result = (tdee + calorieAdjustment).round();
    return result < bmr.round() ? bmr.round() : result;
  }
}
