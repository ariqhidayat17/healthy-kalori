import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';

/// Summary header kalori di CalorieTrackerScreen — diterjemahkan dari
/// screenshot log_makanan/screen.png (tidak ada code.html tersedia).
/// Token warna dan tipografi mengacu ke DESIGN.md "Adventurer's Vitality".
class CalorieSummaryHeader extends StatelessWidget {
  final CalorieProvider calorieProvider;

  const CalorieSummaryHeader({super.key, required this.calorieProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target    = calorieProvider.targetCalories;
    final consumed  = calorieProvider.totalConsumedCalories;
    final remaining = (target - consumed).clamp(0, target);
    final double progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final waterLiters = calorieProvider.totalConsumedWater / 1000.0;

    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceMd), // p-md = 16
      decoration: BoxDecoration(
        // surface-container-high (#f3e6d6) — sesuai screenshot warna card
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl), // 20px
        border: Border.all(
          color: isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: ENERGI TERSISA kiri / TARGET kanan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // font-label-bold uppercase text-outline
                  Text(
                    'ENERGI TERSISA',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  // stat-number Montserrat 900 28px + "Kcal" body-md
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$remaining',
                        style: GoogleFonts.montserrat(
                          fontSize: 28, // stat-number
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.02 * 28,
                          height: 32 / 28,
                          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kcal',
                        style: GoogleFonts.montserrat(
                          fontSize: 16, // headline-md weight
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TARGET',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$target',
                    style: GoogleFonts.montserrat(
                      fontSize: 20, // headline-md
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkText : AppColors.stOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppColors.stSpaceSm), // gap-sm = 8

          // Progress bar — h-3 (12px), track surface-container-highest,
          // fill gradient secondary-container→secondary
          Stack(
            children: [
              Container(
                height: 12, // h-3
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.stSecondaryContainer, AppColors.stSecondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                  ),
                  // DESIGN.md: glossy overlay pada progress bar
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppColors.stSpaceMd), // gap-md = 16

          // 4 kolom makro — flat (tanpa bg box), label uppercase text-outline,
          // value warna berbeda per kolom mengacu ke screenshot
          _MacroRow(
            protein: calorieProvider.totalConsumedProtein,
            carbs: calorieProvider.totalConsumedCarbs,
            fats: calorieProvider.totalConsumedFats,
            waterLiters: waterLiters,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final int protein, carbs, fats;
  final double waterLiters;
  final bool isDark;

  const _MacroRow({
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.waterLiters,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Warna per kolom dari screenshot:
    // Protein → secondary (#9b4500), Karbo → blue, Lemak → green, Air → blue
    final outlineColor = isDark ? AppColors.kDarkTextSub : AppColors.stOutline;
    return Row(
      children: [
        _MacroCol(label: 'PROTEIN',    value: '${protein}g',                  color: AppColors.stSecondary,         outline: outlineColor),
        _Divider(),
        _MacroCol(label: 'KARBOHIDRAT', value: '${carbs}g',                   color: const Color(0xFF2196F3),        outline: outlineColor),
        _Divider(),
        _MacroCol(label: 'LEMAK',      value: '${fats}g',                     color: const Color(0xFF4CAF50),        outline: outlineColor),
        _Divider(),
        _MacroCol(label: 'AIR',        value: '${waterLiters.toStringAsFixed(1)}L', color: const Color(0xFF2196F3), outline: outlineColor),
      ],
    );
  }
}

class _MacroCol extends StatelessWidget {
  final String label, value;
  final Color color, outline;
  const _MacroCol({required this.label, required this.value, required this.color, required this.outline});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // label: label-bold uppercase text-outline
          Text(label, style: GoogleFonts.nunitoSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: outline, letterSpacing: 0.3,
          )),
          const SizedBox(height: 2),
          // value: stat-number warna per kolom
          Text(value, style: GoogleFonts.montserrat(
            fontSize: 16, fontWeight: FontWeight.w900, color: color,
          )),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, height: 28, color: AppColors.stOutlineVariant.withOpacity(0.3));
}
