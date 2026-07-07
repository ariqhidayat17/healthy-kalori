import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class FantasyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;

  const FantasyCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.gradient,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest;

    // DESIGN.md: "Every card must have a subtle 1px inner border in a lighter
    // tint than its background to create a 'beveled' look."
    // Light mode: outline-variant/30 (#d5c4ab @ 30%)
    // Dark mode: kDarkBorder
    final bevelBorder = border ?? Border.all(
      color: isDark
          ? AppColors.kDarkBorder
          : AppColors.stOutlineVariant.withOpacity(0.3),
      width: 1,
    );

    // DESIGN.md Hero Lift: rgba(255,140,66,0.3), blur 12px
    final cardShadow = isDark
        ? AppColors.kDarkSoftShadow
        : AppColors.stHeroShadow;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl), // 20px
        border: bevelBorder,
        boxShadow: cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppColors.stSpaceMd),
            child: child,
          ),
        ),
      ),
    );
  }
}
