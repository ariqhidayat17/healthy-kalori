class CalorieEntry {
  final int? id;
  final String date;
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final String mealTime; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  final String rarity;   // 'Common', 'Rare', 'Epic', 'Legendary'

  CalorieEntry({
    this.id,
    required this.date,
    required this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fats = 0,
    this.mealTime = 'Breakfast',
    this.rarity = 'Common',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'mealTime': mealTime,
      'rarity': rarity,
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
      mealTime: map['mealTime'] as String? ?? 'Breakfast',
      rarity: map['rarity'] as String? ?? 'Common',
    );
  }
}
