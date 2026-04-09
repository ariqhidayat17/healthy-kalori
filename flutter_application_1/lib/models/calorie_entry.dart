class CalorieEntry {
  final int? id;
  final String date;
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;

  CalorieEntry({
    this.id,
    required this.date,
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };
  }

  factory CalorieEntry.fromMap(Map<String, dynamic> map) {
    return CalorieEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      foodName: map['foodName'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as int? ?? 0,
      carbs: map['carbs'] as int? ?? 0,
      fats: map['fats'] as int? ?? 0,
    );
  }
}
