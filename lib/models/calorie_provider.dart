import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../utils/database_helper.dart';
import '../utils/prefs_service.dart';
import '../services/smart_notification_service.dart';
import 'calorie_entry.dart';
import 'fuzzy_logic.dart';
import 'user_profile.dart';

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
    final p = PrefsService.i;
    if (!p.hasProfile) {
      _targetCalories = 2000;
      _targetProtein = 150;
      _targetCarbs = 200;
      _targetFats = 65;
      notifyListeners();
      return;
    }

    final profile = UserProfile(
      name: p.name,
      age: p.age,
      weight: p.weight,
      height: p.height,
      gender: p.gender,
      activityLevel: p.activityLevel,
      goal: p.goal,
    );

    final fuzzy = FuzzyLogic();
    _targetCalories = fuzzy.calculateCalories(profile);

    // Macro Distribution (Protein 2.2g/kg, Fat 25%, rest Carbs)
    _targetProtein = (p.weight * 2.2).round();
    _targetFats = ((_targetCalories * 0.25) / 9).round();

    final proteinKcal = _targetProtein * 4;
    final fatsKcal = _targetFats * 9;
    final remainingKcal = _targetCalories - proteinKcal - fatsKcal;
    _targetCarbs = (remainingKcal > 0 ? remainingKcal / 4 : 0).round();

    // Persist targets to SharedPreferences
    await p.setTargetCalories(_targetCalories);
    await p.setTargetProtein(_targetProtein);
    await p.setTargetCarbs(_targetCarbs);
    await p.setTargetFats(_targetFats);

    notifyListeners();
  }

  Future<void> updateTargetWater(int target) async {
    _targetWater = target;
    await PrefsService.i.setTargetWater(target);
    notifyListeners();
  }

  Future<void> loadTodayCalories() async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    _entries = await DatabaseHelper.instance.getFoodsByDate(today);
    _totalConsumedCalories =
        await DatabaseHelper.instance.getTotalCaloriesByDate(today);

    final macros = await DatabaseHelper.instance.getTotalMacrosByDate(today);
    _totalConsumedProtein = macros['protein'] ?? 0;
    _totalConsumedCarbs = macros['carbs'] ?? 0;
    _totalConsumedFats = macros['fats'] ?? 0;

    _totalConsumedWater =
        await DatabaseHelper.instance.getTotalWaterByDate(today);
    _targetWater = PrefsService.i.targetWater;

    await calculateTargets();
  }

  // ─── Optimistic UI: update state lokal dulu, DB di background ─────────────

  Future<void> addFood(
    String foodName,
    int calories, {
    int protein = 0,
    int carbs = 0,
    int fats = 0,
    String mealTime = 'Breakfast',
    String rarity = 'Common',
  }) async {
    // Validasi input: tolak nilai tidak wajar sebelum masuk ke database
    if (foodName.trim().isEmpty) return;
    if (calories <= 0 || calories > 9999) return;
    if (protein < 0 || protein > 999) return;
    if (carbs < 0 || carbs > 999) return;
    if (fats < 0 || fats > 999) return;

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final newEntry = CalorieEntry(
      date: today,
      foodName: foodName,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
      mealTime: mealTime,
      rarity: rarity,
    );

    // 1. Update state lokal dulu → UI langsung responsif
    _entries = [..._entries, newEntry];
    _totalConsumedCalories += calories;
    _totalConsumedProtein += protein;
    _totalConsumedCarbs += carbs;
    _totalConsumedFats += fats;
    notifyListeners();

    // 2. Simpan ke DB di background, lalu sync ulang id yang di-generate DB
    await DatabaseHelper.instance.insertFood(newEntry);
    await _syncTodayFromDB(today);

    // 3. Refresh notifikasi agar pesan malam mencerminkan data terkini
    SmartNotificationService.refreshAndReschedule();
  }

  Future<void> removeFood(int id) async {
    // 1. Update state lokal dulu
    final removed = _entries.firstWhere(
      (e) => e.id == id,
      orElse: () => CalorieEntry(
        date: '', foodName: '', calories: 0,
        protein: 0, carbs: 0, fats: 0,
      ),
    );
    if (removed.id != null) {
      _entries = _entries.where((e) => e.id != id).toList();
      _totalConsumedCalories =
          (_totalConsumedCalories - removed.calories).clamp(0, 99999);
      _totalConsumedProtein =
          (_totalConsumedProtein - removed.protein).clamp(0, 9999);
      _totalConsumedCarbs =
          (_totalConsumedCarbs - removed.carbs).clamp(0, 9999);
      _totalConsumedFats =
          (_totalConsumedFats - removed.fats).clamp(0, 9999);
      notifyListeners();
    }

    // 2. Hapus dari DB & sync ulang untuk konsistensi
    await DatabaseHelper.instance.deleteFood(id);
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    await _syncTodayFromDB(today);
  }

  Future<void> updateFood(CalorieEntry entry) async {
    await DatabaseHelper.instance.updateFood(entry);
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    await _syncTodayFromDB(today);
  }

  Future<void> addWater(int amountInMl) async {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    if (amountInMl > 0) {
      // Optimistic update
      _totalConsumedWater += amountInMl;
      notifyListeners();
      await DatabaseHelper.instance.insertWater(today, amountInMl);
    } else if (amountInMl < 0) {
      await DatabaseHelper.instance.deleteLastWaterEntry(today);
      _totalConsumedWater =
          await DatabaseHelper.instance.getTotalWaterByDate(today);
      notifyListeners();
    }

    // Refresh notifikasi air berdasarkan data terkini
    SmartNotificationService.refreshAndReschedule();
  }

  /// Sync entries & total makro dari DB (dipanggil setelah write selesai).
  /// Lebih ringan dari loadTodayCalories() karena tidak memanggil
  /// calculateTargets() ulang.
  Future<void> _syncTodayFromDB(String today) async {
    _entries = await DatabaseHelper.instance.getFoodsByDate(today);
    _totalConsumedCalories =
        await DatabaseHelper.instance.getTotalCaloriesByDate(today);
    final macros = await DatabaseHelper.instance.getTotalMacrosByDate(today);
    _totalConsumedProtein = macros['protein'] ?? 0;
    _totalConsumedCarbs = macros['carbs'] ?? 0;
    _totalConsumedFats = macros['fats'] ?? 0;
    notifyListeners();
  }
}
