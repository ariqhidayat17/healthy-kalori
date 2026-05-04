import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/database_helper.dart';
import 'calorie_entry.dart';

class CalorieProvider extends ChangeNotifier {
  List<CalorieEntry> _entries = [];
  int _totalConsumedCalories = 0;
  int _totalConsumedProtein = 0;
  int _totalConsumedCarbs = 0;
  int _totalConsumedFats = 0;
  int _totalConsumedWater = 0; // in ml
  
  // Target Kalori & Makro
  int _targetCalories = 2000;
  int _targetProtein = 150;
  int _targetCarbs = 200;
  int _targetFats = 65;
  int _targetWater = 4000; // default 4000 ml
  
  List<CalorieEntry> get entries => _entries;
  int get totalConsumedCalories => _totalConsumedCalories;
  int get totalConsumedProtein => _totalConsumedProtein;
  int get totalConsumedCarbs => _totalConsumedCarbs;
  int get totalConsumedFats => _totalConsumedFats;
  int get totalConsumedWater => _totalConsumedWater;
  
  int get targetCalories => _targetCalories;
  int get targetProtein => _targetProtein;
  int get targetCarbs => _targetCarbs;
  int get targetFats => _targetFats;
  int get targetWater => _targetWater;

  Future<void> calculateTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasProfile = prefs.getBool('has_profile') ?? false;
    
    if (!hasProfile) {
      _targetCalories = 2000;
      _targetProtein = 150;
      _targetCarbs = 200;
      _targetFats = 65;
      notifyListeners();
      return;
    }

    final double weight = prefs.getDouble('weight') ?? 70.0;
    final double height = prefs.getDouble('height') ?? 170.0;
    final int age = prefs.getInt('age') ?? 25;
    final String gender = prefs.getString('gender') ?? 'Pria';
    final String activityLevel = prefs.getString('activity_level') ?? 'Sedang';
    final String goal = prefs.getString('goal') ?? 'Bulking';

    // 1. Calculate BMR (Mifflin-St Jeor Equation)
    double bmr;
    if (gender == 'Pria') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 2. Activity Multiplier
    double multiplier = 1.2;
    switch (activityLevel) {
      case 'Ringan': multiplier = 1.375; break;
      case 'Sedang': multiplier = 1.55; break;
      case 'Berat': multiplier = 1.725; break;
      case 'Sangat Berat': multiplier = 1.9; break;
    }
    double tdee = bmr * multiplier;

    // 3. Goal Adjustment
    double targetKcal = tdee;
    if (goal == 'Bulking') {
      targetKcal += 300; // Surplus
    } else if (goal == 'Cutting') {
      targetKcal -= 500; // Defisit
    }
    
    _targetCalories = targetKcal.round();

    // 4. Macro Distribution (Protein 2.2g/kg, Fat 25%, rest Carbs)
    _targetProtein = (weight * 2.2).round(); // Bodybuilder rule of thumb
    _targetFats = ((_targetCalories * 0.25) / 9).round();
    
    // Remaining calories for carbs
    final proteinKcal = _targetProtein * 4;
    final fatsKcal = _targetFats * 9;
    final remainingKcal = _targetCalories - proteinKcal - fatsKcal;
    _targetCarbs = (remainingKcal > 0 ? remainingKcal / 4 : 0).round();

    notifyListeners();
  }

  Future<void> updateTargetWater(int target) async {
    final prefs = await SharedPreferences.getInstance();
    _targetWater = target;
    await prefs.setInt('target_water', target);
    notifyListeners();
  }

  Future<void> loadTodayCalories() async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    _entries = await DatabaseHelper.instance.getFoodsByDate(today);
    _totalConsumedCalories = await DatabaseHelper.instance.getTotalCaloriesByDate(today);
    
    final macros = await DatabaseHelper.instance.getTotalMacrosByDate(today);
    _totalConsumedProtein = macros['protein'] ?? 0;
    _totalConsumedCarbs = macros['carbs'] ?? 0;
    _totalConsumedFats = macros['fats'] ?? 0;
    
    final prefs = await SharedPreferences.getInstance();
    _totalConsumedWater = await DatabaseHelper.instance.getTotalWaterByDate(today);
    _targetWater = prefs.getInt('target_water') ?? 4000;
    
    await calculateTargets(); // Hitung ulang setiap load
  }

  Future<void> addFood(String foodName, int calories, {int protein = 0, int carbs = 0, int fats = 0}) async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final newEntry = CalorieEntry(
      date: today,
      foodName: foodName, 
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
    
    await DatabaseHelper.instance.insertFood(newEntry);
    await loadTodayCalories(); // Reload everything to update UI
  }

  Future<void> removeFood(int id) async {
    await DatabaseHelper.instance.deleteFood(id);
    await loadTodayCalories(); // Reload everything to update UI
  }

  Future<void> updateFood(CalorieEntry entry) async {
    await DatabaseHelper.instance.updateFood(entry);
    await loadTodayCalories();
  }


  Future<void> addWater(int amountInMl) async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    if (amountInMl > 0) {
      await DatabaseHelper.instance.insertWater(today, amountInMl);
    } else if (amountInMl < 0) {
      // Logic for undo/decrement
      await DatabaseHelper.instance.deleteLastWaterEntry(today);
    }
    
    await loadTodayCalories();
  }
}

