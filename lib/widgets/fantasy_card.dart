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
    final cardColor = isDark ? AppColors.kDarkSurface : AppColors.kBgCard;
    final shadow = isDark ? AppColors.kDarkSoftShadow : AppColors.kSoftShadow;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: gradient == null ? cardColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: border ??
            (isDark
                ? Border.all(color: AppColors.kDarkBorder, width: 0.5)
                : null),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}
