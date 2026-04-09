import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../utils/database_helper.dart';
import 'calorie_entry.dart';

class CalorieProvider extends ChangeNotifier {
  List<CalorieEntry> _entries = [];
  int _totalConsumedCalories = 0;
  int _totalConsumedProtein = 0;
  int _totalConsumedCarbs = 0;
  int _totalConsumedFats = 0;
  
  List<CalorieEntry> get entries => _entries;
  int get totalConsumedCalories => _totalConsumedCalories;
  int get totalConsumedProtein => _totalConsumedProtein;
  int get totalConsumedCarbs => _totalConsumedCarbs;
  int get totalConsumedFats => _totalConsumedFats;

  Future<void> loadTodayCalories() async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    _entries = await DatabaseHelper.instance.getFoodsByDate(today);
    _totalConsumedCalories = await DatabaseHelper.instance.getTotalCaloriesByDate(today);
    
    final macros = await DatabaseHelper.instance.getTotalMacrosByDate(today);
    _totalConsumedProtein = macros['protein'] ?? 0;
    _totalConsumedCarbs = macros['carbs'] ?? 0;
    _totalConsumedFats = macros['fats'] ?? 0;
    
    notifyListeners();
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
}
