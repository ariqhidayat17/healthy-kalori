import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class MacroCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int current;
  final int target;
  final Color color;
  final Color barColor;

  const MacroCard({
    super.key,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isDark ? AppColors.kDarkSoftShadow : [
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
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.kDarkText : AppColors.stOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '$pctInt%',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isOver ? AppColors.stError : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
              style: GoogleFonts.inter(
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
