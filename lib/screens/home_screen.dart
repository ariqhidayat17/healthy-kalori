import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_profile.dart';
import '../models/calorie_provider.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';

// Import Widgets Baru
import '../widgets/fantasy_card.dart';
import '../widgets/fantasy_calorie_ring.dart';
import '../widgets/macro_progress_card.dart';
import '../widgets/fantasy_rank_badge.dart';
import '../widgets/weight_tracker_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/workout_tracker_card.dart';
import '../widgets/animated_macro_bar.dart';
import '../utils/app_snackbar.dart';
import '../utils/database_helper.dart';
import '../services/gamification_service.dart';
import '../widgets/hero_stats_card.dart';
import '../widgets/streak_banner_widget.dart';
import '../widgets/weekly_insight_card.dart';
import '../services/streak_service.dart';
import 'stats_screen.dart';
import 'main_screen.dart';
import 'rank_progress_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  String _lastWorkoutDate = 'Belum ada data';
  int _streakDays = 0;
  
  // Gamification State
  int _currentXP = 0;
  int _currentLevel = 1;
  String _currentRank = 'Bronze';
  int _maxXP = 500;

  // Daily Quests State
  int _waterCups = 0;
  final int _targetWater = 8;
  bool _proteinClaimed = false;
  bool _calorieClaimed = false;
  bool _waterClaimed = false;
  bool _chestClaimed = false;

  // Weekly Calorie State
  List<double> _weeklyCalories = List.filled(7, 0.0);
  List<String> _weeklyDays = List.filled(7, '');
  bool _loadingWeekly = true;

  // Streak & Weekly Insight state
  int _xpGainedToday = 0;
  int _longestStreak = 0;
  bool _showStreakDialog = false;
  StreakResult? _streakResult;

  // CalorieProvider listener state
  CalorieProvider? _calorieProvider;
  bool _showGuideCard = true;

  @override
  void initState() {
    super.initState();
    _showGuideCard = !(PrefsService.i.raw.getBool('hide_adventurer_guide') ?? false);
    _loadUserProfile();
    _loadWorkoutStats();
    _loadGamificationData();
    _loadMissionsData();
    _loadWeeklyCalories();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyWrapUp();
      _checkStreak();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = Provider.of<CalorieProvider>(context);
    if (_calorieProvider != newProvider) {
      _calorieProvider?.removeListener(_onCalorieProviderChanged);
      _calorieProvider = newProvider;
      _calorieProvider?.addListener(_onCalorieProviderChanged);
    }
  }

  @override
  void dispose() {
    _calorieProvider?.removeListener(_onCalorieProviderChanged);
    super.dispose();
  }

  void _onCalorieProviderChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWeeklyCalories();
      });
    }
  }

  Future<void> _loadWeeklyCalories() async {
    List<double> calories = [];
    List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      final dayName = DateFormat('E').format(date);
      days.add(dayName);
      final cal = await DatabaseHelper.instance.getTotalCaloriesByDate(dateStr);
      calories.add(cal.toDouble());
    }
    if (mounted) {
      setState(() {
        _weeklyCalories = calories;
        _weeklyDays = days;
        _loadingWeekly = false;
      });
    }
  }

  Future<void> _loadMissionsData() async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    if (mounted) {
      setState(() {
        _waterCups = 0; // Diambil dari CalorieProvider saat build, bukan SharedPreferences
        _proteinClaimed = prefs.getBool('mission_protein_$dateKey') ?? false;
        _calorieClaimed = prefs.getBool('mission_calorie_$dateKey') ?? false;
        _waterClaimed = prefs.getBool('mission_water_$dateKey') ?? false;
        _chestClaimed = prefs.getBool('mission_chest_$dateKey') ?? false;
      });
    }
  }

  Future<void> _loadGamificationData() async {
    final service = GamificationService();
    int xp = await service.getCurrentXP();
    Map<String, int> progress = service.getRankProgress(xp);
    if (mounted) {
      setState(() {
        _currentXP = xp;
        _currentLevel = GamificationService.getCurrentLevel(xp);
        _currentRank = service.getCurrentRank(xp);
        _maxXP = progress['max_xp']!;
      });
    }
  }

  /// Cek dan update streak harian. Tampilkan dialog jika hari baru / milestone.
  Future<void> _checkStreak() async {
    final result = await StreakService().checkAndUpdate();
    if (!mounted) return;

    setState(() {
      _streakDays       = result.streak;
      _longestStreak    = result.longestStreak;
      _xpGainedToday    = result.xpGained;
      _streakResult     = result;
      // Tampilkan dialog hanya saat hari baru (bukan setiap build)
      _showStreakDialog  = result.isNewDay;
    });

    // Refresh XP setelah streak menambahkan XP
    if (result.isNewDay && result.xpGained > 0) {
      await _loadGamificationData();
    }

    // Tampilkan dialog milestone atau streak-reset
    if (result.isNewDay && mounted) {
      final isMilestone = [3, 7, 14, 30].contains(result.streak);
      if (isMilestone || result.isStreakBroken) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => StreakDialog(
            result: result,
            onClose: () => Navigator.pop(context),
          ),
        );
      }
    }
  }

  Future<void> _claimMission(String missionKey, int xpReward, String missionName) async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setBool('mission_${missionKey}_$dateKey', true);

    final xpResult = await GamificationService().addXP(xpReward);
    await _loadGamificationData();
    await _loadMissionsData();

    if (mounted) {
      final leveledUp = xpResult['leveled_up'] as bool;
      if (leveledUp) {
        _showLevelUpDialog(xpResult['new_rank'] as String);
      } else {
        AppSnackbar.xp(context, '⚔️ Misi "$missionName" diklaim! +$xpReward XP');
      }
    }
  }

  Future<void> _claimDailyChest(int completedMissions) async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setBool('mission_chest_$dateKey', true);

    final bonusXP = completedMissions * 30;
    final xpResult = await GamificationService().addXP(bonusXP);
    await _loadGamificationData();
    await _loadMissionsData();

    if (mounted) {
      _showChestDialog(bonusXP, xpResult['leveled_up'] as bool, xpResult['new_rank'] as String);
    }
  }

  void _showChestDialog(int xpGained, bool leveledUp, String newRank) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(scale: value, child: child),
                child: const Text('🎁', style: TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Peti Harian Dibuka!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              if (leveledUp) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Text(
                    '🎉 NAIK RANK ke $newRank!',
                    style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$xpGained XP Diperoleh!',
                  style: const TextStyle(color: Color(0xFFFF9800), fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu adalah pahlawan sejati! 🏆\nTerus pertahankan streak harianmu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Keren! 🎊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLevelUpDialog(String newRank) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(scale: value, child: child),
                child: const Text('🏆', style: TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 16),
              const Text('RANK NAIK!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                'Selamat! Kamu telah mencapai\nperingkat $newRank! 🎖️',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF388E3C), fontWeight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Kembali Berjuang! ⚔️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkDailyWrapUp() async {
    final now = DateTime.now();
    if (now.hour >= 20) { // Setelah jam 8 malam
      final prefs = PrefsService.i.raw;
      final today = DateFormat('dd/MM/yyyy').format(now);
      final lastWrapup = prefs.getString('last_wrapup_date') ?? '';

      if (lastWrapup != today && mounted) {
        await prefs.setString('last_wrapup_date', today);
        _showWrapUpModal();
      }
    }
  }

  void _showWrapUpModal() {
    final calorieProvider = context.read<CalorieProvider>();
    final consumed = calorieProvider.totalConsumedCalories;
    final target = calorieProvider.targetCalories;
    final isSurplus = consumed > target;
    final difference = (consumed - target).abs();

    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (consumed == 0) {
      title = "Hari Ini Kosong?";
      message = "Kamu belum mencatat apapun hari ini. Jangan lupa makan dan catat ya!";
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else if (difference <= 200) {
      title = "Sempurna! 🎯";
      message = "Hebat! Kalorimu hari ini ($consumed kcal) sangat mendekati target ($target kcal). Pertahankan konsistensi ini!";
      icon = Icons.star_rounded;
      iconColor = Colors.yellow;
    } else if (isSurplus) {
      title = "Surplus Kalori 📈";
      message = "Kamu kelebihan $difference kcal hari ini. Cocok jika sedang bulking, tapi hati-hati jika sedang cutting!";
      icon = Icons.trending_up_rounded;
      iconColor = Colors.greenAccent;
    } else {
      title = "Defisit Kalori 📉";
      message = "Kamu masih kurang $difference kcal hari ini. Sangat bagus untuk fat loss, tapi pastikan nutrisimu tetap cukup!";
      icon = Icons.trending_down_rounded;
      iconColor = Colors.blueAccent;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 24),
            Icon(icon, size: 72, color: iconColor),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700], height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kNatureGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Siap Untuk Besok!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    final prefs = PrefsService.i.raw;
    final hasProfile = prefs.getBool('has_profile') ?? false;

    if (hasProfile) {
      setState(() {
        _userProfile = UserProfile(
          name: prefs.getString('name') ?? '',
          age: prefs.getInt('age') ?? 0,
          weight: prefs.getDouble('weight') ?? 0,
          height: prefs.getDouble('height') ?? 0,
          gender: prefs.getString('gender') ?? 'Pria',
          activityLevel: prefs.getString('activity_level') ?? 'Sedang',
          goal: prefs.getString('goal') ?? 'Bulking',
        );
      });
    }
  }

  Future<void> _loadWorkoutStats() async {
    final prefs = PrefsService.i.raw;
    final String lastWorkoutStr = prefs.getString('last_workout_date') ?? '';
    int streak = prefs.getInt('workout_streak') ?? 0;

    if (lastWorkoutStr.isNotEmpty) {
      final now = DateTime.now();
      final today = DateFormat('dd/MM/yyyy').format(now);
      final yesterday = DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1)));

      if (lastWorkoutStr != today && lastWorkoutStr != yesterday) {
        streak = 0;
        await prefs.setInt('workout_streak', 0);
      }
    }

    setState(() {
      _lastWorkoutDate = lastWorkoutStr.isEmpty ? 'Belum ada data' : lastWorkoutStr;
      _streakDays = streak;
    });
  }

  Widget _buildAICoachChip(CalorieProvider calorieProvider) {
    final proteinGap = calorieProvider.targetProtein - calorieProvider.totalConsumedProtein;
    final hasLowProtein = proteinGap > 0 && calorieProvider.totalConsumedProtein < calorieProvider.targetProtein * 0.5;
    final caloriesLeft = calorieProvider.targetCalories - calorieProvider.totalConsumedCalories;

    String tip;
    if (hasLowProtein) {
      tip = 'Protein masih kurang ${proteinGap}g! Selesaikan misi "Daging Perkasa".';
    } else if (caloriesLeft > 500) {
      tip = 'Masih ada $caloriesLeft kcal tersisa. Waktunya makan siang ksatria! ⚔️';
    } else if (caloriesLeft < 0) {
      tip = 'Kalori sudah melebihi target! Jaga sisa harimu. 🛡️';
    } else {
      tip = 'Luar biasa! Asupan harianmu terjaga dengan baik. Pertahankan! ✨';
    }

    // Warna presisi dari code.html: bg-blue-50, border-blue-200,
    // bg-blue-500 (icon circle), text-blue-800, text-blue-400 (chevron)
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // p-sm
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF), // blue-50
          borderRadius: BorderRadius.circular(8), // rounded-lg
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1), // blue-200
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF3B82F6), // blue-500
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🧠', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8), // gap-sm
            Expanded(
              child: Text(
                tip,
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700, // label-bold
                  color: const Color(0xFF1E40AF), // blue-800
                  height: 1.3,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF60A5FA), size: 22), // blue-400
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieRingSection(CalorieProvider calorieProvider) {
    final remaining = calorieProvider.targetCalories - calorieProvider.totalConsumedCalories;
    final isOverload = remaining < 0;

    return Center(
      child: Column(
        children: [
          // Ring 200x200 — ukuran presisi sesuai SVG viewBox di code.html
          FantasyCalorieRing(
            current: calorieProvider.totalConsumedCalories.toDouble(),
            target: calorieProvider.targetCalories.toDouble(),
            size: 200,
          ),
          const SizedBox(height: 16), // mt-4
          // Status pill — bg surface-container-low, border outline-variant/30
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // px-4 py-1.5
            decoration: BoxDecoration(
              color: isOverload
                  ? AppColors.stErrorContainer.withOpacity(0.3)
                  : AppColors.kBgModal, // surface-container-low (#fff2e1)
              borderRadius: BorderRadius.circular(100), // rounded-full
              border: Border.all(
                color: AppColors.stOutlineVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              isOverload ? 'Overload! ⚠️' : 'Masih aman! 😊',
              style: GoogleFonts.inter( // text-sm di HTML pakai font default = Inter/body
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: isOverload ? AppColors.stError : AppColors.stOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBarsSection(CalorieProvider calorieProvider) {
    final prot  = calorieProvider.totalConsumedProtein;
    final tProt = calorieProvider.targetProtein > 0 ? calorieProvider.targetProtein : 130;
    final carb  = calorieProvider.totalConsumedCarbs;
    final tCarb = calorieProvider.targetCarbs > 0 ? calorieProvider.targetCarbs : 200;
    final fat   = calorieProvider.totalConsumedFats;
    final tFat  = calorieProvider.targetFats > 0 ? calorieProvider.targetFats : 65;

    // Warna persis dari code.html:
    // Protein → text-primary (#7c5800), bar bg-secondary (#9b4500)
    // Carbs   → text-[#2196f3], bar bg-[#2196f3]
    // Fat     → text-[#4caf50], bar bg-[#4caf50]
    return Column(
      children: [
        _MacroCard(
          emoji: '🥩', label: 'Protein',
          current: prot, target: tProt,
          color: AppColors.stPrimary,
          barColor: AppColors.stSecondary,
        ),
        const SizedBox(height: 8), // gap-sm
        _MacroCard(
          emoji: '🍞', label: 'Karbohidrat',
          current: carb, target: tCarb,
          color: const Color(0xFF2196F3),
          barColor: const Color(0xFF2196F3),
        ),
        const SizedBox(height: 8),
        _MacroCard(
          emoji: '🥑', label: 'Lemak',
          current: fat, target: tFat,
          color: const Color(0xFF4CAF50),
          barColor: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildQuestBoardSection(CalorieProvider calorieProvider) {
    final consumedProtein = calorieProvider.totalConsumedProtein;
    final targetProtein = calorieProvider.targetProtein.toDouble() > 0 ? calorieProvider.targetProtein.toDouble() : 150.0;
    final consumedCalories = calorieProvider.totalConsumedCalories;
    final targetCalories = calorieProvider.targetCalories > 0 ? calorieProvider.targetCalories : 2000;

    double protProgress = (consumedProtein / targetProtein).clamp(0.0, 1.0);

    final int waterCups = (calorieProvider.totalConsumedWater / 250).floor();
    double waterProgress = (waterCups / _targetWater).clamp(0.0, 1.0);

    bool protCompleted = protProgress >= 1.0;
    bool calCompleted = consumedCalories > 0 && consumedCalories <= targetCalories;
    bool waterCompleted = waterProgress >= 1.0;

    int completedMissions = 0;
    if (protCompleted) completedMissions++;
    if (calCompleted) completedMissions++;
    if (waterCompleted) completedMissions++;

    final bool canClaimChest = completedMissions == 3 && !_chestClaimed &&
        _proteinClaimed && _calorieClaimed && _waterClaimed;
    final int missionsLeft = 3 - completedMissions;

    // Section ini = "Mission Card" di code.html: SATU card besar
    // (surface-container-high, rounded-2xl) membungkus header + 3 item misi
    // + Daily Reward card di dalamnya. Sebelumnya item-item ini lepas
    // di luar card — itu salah, sudah diperbaiki di sini.
    return Container(
      padding: const EdgeInsets.all(16), // p-md
      decoration: BoxDecoration(
        color: AppColors.stSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(16), // rounded-2xl
        border: Border.all(color: AppColors.stOutline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "MISI HARIAN (2/3 ✅)" + ikon refresh
          Padding(
            padding: const EdgeInsets.only(bottom: 16), // mb-md
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MISI HARIAN ($completedMissions/3 ${completedMissions == 3 ? "✅" : ""})',
                  style: GoogleFonts.montserrat( // font-headline-md
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.w700,
                    color: AppColors.stPrimaryContainer,
                    shadows: const [Shadow(color: Colors.black26, blurRadius: 1)], // drop-shadow-sm
                  ),
                ),
                Icon(Icons.refresh_rounded, color: AppColors.stOutline, size: 22),
              ],
            ),
          ),

          // 3 item misi — space-y-sm
          _MissionItem(
            emoji: '🥩',
            bgColor: const Color(0xFFFFEDD5), // orange-100
            title: 'Daging Perkasa',
            subtitle: 'Konsumsi ${targetProtein.toInt()}g Protein',
            xpLabel: '+50 XP',
            isChecked: _proteinClaimed,
            isDimmed: false,
            onTap: protCompleted && !_proteinClaimed
                ? () => _claimMission('protein', 50, 'Daging Perkasa')
                : null,
          ),
          const SizedBox(height: 8),
          _MissionItem(
            emoji: '🔥',
            bgColor: const Color(0xFFFEE2E2), // red-100
            title: 'Latihan Membara',
            subtitle: 'Kalori \u2264 $targetCalories kcal',
            xpLabel: '+40 XP',
            isChecked: _calorieClaimed,
            isDimmed: true, // HTML: opacity-75 untuk item 2 & 3
            onTap: calCompleted && !_calorieClaimed
                ? () => _claimMission('calorie', 40, 'Latihan Membara')
                : null,
          ),
          const SizedBox(height: 8),
          _MissionItem(
            emoji: '💧',
            bgColor: const Color(0xFFDBEAFE), // blue-100
            title: 'Air Kehidupan',
            subtitle: 'Minum $_targetWater Gelas Air',
            xpLabel: '+20 XP',
            isChecked: _waterClaimed,
            isDimmed: true,
            onTap: waterCompleted && !_waterClaimed
                ? () => _claimMission('water', 20, 'Air Kehidupan')
                : null,
          ),

          // Daily Reward Card — di DALAM card yang sama (mt-lg)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Container(
              padding: const EdgeInsets.all(16), // p-md
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.stPrimaryContainer, AppColors.stPrimaryFixed],
                ),
                borderRadius: BorderRadius.circular(12), // rounded-xl
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _chestClaimed ? '✅' : '🎁',
                        style: const TextStyle(fontSize: 30), // text-3xl
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -4, duration: 800.ms),
                      const SizedBox(width: 16), // gap-md
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kotak Harta Harian',
                            style: GoogleFonts.montserrat( // font-headline-md
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.stOnPrimaryContainer,
                            ),
                          ),
                          Text(
                            _chestClaimed
                                ? 'Sudah diklaim hari ini!'
                                : (canClaimChest
                                    ? 'Semua misi selesai!'
                                    : 'Selesaikan $missionsLeft misi lagi!'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.stOnPrimaryFixedVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: canClaimChest ? () => _claimDailyChest(completedMissions) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
                      decoration: BoxDecoration(
                        color: AppColors.stPrimary,
                        borderRadius: BorderRadius.circular(100), // rounded-full
                      ),
                      child: Opacity(
                        opacity: canClaimChest ? 1.0 : 0.5,
                        child: Text(
                          'KLAIM',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(double targetCalories) {
    if (_loadingWeekly) {
      return const FantasyCard(
        child: SizedBox(
          height: 150,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.kPrimaryOrange),
          ),
        ),
      );
    }

    double maxCal = _weeklyCalories.reduce((a, b) => a > b ? a : b);
    if (maxCal < targetCalories) {
      maxCal = targetCalories;
    }
    if (maxCal == 0) {
      maxCal = 2000;
    }

    return FantasyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // h3.font-headline-md text-base mb-md — judul saja, tanpa icon
            // di sisi kanan (HTML tidak punya icon bar_chart di header ini)
            'Statistik Mingguan',
            style: GoogleFonts.montserrat(
              fontSize: 16, // text-base
              fontWeight: FontWeight.w700, // headline-md
              color: AppColors.stOnSurface,
            ),
          ),
          const SizedBox(height: 16), // mb-md
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final cal = _weeklyCalories[index];
                final day = _weeklyDays[index];
                final double heightFactor = (cal / maxCal).clamp(0.02, 1.0);
                final isToday = index == 6;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Track: bg-surface-container-high, rounded-t-md (6px)
                          Container(
                            width: 16,
                            decoration: BoxDecoration(
                              color: AppColors.stSurfaceContainerHigh,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          // Fill: bg-primary-container (solid #ffb800), hover→primary di web
                          // (hover diabaikan di mobile, today disorot via warna primary solid)
                          FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              width: 16,
                              decoration: BoxDecoration(
                                color: isToday ? AppColors.stPrimary : AppColors.stPrimaryContainer,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: GoogleFonts.nunitoSans( // font-label-bold text-outline
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isToday ? AppColors.stPrimary : AppColors.stOutline,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Rata-rata: ${(_weeklyCalories.reduce((a, b) => a + b) / 7).toInt()} kcal / hari',
              style: GoogleFonts.inter( // body text, bukan label
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.stOutline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    String name = _userProfile?.name ?? 'Hero';

    return Scaffold(
      backgroundColor: AppColors.stBackground, // #fff8f3, sama dengan kBgCream tapi konsisten ke token Stitch
      appBar: RPGAppBar(
        screenKey: 'home',
        showSubtitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
            icon: Icon(Icons.bar_chart_rounded, color: AppColors.stPrimary, size: 26),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // px-container-margin (20px), pt-md (16px) sesuai code.html <main>
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Stats Card
              HeroStatsCard(name: name, currentLevel: _currentLevel, streakDays: _streakDays, currentXP: _currentXP, maxXP: _maxXP, rank: _currentRank).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const SizedBox(height: 12), // gap-stack-gap (12px) antar section utama

              if (_showGuideCard) ...[
                _buildAdventurerGuideCard(Theme.of(context).brightness == Brightness.dark),
                const SizedBox(height: 12),
              ],

              // 1b. Streak Banner (tambahan di luar spek Stitch, dipertahankan)
              StreakBannerWidget(
                streak: _streakDays,
                longestStreak: _longestStreak,
                xpGained: _xpGainedToday,
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),

              // 2. AI Coach Chip
              _buildAICoachChip(calorieProvider).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 12),

              // 3. Calorie Ring Section
              _buildCalorieRingSection(calorieProvider).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 12),

              // 4. Macro Bars Grid
              _buildMacroBarsSection(calorieProvider).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),

              // 5. Mission Card (header + 3 item + reward, satu card)
              _buildQuestBoardSection(calorieProvider).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
              const SizedBox(height: 12),

              // 6. Weekly Stats Card
              _buildWeeklyStatsCard(calorieProvider.targetCalories.toDouble()).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),

              // 7. Weekly AI Insight (tambahan di luar spek Stitch, dipertahankan)
              const WeeklyInsightCard().animate().fadeIn(delay: 650.ms),
              const SizedBox(height: 24), // lg (24px) sebelum section baru "Log Petualangan"

              // ── Tracker tambahan (Weight/Water/Workout) — di luar spek Stitch,
              // dipertahankan sesuai kesepakatan, styling header disamakan ke
              // sistem font Stitch (Montserrat headline, bukan Poppins)
              Text(
                'Log Petualangan',
                style: GoogleFonts.montserrat(
                  fontSize: 20, // headline-md
                  fontWeight: FontWeight.w700,
                  color: AppColors.stOnSurface,
                ),
              ),
              const SizedBox(height: 12),
              WeightTrackerCard(
                userProfile: _userProfile,
                onLogAdded: _loadUserProfile,
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 12),
              const WaterTrackerCard().animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 12),
              WorkoutTrackerCard(
                streakDays: _streakDays,
                lastWorkoutDate: _lastWorkoutDate,
                onLogAdded: _loadWorkoutStats,
              ).animate().fadeIn(delay: 900.ms),
              const SizedBox(height: 100), // Spasi untuk bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdventurerGuideCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        border: Border.all(color: AppColors.stSecondary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🧙‍♂️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'PANDUAN PETUALANGAN',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.stSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                onPressed: () async {
                  setState(() {
                    _showGuideCard = false;
                  });
                  await PrefsService.i.raw.setBool('hide_adventurer_guide', true);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat datang di Guild Healthy Calories! Sebagai seorang Binaragawan, misi Anda adalah menjaga surplus/defisit nutrisi agar performa tubuh maksimal. Berikut adalah panduan singkat fitur utama Anda:',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildGuideItem('📊', 'Dashboard Stat', 'Monitor sisa kalori harian dan sisa protein secara real-time di bagian atas.', isDark),
          const SizedBox(height: 8),
          _buildGuideItem('🎯', 'Quest Harian', 'Selesaikan misi konsumsi protein, kalori, dan air untuk mendapatkan Bonus XP.', isDark),
          const SizedBox(height: 8),
          _buildGuideItem('🧠', 'AI Coach Apex', 'Bicaralah dengan Apex di menu chat untuk berkonsultasi seputar menu makanan Anda.', isDark),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String emoji, String title, String desc, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ── MacroCard — sesuai desain Stitch (card terpisah per makro + persentase) ──

class _MacroCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int current;
  final int target;
  final Color color;
  final Color barColor;

  const _MacroCard({
    required this.emoji,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double pct = target > 0 ? (current / target).clamp(0.0, 1.5) : 0.0;
    final int pctInt = (pct * 100).round().clamp(0, 999);
    final bool isOver = pct > 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // p-md
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(
          color: isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? AppColors.kDarkSoftShadow : [
          // .fantasy-card shadow dari code.html
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)), // text-xl
                  const SizedBox(width: 4), // gap-xs
                  Text(
                    label,
                    style: GoogleFonts.nunitoSans( // font-label-bold
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkText : AppColors.stOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.nunitoSans( // font-label-bold (BUKAN Montserrat)
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isOver ? AppColors.stError : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // gap-xs
          // Progress bar — h-2 (8px), bg surface-container-high, progress-gloss
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHigh,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOver ? AppColors.stError : barColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${current}g / ${target}g',
              style: GoogleFonts.inter( // text-[10px] text-outline (body text, bukan stat)
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mission Item — item misi individual di dalam Mission Card ──────────────
//
// Diterjemahkan dari "Mission Item 1/2/3" di code.html:
// bg-surface-container-lowest, rounded-xl, border outline-variant/20,
// icon 40x40 kotak warna pastel, judul+subtitle, badge XP + checkbox.
class _MissionItem extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String xpLabel;
  final bool isChecked;
  final bool isDimmed;
  final VoidCallback? onTap;

  const _MissionItem({
    required this.emoji,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.xpLabel,
    required this.isChecked,
    required this.isDimmed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        // opacity-75 untuk item ke-2 & ke-3 sesuai HTML
        opacity: isDimmed && !isChecked ? 0.75 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(8), // p-sm
          decoration: BoxDecoration(
            color: AppColors.stSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(12), // rounded-xl
            border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Icon box 40x40 (w-10 h-10), rounded-lg
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 16), // gap-md
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunitoSans( // font-label-bold
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stOnSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter( // text-[10px] text-outline, body text
                        fontSize: 10,
                        color: AppColors.stOutline,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.stSecondaryFixed, // bg-secondary-fixed
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      xpLabel,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.stSecondary, // text-secondary
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Checkbox 20x20 (w-5 h-5)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isChecked ? AppColors.stPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isChecked ? AppColors.stPrimary : AppColors.stOutline,
                        width: 1.5,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
