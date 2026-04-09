class UserProfile {
  final String name;
  final int age;
  final double weight; // dalam kg
  final double height; // dalam cm
  final String gender;
  final String activityLevel; // ringan, sedang, berat
  final String goal; // bulking, cutting, maintenance
  
  UserProfile({
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });

  // Menghitung BMR (Basal Metabolic Rate) menggunakan rumus Harris-Benedict
  double calculateBMR() {
    if (gender == 'Pria') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  // Faktor aktivitas
  double getActivityFactor() {
    switch (activityLevel) {
      case 'Ringan':
        return 1.375;
      case 'Sedang':
        return 1.55;
      case 'Berat':
        return 1.725;
      case 'Sangat Berat':
        return 1.9;
      default:
        return 1.2; // Sedentary
    }
  }
}