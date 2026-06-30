import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Progress bar makro yang dianimasikan — menggantikan versi lama yang static.
///
/// Fitur baru:
/// - Animasi fill saat mount (TweenAnimationBuilder)
/// - Status over-target (merah saat melebihi 100%)
/// - Label lengkap dengan nilai saat ini, target, dan satuan
/// - Pill label dengan icon warna
class AnimatedMacroBar extends StatelessWidget {
  final String label;
  final String unit;
  final int current;
  final int target;
  final Color color;
  final IconData? icon;
  final String? emoji;

  const AnimatedMacroBar({
    super.key,
    required this.label,
    required this.unit,
    required this.current,
    required this.target,
    required this.color,
    this.icon,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final double raw = target > 0 ? current / target : 0.0;
    final double progress = raw.clamp(0.0, 1.0);
    final bool isOver = raw > 1.0;
    final barColor = isOver ? AppColors.kHealthRed : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '$current',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isOver ? AppColors.kHealthRed : color,
                  ),
                ),
                Text(
                  ' / $target $unit',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // ── Animated progress bar ─────────────────────────────────────────
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              children: [
                // Background track
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          barColor.withOpacity(0.7),
                          barColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // ── Over-target warning ───────────────────────────────────────────
        if (isOver)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '⚠️ ${((raw - 1) * 100).round()}% di atas target',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.kHealthRed,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
      ],
    );
  }
}

/// Card berisi 3 macro bars (Protein, Karbo, Lemak) sekaligus.
class MacroProgressCard extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fats;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;

  const MacroProgressCard({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Makronutrisi Hari Ini',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          AnimatedMacroBar(
            label: 'Protein',
            unit: 'g',
            current: protein,
            target: targetProtein,
            color: AppColors.kPrimaryOrange,
            emoji: '🍗',
          ),
          const SizedBox(height: 14),
          AnimatedMacroBar(
            label: 'Karbohidrat',
            unit: 'g',
            current: carbs,
            target: targetCarbs,
            color: AppColors.kManaBlue,
            emoji: '🍚',
          ),
          const SizedBox(height: 14),
          AnimatedMacroBar(
            label: 'Lemak',
            unit: 'g',
            current: fats,
            target: targetFats,
            color: AppColors.kNatureGreen,
            emoji: '🥑',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
