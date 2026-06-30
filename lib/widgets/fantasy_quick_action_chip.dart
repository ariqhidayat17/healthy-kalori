import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class FantasyQuickActionChip extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool isActive;

  const FantasyQuickActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.kGradientSunset : null,
            color: isActive ? null : Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.kPrimaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
