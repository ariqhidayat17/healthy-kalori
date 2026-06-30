import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/prefs_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/calorie_provider.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/fantasy_quest_card.dart';
import '../widgets/fantasy_card.dart';

/// MissionScreen — Quest Board harian.
/// Rank & Leaderboard kini di RankProgressScreen terpisah (tab Rank di
/// bottom nav), jadi screen ini fokus 100% ke quest harian sesuai desain
/// Stitch: "XP HARI INI" card + Quest Aktif + Peti Harta Harian.
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  int _currentXP = 0;
  String _currentRank = 'Bronze';

  bool _proteinClaimed = false;
  bool _calorieClaimed = false;
  bool _waterClaimed = false;
  bool _chestClaimed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';

    final stats = await GamificationService().getUserStats();

    setState(() {
      _currentXP = stats['xp'] as int? ?? 0;
      _currentRank = stats['rank'] as String? ?? 'Bronze';
      _proteinClaimed = prefs.getBool('mission_protein_$dateKey') ?? false;
      _calorieClaimed = prefs.getBool('mission_calorie_$dateKey') ?? false;
      _waterClaimed = prefs.getBool('mission_water_$dateKey') ?? false;
      _chestClaimed = prefs.getBool('mission_chest_$dateKey') ?? false;
    });
  }

  Future<void> _claimMission(String missionKey, int xpReward, String missionName) async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setBool('mission_${missionKey}_$dateKey', true);

    final xpResult = await GamificationService().addXP(xpReward);
    await _loadData();

    if (mounted) {
      final leveledUp = xpResult['leveled_up'] as bool;
      if (leveledUp) {
        _showLevelUpDialog(xpResult['new_rank'] as String);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚔️ Misi "$missionName" diklaim! +$xpReward XP'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
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
    await _loadData();

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
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
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
                  color: const Color(0xFFFF9800).withValues(alpha: 0.1),
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

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final consumedProtein = calorieProvider.totalConsumedProtein;
    final targetProtein = calorieProvider.targetProtein > 0
        ? calorieProvider.targetProtein.toDouble()
        : 150.0;

    final consumedCalories = calorieProvider.totalConsumedCalories;
    final targetCalories = calorieProvider.targetCalories > 0
        ? calorieProvider.targetCalories
        : 2000;

    final consumedWaterMl = calorieProvider.totalConsumedWater;
    final targetWaterMl = calorieProvider.targetWater > 0
        ? calorieProvider.targetWater
        : 2000;
    final waterCups = (consumedWaterMl / 250).floor();
    final targetWaterCups = (targetWaterMl / 250).ceil();

    double protProgress = (consumedProtein / targetProtein).clamp(0.0, 1.0);
    double calProgress = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
        : 0.0;
    bool calCompleted = calProgress >= 0.9;
    double waterProgress = (consumedWaterMl / targetWaterMl).clamp(0.0, 1.0);
    bool protCompleted = protProgress >= 1.0;
    bool waterCompleted = waterProgress >= 1.0;

    int completedMissions = 0;
    if (protCompleted) completedMissions++;
    if (calCompleted) completedMissions++;
    if (waterCompleted) completedMissions++;

    final bool allMissionsCompleted = completedMissions == 3;
    final bool canClaimChest = allMissionsCompleted && !_chestClaimed &&
        _proteinClaimed && _calorieClaimed && _waterClaimed;

    // XP hari ini — estimasi dari misi yang sudah diklaim (sesuai desain Stitch "XP HARI INI")
    int xpToday = 0;
    if (_proteinClaimed) xpToday += 50;
    if (_calorieClaimed) xpToday += 40;
    if (_waterClaimed) xpToday += 20;
    const int maxXpToday = 50 + 40 + 20; // 110, dibulatkan visual ke 200 di Stitch utk headroom chest
    final double xpTodayProgress = (xpToday / maxXpToday).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.kBgCream,
      appBar: const RPGAppBar(screenKey: 'quest'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ── XP HARI INI card — sesuai desain Stitch ───────────────────────
            _buildXPTodayCard(xpToday, maxXpToday, xpTodayProgress, completedMissions),
            const SizedBox(height: 24),

            _sectionTitle('QUEST AKTIF'),
            const SizedBox(height: 12),

            FantasyQuestCard(
              icon: '🥩',
              title: 'Makan 150g Protein',
              progressText: '${consumedProtein.toInt()} / ${targetProtein.toInt()}g',
              progress: protProgress,
              xpReward: 50,
              isCompleted: protCompleted,
              isClaimed: _proteinClaimed,
              onClaim: () => _claimMission('protein', 50, 'Protein Warrior'),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1),
            const SizedBox(height: 12),

            FantasyQuestCard(
              icon: '🔥',
              title: 'Total Kalori < ${targetCalories}',
              progressText: '$consumedCalories kcal',
              progress: calProgress,
              xpReward: 40,
              isCompleted: calCompleted,
              isClaimed: _calorieClaimed,
              onClaim: () => _claimMission('calorie', 40, 'Kalori Terjaga'),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
            const SizedBox(height: 12),

            FantasyQuestCard(
              icon: '💧',
              title: 'Minum ${(targetWaterMl / 1000).toStringAsFixed(1)}L Air',
              progressText: '$waterCups / $targetWaterCups Gelas',
              progress: waterProgress,
              xpReward: 20,
              isCompleted: waterCompleted,
              isClaimed: _waterClaimed,
              onClaim: () => _claimMission('water', 20, 'Hydration Hero'),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
            const SizedBox(height: 32),

            // ── Peti Harta Harian — sesuai desain Stitch (dashed border) ──────
            _buildTreasureChest(canClaimChest, completedMissions, isDark),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // ── XP Hari Ini card sesuai Stitch ─────────────────────────────────────────
  Widget _buildXPTodayCard(int xpToday, int maxXp, double progress, int completed) {
    final pct = (progress * 100).round();
    return FantasyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'XP HARI INI',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: Colors.black45, letterSpacing: 0.5,
                    ),
                  ),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '$xpToday ',
                        style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                      ),
                      TextSpan(
                        text: '/ $maxXp',
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black38),
                      ),
                    ]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '✨ $pct% Selesai',
                  style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF8A5A1E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(100)),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: AppColors.kGradientSunset,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completed == 3
                ? 'Semua quest selesai! Buka Peti Harta sekarang! 🎁'
                : 'Teruslah berjuang, Ksatria! Sedikit lagi menuju level berikutnya.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Text('⚔️ ', style: TextStyle(fontSize: 14)),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasureChest(bool canClaim, int completed, bool isDark) {
    return GestureDetector(
      onTap: canClaim ? () => _claimDailyChest(completed) : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.kDarkSurface2 : const Color(0xFFFBF1E3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.kPrimaryGold.withOpacity(canClaim ? 0.8 : 0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Text(
              _chestClaimed ? '✅' : (canClaim ? '🎁' : '📦'),
              style: const TextStyle(fontSize: 56),
            ).animate(target: canClaim ? 1 : 0).shake(duration: 1.seconds),
            const SizedBox(height: 12),
            Text(
              _chestClaimed ? 'Klaim Berhasil!' : 'Peti Harta Harian',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800, fontSize: 17,
                color: _chestClaimed ? Colors.grey : AppColors.kPrimaryGold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _chestClaimed
                  ? 'Kembali lagi besok ya!'
                  : (canClaim ? 'Ketuk untuk buka hadiah!' : 'Selesaikan semua quest untuk membuka!'),
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
