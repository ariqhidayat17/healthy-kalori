import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';
import '../widgets/fantasy_card.dart';

/// Widget ringkasan kalori + progress bar di bagian atas CalorieTrackerScreen.
/// Diekstrak dari _buildMacroSummaryBar + _buildMiniMacrosRow.
class CalorieSummaryHeader extends StatelessWidget {
  final CalorieProvider calorieProvider;

  const CalorieSummaryHeader({super.key, required this.calorieProvider});

  @override
  Widget build(BuildContext context) {
    final target = calorieProvider.targetCalories;
    final consumed = calorieProvider.totalConsumedCalories;
    final remaining = (target - consumed).clamp(0, target);
    final double progress =
        target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return FantasyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: Energi Tersisa + Target ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENERGI TERSISA',
                    style: GoogleFonts.nunito(
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remaining ',
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.kPrimaryOrange,
                          ),
                        ),
                        TextSpan(
                          text: 'Kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TARGET',
                    style: GoogleFonts.nunito(
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$target',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Progress bar (Mana Bar style) ─────────────────────────────────
          Stack(
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFC8A40), Color(0xFF9B4500)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Mini makro row ──────────────────────────────────────────────
          _MiniMacrosRow(calorieProvider: calorieProvider),
        ],
      ),
    );
  }
}

class _MiniMacrosRow extends StatelessWidget {
  final CalorieProvider calorieProvider;
  const _MiniMacrosRow({required this.calorieProvider});

  @override
  Widget build(BuildContext context) {
    final waterLiters = calorieProvider.totalConsumedWater / 1000.0;
    return Row(
      children: [
        _MiniMacroItem(
          label: 'PROTEIN',
          value: '${calorieProvider.totalConsumedProtein}g',
          color: AppColors.kPrimaryOrange,
        ),
        const SizedBox(width: 8),
        _MiniMacroItem(
          label: 'KARBO',
          value: '${calorieProvider.totalConsumedCarbs}g',
          color: AppColors.kManaBlue,
        ),
        const SizedBox(width: 8),
        _MiniMacroItem(
          label: 'LEMAK',
          value: '${calorieProvider.totalConsumedFats}g',
          color: AppColors.kHealthRed,
        ),
        const SizedBox(width: 8),
        _MiniMacroItem(
          label: 'AIR',
          value: '${waterLiters.toStringAsFixed(1)}L',
          color: const Color(0xFF29B6F6),
        ),
      ],
    );
  }
}

class _MiniMacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniMacroItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
