import '../models/user_profile.dart';

class FuzzyLogic {
  // Fungsi keanggotaan untuk berat badan (underweight, normal, overweight)
  double underweightMembership(double bmi) {
    if (bmi <= 18.5) return 1.0;
    if (bmi > 18.5 && bmi < 20) return (20 - bmi) / 1.5;
    return 0.0;
  }

  double normalWeightMembership(double bmi) {
    if (bmi <= 18.5) return 0.0;
    if (bmi > 18.5 && bmi < 20) return (bmi - 18.5) / 1.5;
    if (bmi >= 20 && bmi <= 25) return 1.0;
    if (bmi > 25 && bmi < 27) return (27 - bmi) / 2;
    return 0.0;
  }

  double overweightMembership(double bmi) {
    if (bmi <= 25) return 0.0;
    if (bmi > 25 && bmi < 27) return (bmi - 25) / 2;
    if (bmi >= 27) return 1.0;
    return 0.0;
  }

  // Fungsi keanggotaan untuk aktivitas (low, medium, high)
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

  // Menghitung kalori berdasarkan logika fuzzy
  int calculateCalories(UserProfile profile) {
    double bmr = profile.calculateBMR();
    double activityFactor = profile.getActivityFactor();
    double tdee = bmr * activityFactor; // Total Daily Energy Expenditure

    // Hitung BMI
    double bmi =
        profile.weight / ((profile.height / 100) * (profile.height / 100));

    // Derajat keanggotaan
    double underweight = underweightMembership(bmi);
    double normal = normalWeightMembership(bmi);
    double overweight = overweightMembership(bmi);

    double highActivity = highActivityMembership(profile.activityLevel);

    // Aturan fuzzy untuk bodybuilder
    double calorieAdjustment = 0;

    // Rule 1: Jika underweight dan goal bulking, tambah kalori banyak
    if (profile.goal == 'Bulking') {
      calorieAdjustment += underweight * 500; // +500 kalori
      calorieAdjustment += normal * 300; // +300 kalori
      calorieAdjustment += overweight * 100; // +100 kalori
    }
    // Rule 2: Jika overweight dan goal cutting, kurangi kalori
    else if (profile.goal == 'Cutting') {
      calorieAdjustment -= underweight * 100; // -100 kalori
      calorieAdjustment -= normal * 300; // -300 kalori
      calorieAdjustment -= overweight * 500; // -500 kalori
    }
    // Rule 3: Jika normal dan goal maintenance
    else {
      calorieAdjustment += underweight * 100; // +100 kalori
      calorieAdjustment += overweight * (-100); // -100 kalori
    }

    // Adjustment berdasarkan aktivitas
    calorieAdjustment +=
        highActivity * 200; // Aktivitas tinggi butuh lebih banyak kalori

    return (tdee + calorieAdjustment).round();
  }
}
