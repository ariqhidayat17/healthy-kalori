import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';
import '../services/gamification_service.dart';
import '../utils/prefs_service.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/fantasy_card.dart';
import '../widgets/fantasy_quest_card.dart';

/// MissionScreen — diterjemahkan presisi dari misi_harian/code.html.
///
/// Struktur sesuai HTML:
/// 1. XP Progress Card (parchment-texture, stat-number primary, bar gold)
/// 2. Quest Aktif section — 3 quest card (restaurant/fire/water_drop icons)
/// 3. Peti Harta Harian (dashed border primary-container/50)
/// 4. Quest Mingguan (horizontal scroll, border-l-4)
class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  int _currentXP = 0;
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
      _proteinClaimed = prefs.getBool('mission_protein_$dateKey') ?? false;
      _calorieClaimed = prefs.getBool('mission_calorie_$dateKey') ?? false;
      _waterClaimed   = prefs.getBool('mission_water_$dateKey')   ?? false;
      _chestClaimed   = prefs.getBool('mission_chest_$dateKey')   ?? false;
    });
  }

  Future<void> _claimMission(String key, int xp, String name) async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setBool('mission_${key}_$dateKey', true);
    final result = await GamificationService().addXP(xp);
    await _loadData();
    if (mounted) {
      if (result['leveled_up'] == true) {
        _showLevelUpDialog(result['new_rank'] as String);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚔️ "$name" diklaim! +$xp XP'),
          backgroundColor: AppColors.stPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.stRadiusLg)),
        ));
      }
    }
  }

  Future<void> _claimChest(int completedCount) async {
    final prefs = PrefsService.i.raw;
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    await prefs.setBool('mission_chest_$dateKey', true);
    final bonus = completedCount * 30;
    await GamificationService().addXP(bonus);
    await _loadData();
    if (mounted) _showChestDialog(bonus);
  }

  void _showChestDialog(int xpGained) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.stRadiusXl)),
        title: const Text('🎁 Peti Harta Dibuka!', textAlign: TextAlign.center),
        content: Text('+$xpGained XP bonus! Kerja bagus hari ini!', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keren!')),
        ],
      ),
    );
  }

  void _showLevelUpDialog(String newRank) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.stRadiusXl)),
        title: const Text('🏆 RANK NAIK!', textAlign: TextAlign.center),
        content: Text('Selamat! Kamu mencapai rank $newRank! 🎖️', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Lanjutkan!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final prot  = calorieProvider.totalConsumedProtein;
    final tProt = calorieProvider.targetProtein > 0 ? calorieProvider.targetProtein : 150;
    final cal   = calorieProvider.totalConsumedCalories;
    final tCal  = calorieProvider.targetCalories > 0 ? calorieProvider.targetCalories : 2000;
    final water = calorieProvider.totalConsumedWater; // ml
    final tWater = calorieProvider.targetWater > 0 ? calorieProvider.targetWater : 2000;

    final protPct  = (prot / tProt).clamp(0.0, 1.0);
    final calOk    = cal > 0 && cal <= tCal;
    final waterPct = (water / tWater).clamp(0.0, 1.0);

    int completed = 0;
    if (protPct >= 1.0) completed++;
    if (calOk) completed++;
    if (waterPct >= 1.0) completed++;

    // XP hari ini dari misi yang diklaim
    int xpToday = 0;
    if (_proteinClaimed) xpToday += 50;
    if (_calorieClaimed) xpToday += 40;
    if (_waterClaimed)   xpToday += 20;
    const int maxXpToday = 110;
    final xpPct = (xpToday / maxXpToday).clamp(0.0, 1.0);

    final bool canClaimChest = completed == 3 && !_chestClaimed
        && _proteinClaimed && _calorieClaimed && _waterClaimed;

    // "parchment-texture" = surface-container (#f9ecdb)
    final parchment = isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer;

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.stBackground,
      appBar: const RPGAppBar(screenKey: 'quest'),
      body: SingleChildScrollView(
        // mt-20 px-container-margin space-y-lg
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. XP Progress Card ─────────────────────────────────────────
            _XPCard(xpToday: xpToday, maxXp: maxXpToday, pct: xpPct, parchment: parchment, isDark: isDark),
            const SizedBox(height: 24), // space-y-lg

            // ── 2. Quest Aktif header ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.sports_kabaddi_rounded, color: isDark ? AppColors.kDarkText : AppColors.stPrimary, size: 22),
                    const SizedBox(width: 8),
                    Text('QUEST AKTIF', style: GoogleFonts.montserrat(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                    )),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                  ),
                  child: Text('3 Tersedia', style: GoogleFonts.nunitoSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Quest 1: Protein ────────────────────────────────────────────
            FantasyQuestCard(
              title: 'Makan ${tProt}g Protein',
              progressText: '${prot}g / ${tProt}g',
              progress: protPct,
              xpReward: 50,
              isCompleted: protPct >= 1.0,
              isClaimed: _proteinClaimed,
              icon: '🥩',
              onClaim: protPct >= 1.0 && !_proteinClaimed ? () => _claimMission('protein', 50, 'Makan Protein') : null,
            ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
            const SizedBox(height: 12),

            // ── Quest 2: Kalori ─────────────────────────────────────────────
            FantasyQuestCard(
              title: 'Total Kalori < $tCal',
              progressText: calOk ? '$cal kcal (Terjaga)' : '$cal kcal',
              progress: calOk ? 1.0 : (cal / tCal).clamp(0.0, 1.0),
              xpReward: 40,
              isCompleted: calOk,
              isClaimed: _calorieClaimed,
              icon: '🔥',
              onClaim: calOk && !_calorieClaimed ? () => _claimMission('calorie', 40, 'Kalori Terjaga') : null,
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
            const SizedBox(height: 12),

            // ── Quest 3: Air ─────────────────────────────────────────────────
            FantasyQuestCard(
              title: 'Minum ${(tWater / 1000).toStringAsFixed(1)}L Air',
              progressText: '${(water / 1000).toStringAsFixed(1)}L / ${(tWater / 1000).toStringAsFixed(1)}L',
              progress: waterPct,
              xpReward: 20,
              isCompleted: waterPct >= 1.0,
              isClaimed: _waterClaimed,
              icon: '💧',
              onClaim: waterPct >= 1.0 && !_waterClaimed ? () => _claimMission('water', 20, 'Hydration Hero') : null,
            ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
            const SizedBox(height: 24),

            // ── 3. Peti Harta Harian ────────────────────────────────────────
            GestureDetector(
              onTap: canClaimChest ? () => _claimChest(completed) : null,
              child: FantasyCard(
                padding: const EdgeInsets.all(24),
                border: Border.all(
                  color: AppColors.stPrimaryContainer.withOpacity(0.5),
                  width: 2,
                ),
                child: Column(
                  children: [
                    // Relative icon + lock overlay
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(_chestClaimed ? '✅' : '🎁',
                          style: TextStyle(fontSize: 64, color: canClaimChest ? null : null))
                            .animate(target: canClaimChest ? 1 : 0)
                            .shake(duration: 1.seconds),
                        if (!canClaimChest && !_chestClaimed)
                          Positioned(
                            top: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.stError,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.stBackground, width: 2),
                              ),
                              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _chestClaimed ? 'Sudah Diklaim!' : 'Peti Harta Harian',
                      style: GoogleFonts.montserrat(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _chestClaimed
                          ? 'Kembali lagi besok!'
                          : (canClaimChest ? 'Ketuk untuk klaim!' : 'Selesaikan semua quest untuk membuka!'),
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Progress dots: 3 dots, biru = completed, abu = kosong
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 40, height: 8,
                        decoration: BoxDecoration(
                          color: i < completed ? AppColors.stPrimary : AppColors.stSurfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                        ),
                      )),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completed / 3 QUEST SELESAI',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            // ── 4. Quest Mingguan (horizontal scroll) ──────────────────────
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: AppColors.stPrimary, size: 20),
                const SizedBox(width: 8),
                Text('QUEST MINGGUAN', style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                )),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _WeeklyQuestCard(
                    icon: Icons.fitness_center_rounded, iconColor: AppColors.stSecondary,
                    borderColor: AppColors.stSecondary, title: 'Angkat Beban 3x',
                    xpLabel: '+150 XP', xpBg: AppColors.stSecondaryFixed, xpFg: AppColors.stOnSecondaryFixedVariant,
                    progress: 2/3, label: '2 / 3 Hari',
                    barColor: AppColors.stSecondary, parchment: parchment,
                  ),
                  const SizedBox(width: 16),
                  _WeeklyQuestCard(
                    icon: Icons.directions_run_rounded, iconColor: AppColors.stPrimary,
                    borderColor: AppColors.stPrimary, title: 'Lari 10km Total',
                    xpLabel: '+200 XP', xpBg: AppColors.stPrimaryFixed, xpFg: AppColors.stOnPrimaryFixedVariant,
                    progress: 0.42, label: '4.2 / 10 km',
                    barColor: AppColors.stPrimary, parchment: parchment,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ── XP Progress Card ──────────────────────────────────────────────────────────
class _XPCard extends StatelessWidget {
  final int xpToday, maxXp;
  final double pct;
  final Color parchment;
  final bool isDark;
  const _XPCard({required this.xpToday, required this.maxXp, required this.pct, required this.parchment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return FantasyCard(
      padding: const EdgeInsets.all(AppColors.stSpaceMd),
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
                  Text('XP HARI INI', style: GoogleFonts.nunitoSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                  )),
                  RichText(text: TextSpan(children: [
                    TextSpan(text: '$xpToday', style: GoogleFonts.montserrat(
                      fontSize: 28, fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
                    )),
                    TextSpan(text: ' / $maxXp', style: GoogleFonts.montserrat(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                    )),
                  ])),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.stSecondary, size: 16),
                  const SizedBox(width: 4),
                  Text('${(pct * 100).round()}% Selesai', style: GoogleFonts.nunitoSans(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.stSecondary,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // h-4 bg-surface-container-highest, progress-bar-inner gold gradient
          Stack(children: [
            Container(height: 16, decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
              border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.5), width: 1),
            )),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.stPrimaryContainer, AppColors.stPrimaryFixed],
                  ),
                  borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1))],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            '"Teruslah berjuang, Ksatria! Sedikit lagi menuju level berikutnya."',
            style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic,
              color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Weekly Quest Card ─────────────────────────────────────────────────────────
class _WeeklyQuestCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, borderColor, xpBg, xpFg, barColor, parchment;
  final String title, xpLabel, label;
  final double progress;

  const _WeeklyQuestCard({
    required this.icon, required this.iconColor, required this.borderColor,
    required this.title, required this.xpLabel, required this.xpBg,
    required this.xpFg, required this.progress, required this.label,
    required this.barColor, required this.parchment,
  });

  @override
  Widget build(BuildContext context) {
    return FantasyCard(
      width: 260, // min-w-[260px]
      padding: const EdgeInsets.all(AppColors.stSpaceMd),
      border: Border(left: BorderSide(color: borderColor, width: 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: xpBg, borderRadius: BorderRadius.circular(AppColors.stRadiusDefault)),
                child: Text(xpLabel, style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.w700, color: xpFg)),
              ),
              Text(label, style: GoogleFonts.nunitoSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.stOutline)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(children: [
            Container(height: 6, decoration: BoxDecoration(
              color: AppColors.stSurfaceContainerHighest, borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
            )),
            FractionallySizedBox(widthFactor: progress,
              child: Container(height: 6, decoration: BoxDecoration(
                color: barColor, borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
              ))),
          ]),
        ],
      ),
    );
  }
}
