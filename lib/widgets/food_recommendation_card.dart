import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Card rekomendasi makanan yang muncul di dalam chat Apex.
/// Sesuai desain Stitch: gambar header + badge rarity + tabel nutrisi
/// + tombol "Tambah ke Log".
class FoodRecommendationCard extends StatelessWidget {
  final String foodName;
  final String rarity; // Common, Rare, Epic, Legendary
  final int calories;
  final int protein;
  final int fats;
  final int carbs;
  final String emoji;
  final VoidCallback onAddToLog;

  const FoodRecommendationCard({
    super.key,
    required this.foodName,
    required this.rarity,
    required this.calories,
    required this.protein,
    required this.fats,
    this.carbs = 0,
    this.emoji = '🍗',
    required this.onAddToLog,
  });

  Color get _rarityColor => switch (rarity) {
        'Legendary' => AppColors.kRarityLegendary,
        'Epic'      => AppColors.kRarityEpic,
        'Rare'      => AppColors.kRarityRare,
        _           => AppColors.kRarityCommon,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _rarityColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _rarityColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header gambar dengan gradient overlay + nama ─────────────────
          Stack(
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    colors: [_rarityColor.withOpacity(0.3), _rarityColor.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
              // Gradient overlay di bawah untuk readability teks
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.zero),
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xCC000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Badge rarity
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _rarityColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    rarity.toUpperCase(),
                    style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Nama makanan
              Positioned(
                bottom: 10, left: 12, right: 12,
                child: Text(
                  foodName,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // ── Tabel nutrisi ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              children: [
                _NutritionRow(label: 'Kalori', value: '$calories kcal', isDark: isDark, bold: true),
                const SizedBox(height: 6),
                _NutritionRow(label: 'Protein', value: '${protein}g', isDark: isDark),
                if (carbs > 0) ...[
                  const SizedBox(height: 6),
                  _NutritionRow(label: 'Karbohidrat', value: '${carbs}g', isDark: isDark),
                ],
                const SizedBox(height: 6),
                _NutritionRow(label: 'Lemak', value: '${fats}g', isDark: isDark),
              ],
            ),
          ),

          // ── Tombol Tambah ke Log ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: GestureDetector(
              onTap: onAddToLog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.kPrimaryGold, AppColors.kPrimaryOrange],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Tambah ke Log',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool bold;

  const _NutritionRow({
    required this.label,
    required this.value,
    required this.isDark,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.kDarkText : const Color(0xFF211B11);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.kDarkTextSub : const Color(0xFF837560),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: bold ? AppColors.kPrimaryOrange : textColor,
          ),
        ),
      ],
    );
  }
}
