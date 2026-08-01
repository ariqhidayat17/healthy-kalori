import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const SectionHeader({super.key, required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.stPrimary, size: 20),
        const SizedBox(width: AppColors.stSpaceSm),
        Text(label, style: GoogleFonts.nunitoSans(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1,
          color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant)),
      ],
    );
  }
}

class StatCell extends StatelessWidget {
  final String label, value, unit;
  final Color? valueColor, unitBg, unitColor;
  final bool isDark;

  const StatCell({
    super.key,
    required this.label, required this.value, required this.unit,
    required this.isDark, this.valueColor, this.unitBg, this.unitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceSm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
        border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: GoogleFonts.nunitoSans(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
          color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.montserrat(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: valueColor ?? (isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: unitBg ?? Colors.transparent,
            borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
          ),
          child: Text(unit, style: GoogleFonts.nunitoSans(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: unitColor ?? (isDark ? AppColors.kDarkTextSub : AppColors.stOutline))),
        ),
      ]),
    );
  }
}

class InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const InfoTag({super.key, required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainer,
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.stOutline),
        const SizedBox(width: 4),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.icon, required this.label,
    required this.value, required this.isDark, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppColors.stSpaceSm),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.stPrimaryContainer.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.stPrimary),
        ),
        const SizedBox(width: AppColors.stSpaceMd),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}

class SettingsChevron extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool isDark;
  final VoidCallback? onTap;

  const SettingsChevron({
    super.key,
    required this.icon, required this.label, required this.isDark,
    this.trailing, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppColors.stSpaceSm),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.stPrimaryContainer.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.stPrimary),
          ),
          const SizedBox(width: AppColors.stSpaceMd),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
          if (trailing != null) ...[
            Text(trailing!, style: GoogleFonts.inter(
              fontSize: 12, color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline)),
            const SizedBox(width: 4),
          ],
          Icon(Icons.chevron_right_rounded,
            color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline, size: 20),
        ]),
      ),
    );
  }
}
