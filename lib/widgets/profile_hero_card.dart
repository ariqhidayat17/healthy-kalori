import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/gamification_service.dart';

class RankTheme {
  final List<Color> gradientColors;
  final Color borderColor;
  final Color glowColor;
  final String title;

  const RankTheme({
    required this.gradientColors,
    required this.borderColor,
    required this.glowColor,
    required this.title,
  });

  factory RankTheme.fromRank(String rank) {
    switch (rank) {
      case 'Bronze':
        return const RankTheme(
          gradientColors: [Color(0xFF5D4037), Color(0xFF3E2723)],
          borderColor: Color(0xFFCD7F32),
          glowColor: Color(0x33CD7F32),
          title: 'BRONZE WARRIOR',
        );
      case 'Silver':
        return const RankTheme(
          gradientColors: [Color(0xFF455A64), Color(0xFF263238)],
          borderColor: Color(0xFFB0C4DE),
          glowColor: Color(0x33B0C4DE),
          title: 'SILVER WARRIOR',
        );
      case 'Gold':
        return const RankTheme(
          gradientColors: [Color(0xFF7D6608), Color(0xFF453603)],
          borderColor: Color(0xFFFFD700),
          glowColor: Color(0x4DFFD700),
          title: 'GOLD WARRIOR',
        );
      case 'Diamond':
        return const RankTheme(
          gradientColors: [Color(0xFF1A5276), Color(0xFF11334C)],
          borderColor: Color(0xFF00E5FF),
          glowColor: Color(0x4D00E5FF),
          title: 'DIAMOND WARRIOR',
        );
      case 'Spartan':
        return const RankTheme(
          gradientColors: [Color(0xFF7B241C), Color(0xFF421010)],
          borderColor: Color(0xFFFF3D00),
          glowColor: Color(0x66FF3D00),
          title: 'SPARTAN WARRIOR',
        );
      default:
        return const RankTheme(
          gradientColors: [Color(0xFF1F2937), Color(0xFF111827)],
          borderColor: Colors.white30,
          glowColor: Colors.transparent,
          title: 'HERO',
        );
    }
  }
}

class ProfileHeroCard extends StatelessWidget {
  final String name;
  final int xp;
  final String rank;
  final int workoutStreak;
  final VoidCallback onEditPressed;

  // Body stats parameters for unified profile info
  final double weight;
  final double height;
  final String bmiStr;
  final String bmiLabel;
  final Color bmiColor;
  final Color bmiBg;
  final String goal;
  final num targetCal;
  final String goalEmoji;
  final String activityLevel;
  final int age;

  const ProfileHeroCard({
    super.key,
    required this.name,
    required this.xp,
    required this.rank,
    required this.workoutStreak,
    required this.onEditPressed,
    required this.weight,
    required this.height,
    required this.bmiStr,
    required this.bmiLabel,
    required this.bmiColor,
    required this.bmiBg,
    required this.goal,
    required this.targetCal,
    required this.goalEmoji,
    required this.activityLevel,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final gamification = GamificationService();
    final rankProgress = gamification.getRankProgress(xp);
    final xpMin = rankProgress['min_xp']!;
    final xpMax = rankProgress['max_xp']!;
    final xpProgress = xpMax > xpMin ? (xp - xpMin) / (xpMax - xpMin) : 0.0;
    final rankTheme = RankTheme.fromRank(rank);

    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rankTheme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        border: Border.all(color: rankTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rankTheme.glowColor,
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 20),
              onPressed: onEditPressed,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Identity Row ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: rankTheme.borderColor,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rankTheme.borderColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            rank == 'Bronze' ? 'assets/images/bronze.png' :
                            rank == 'Silver' ? 'assets/images/silver.png' :
                            rank == 'Gold' ? 'assets/images/gold.png' :
                            rank == 'Diamond' ? 'assets/images/diamond.png' :
                            rank == 'Spartan' ? 'assets/images/spartan.png' :
                            'assets/images/apex_avatar.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.stPrimaryFixed.withOpacity(0.3),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.stPrimaryFixed,
                            borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                            border: Border.all(color: AppColors.stOnPrimaryFixedVariant.withOpacity(0.2)),
                          ),
                          child: Text(
                            'LEVEL ${GamificationService.getCurrentLevel(xp)}',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.stOnPrimaryFixedVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppColors.stSpaceLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 28 / 22,
                          ),
                        ),
                        const SizedBox(height: AppColors.stSpaceXs),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: rankTheme.borderColor.withOpacity(0.15),
                                border: Border.all(color: rankTheme.borderColor.withOpacity(0.4)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rankTheme.title,
                                style: GoogleFonts.nunitoSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: rankTheme.borderColor,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Text(
                                  '$workoutStreak Hari Streak',
                                  style: GoogleFonts.nunitoSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppColors.stSpaceMd),

              // ── XP Progress ────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP Progress',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${xp.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")} / ${xpMax.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: xpProgress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.stPrimaryFixed, AppColors.stPrimaryContainer],
                            ),
                          ),
                          child: Container(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: Colors.white24, height: 24, thickness: 1),

              // ── Body Stats Grid ────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _buildStatCell(
                      label: 'BERAT',
                      value: '${weight.toInt()}',
                      unit: 'kg',
                    ),
                  ),
                  const SizedBox(width: AppColors.stSpaceSm),
                  Expanded(
                    child: _buildStatCell(
                      label: 'TINGGI',
                      value: '${height.toInt()}',
                      unit: 'cm',
                    ),
                  ),
                  const SizedBox(width: AppColors.stSpaceSm),
                  Expanded(
                    child: _buildStatCell(
                      label: 'BMI',
                      value: bmiStr,
                      unit: bmiLabel,
                      unitBg: bmiBg,
                      unitColor: bmiColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppColors.stSpaceMd),

              // ── RPG Goals & Details Row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MODE TUJUAN',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$goalEmoji ${goal.toUpperCase()}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${targetCal.toInt()} kcal/hari',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppColors.stSpaceSm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFO RPG',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Usia: $age Thn',
                            style: GoogleFonts.nunitoSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activityLevel,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required String label,
    required String value,
    required String unit,
    Color? unitBg,
    Color? unitColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceSm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.nunitoSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          if (unitBg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: unitBg,
                borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
              ),
              child: Text(
                unit,
                style: GoogleFonts.nunitoSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: unitColor ?? Colors.white,
                ),
              ),
            )
          else
            Text(
              unit,
              style: GoogleFonts.nunitoSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}