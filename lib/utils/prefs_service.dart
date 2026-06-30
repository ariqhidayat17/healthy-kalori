import 'package:shared_preferences/shared_preferences.dart';

/// Singleton wrapper untuk SharedPreferences.
///
/// Ganti semua `SharedPreferences.getInstance()` di codebase dengan
/// `PrefsService.i` — cukup panggil [PrefsService.init()] sekali di [main()]
/// sebelum [runApp()], lalu akses via getter yang tersedia.
///
/// Manfaat:
/// - Tidak ada lagi await getInstance() tersebar di 36 tempat
/// - Semua key terdefinisi sebagai konstanta → tidak typo
/// - Mudah di-mock untuk unit testing
/// - Jika storage engine diganti, cukup edit file ini
class PrefsService {
  PrefsService._();
  static PrefsService? _instance;
  late SharedPreferences _prefs;

  /// Singleton instance. Panggil [init()] dulu sebelum mengakses ini.
  static PrefsService get i {
    assert(_instance != null, 'PrefsService belum diinisialisasi. Panggil PrefsService.init() di main().');
    return _instance!;
  }

  /// Inisialisasi — panggil sekali di main() sebelum runApp().
  static Future<void> init() async {
    if (_instance != null) return;
    _instance = PrefsService._();
    _instance!._prefs = await SharedPreferences.getInstance();
  }

  // ─── Keys ────────────────────────────────────────────────────────────────
  static const kHasProfile          = 'has_profile';
  static const kHasSeenOnboarding   = 'has_seen_onboarding';
  static const kName                = 'name';
  static const kAge                 = 'age';
  static const kWeight              = 'weight';
  static const kHeight              = 'height';
  static const kGender              = 'gender';
  static const kActivityLevel       = 'activity_level';
  static const kGoal                = 'goal';
  static const kTargetCalories      = 'target_calories';
  static const kTargetProtein       = 'target_protein';
  static const kTargetCarbs         = 'target_carbs';
  static const kTargetFats          = 'target_fats';
  static const kTargetWater         = 'target_water';
  static const kNotificationsEnabled = 'notifications_enabled';
  static const kWorkoutStreak       = 'workout_streak';
  static const kLastWorkoutDate     = 'last_workout_date';
  static const kLastWrapupDate      = 'last_wrapup_date';
  static const kAppOpenCount        = 'app_open_count';
  static const kShowPerfOverlay     = 'show_performance_overlay';
  static const kProgressPhotos      = 'progress_photos';
  static const kProgressPin         = 'progress_pin';
  static const kAiChatHistory       = 'ai_chat_history';
  static const kUserXP              = 'user_xp';
  static const kUserLevel           = 'user_level';

  // ─── Akses langsung ke _prefs (untuk operasi custom) ─────────────────────
  SharedPreferences get raw => _prefs;

  // ─── User Profile ─────────────────────────────────────────────────────────
  bool   get hasProfile        => _prefs.getBool(kHasProfile)        ?? false;
  bool   get hasSeenOnboarding => _prefs.getBool(kHasSeenOnboarding) ?? false;
  String get name              => _prefs.getString(kName)            ?? 'User';
  int    get age               => _prefs.getInt(kAge)                ?? 25;
  double get weight            => _prefs.getDouble(kWeight)          ?? 70.0;
  double get height            => _prefs.getDouble(kHeight)          ?? 170.0;
  String get gender            => _prefs.getString(kGender)          ?? 'Pria';
  String get activityLevel     => _prefs.getString(kActivityLevel)   ?? 'Sedang';
  String get goal              => _prefs.getString(kGoal)            ?? 'Bulking';

  Future<void> saveProfile({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activityLevel,
    required String goal,
  }) async {
    await _prefs.setBool(kHasProfile, true);
    await _prefs.setString(kName, name);
    await _prefs.setInt(kAge, age);
    await _prefs.setDouble(kWeight, weight);
    await _prefs.setDouble(kHeight, height);
    await _prefs.setString(kGender, gender);
    await _prefs.setString(kActivityLevel, activityLevel);
    await _prefs.setString(kGoal, goal);
  }

