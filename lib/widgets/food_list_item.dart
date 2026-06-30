import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/calorie_entry.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';

class FoodListItem extends StatelessWidget {
  final CalorieEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const FoodListItem({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String rarity = GamificationService.determineFoodRarity(
      entry.calories.toDouble(),
      entry.protein.toDouble(),
    );

    Color rarityColor;
    String rarityLabel;
    bool isLegendary = rarity == 'Legendary';
    List<BoxShadow> cardShadow = AppColors.kSoftShadow;

    switch (rarity) {
      case 'Legendary':
        rarityColor = const Color(0xFFFBBF24);
        rarityLabel = 'LEGENDARY';
        cardShadow = [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
        break;
      case 'Epic':
        rarityColor = const Color(0xFFA855F7);
        rarityLabel = 'EPIC';
        cardShadow = [
          BoxShadow(
            color: const Color(0xFFA855F7).withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ];
        break;
      case 'Rare':
        rarityColor = const Color(0xFFF97316);
        rarityLabel = 'RARE';
        break;
      case 'Common':
      default:
        rarityColor = const Color(0xFF94A3B8);
        rarityLabel = 'COMMON';
        cardShadow = [];
    }

    String foodEmoji = _getFoodEmoji(entry.foodName);

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor,
          width: isLegendary ? 2.0 : (rarity == 'Common' ? 1.0 : 1.5),
        ),
        boxShadow: cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Left: Food Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3), // bg-surface-container-low style
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Text(
                      foodEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Middle: Food Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.foodName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _macroInfo('P', entry.protein, AppColors.kPrimaryOrange),
                          const SizedBox(width: 6),
                          _macroInfo('C', entry.carbs, AppColors.kManaBlue),
                          const SizedBox(width: 6),
                          _macroInfo('F', entry.fats, AppColors.kNatureGreen),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Rarity Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: rarityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: rarityColor.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLegendary) ...[
                              const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFBBF24)),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              rarityLabel,
                              style: GoogleFonts.nunito(
                                color: rarityColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Calories
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.calories}',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: rarityColor,
                      ),
                    ),
                    Text(
                      'KCAL',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.kHealthRed, size: 20),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isLegendary) {
      return Shimmer.fromColors(
        baseColor: Colors.white,
        highlightColor: const Color(0xFFFBBF24).withOpacity(0.2),
        period: const Duration(milliseconds: 2000),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _macroInfo(String label, int value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            fontSize: 9,
            color: color,
          ),
        ),
        Text(
          ' ${value}g',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 9,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _getFoodEmoji(String foodName) {
    final lower = foodName.toLowerCase();
    if (lower.contains('nasi') || lower.contains('rice')) return '🍚';
    if (lower.contains('ayam') || lower.contains('chicken')) return '🍗';
    if (lower.contains('sapi') || lower.contains('beef') || lower.contains('daging')) return '🥩';
    if (lower.contains('ikan') || lower.contains('fish')) return '🐟';
    if (lower.contains('telur') || lower.contains('egg')) return '🥚';
    if (lower.contains('suku') || lower.contains('susu') || lower.contains('milk')) return '🥛';
    if (lower.contains('buah') || lower.contains('fruit')) return '🍎';
    if (lower.contains('sayur') || lower.contains('veggie') || lower.contains('salad')) return '🥗';
    if (lower.contains('roti') || lower.contains('bread')) return '🍞';
    if (lower.contains('mie') || lower.contains('mifun') || lower.contains('noodle')) return '🍜';
    if (lower.contains('kopi') || lower.contains('coffee')) return '☕';
    if (lower.contains('teh') || lower.contains('tea')) return '🍵';
    if (lower.contains('jus') || lower.contains('juice')) return '🥤';
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('sate')) return '🍢';
    if (lower.contains('sup') || lower.contains('soto') || lower.contains('soup')) return '🍲';
    if (lower.contains('coklat') || lower.contains('chocolate')) return '🍫';
    if (lower.contains('es') || lower.contains('ice cream')) return '🍦';
    return '🍽️';
  }
}