  // ─── Targets ──────────────────────────────────────────────────────────────
  int get targetCalories => _prefs.getInt(kTargetCalories) ?? 2000;
  int get targetProtein  => _prefs.getInt(kTargetProtein)  ?? 150;
  int get targetCarbs    => _prefs.getInt(kTargetCarbs)    ?? 200;
  int get targetFats     => _prefs.getInt(kTargetFats)     ?? 65;
  int get targetWater    => _prefs.getInt(kTargetWater)    ?? 4000;

  Future<void> setTargetCalories(int v) => _prefs.setInt(kTargetCalories, v);
  Future<void> setTargetProtein(int v)  => _prefs.setInt(kTargetProtein, v);
  Future<void> setTargetCarbs(int v)    => _prefs.setInt(kTargetCarbs, v);
  Future<void> setTargetFats(int v)     => _prefs.setInt(kTargetFats, v);
  Future<void> setTargetWater(int v)    => _prefs.setInt(kTargetWater, v);

  // ─── Settings ─────────────────────────────────────────────────────────────
  bool get notificationsEnabled => _prefs.getBool(kNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool v) => _prefs.setBool(kNotificationsEnabled, v);

  bool get showPerfOverlay => _prefs.getBool(kShowPerfOverlay) ?? false;
  Future<void> setShowPerfOverlay(bool v) => _prefs.setBool(kShowPerfOverlay, v);

  // ─── Workout / Streak ─────────────────────────────────────────────────────
  int    get workoutStreak    => _prefs.getInt(kWorkoutStreak)       ?? 0;
  String get lastWorkoutDate  => _prefs.getString(kLastWorkoutDate)  ?? '';
  Future<void> setWorkoutStreak(int v)       => _prefs.setInt(kWorkoutStreak, v);
  Future<void> setLastWorkoutDate(String v)  => _prefs.setString(kLastWorkoutDate, v);

  // ─── App meta ─────────────────────────────────────────────────────────────
  int    get appOpenCount     => _prefs.getInt(kAppOpenCount)        ?? 0;
  String get lastWrapupDate   => _prefs.getString(kLastWrapupDate)   ?? '';
  Future<void> setAppOpenCount(int v)    => _prefs.setInt(kAppOpenCount, v);
  Future<void> setLastWrapupDate(String v) => _prefs.setString(kLastWrapupDate, v);
  Future<void> setHasSeenOnboarding(bool v) => _prefs.setBool(kHasSeenOnboarding, v);

  // ─── Progress Photos & PIN ────────────────────────────────────────────────
  String? get progressPhotosJson => _prefs.getString(kProgressPhotos);
  String? get progressPin        => _prefs.getString(kProgressPin);
  Future<void> setProgressPhotosJson(String v) => _prefs.setString(kProgressPhotos, v);
  Future<void> setProgressPin(String v)        => _prefs.setString(kProgressPin, v);

  // ─── AI Chat ──────────────────────────────────────────────────────────────
  String? get aiChatHistory => _prefs.getString(kAiChatHistory);
  Future<void> setAiChatHistory(String v) => _prefs.setString(kAiChatHistory, v);
  Future<void> clearAiChatHistory()       => _prefs.remove(kAiChatHistory);

  // ─── Gamification ─────────────────────────────────────────────────────────
  int    get userXP    => _prefs.getInt(kUserXP)       ?? 0;
  String get userLevel => _prefs.getString(kUserLevel) ?? 'Bronze';
  Future<void> setUserXP(int v)       => _prefs.setInt(kUserXP, v);
  Future<void> setUserLevel(String v) => _prefs.setString(kUserLevel, v);

  // ─── Mission (dynamic keys) ───────────────────────────────────────────────
  bool   getMissionDone(String key)       => _prefs.getBool(key)  ?? false;
  Future<void> setMissionDone(String key) => _prefs.setBool(key, true);

  // ─── Generic (untuk key dinamis yang tidak masuk kategori di atas) ────────
  String?  getString(String key)                 => _prefs.getString(key);
  int?     getInt(String key)                    => _prefs.getInt(key);
  double?  getDouble(String key)                 => _prefs.getDouble(key);
  bool?    getBool(String key)                   => _prefs.getBool(key);
  Future<void> setString(String key, String v)   => _prefs.setString(key, v);
  Future<void> setInt(String key, int v)         => _prefs.setInt(key, v);
  Future<void> setDouble(String key, double v)   => _prefs.setDouble(key, v);
  Future<void> setBool(String key, bool v)       => _prefs.setBool(key, v);
  Future<void> remove(String key)                => _prefs.remove(key);
}
