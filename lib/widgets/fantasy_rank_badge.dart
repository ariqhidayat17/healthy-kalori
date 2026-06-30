import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class FantasyRankBadge extends StatelessWidget {
  final String rankName;
  final int level;
  final double progress;
  final double size;

  const FantasyRankBadge({
    super.key,
    required this.rankName,
    required this.level,
    required this.progress,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on rank name (simplified logic)
    Color rankColor = AppColors.kPrimaryGold;
    String rankIcon = '🥇';
    if (rankName.toLowerCase().contains('bronze')) {
      rankColor = Colors.brown;
      rankIcon = '🥉';
    } else if (rankName.toLowerCase().contains('silver')) {
      rankColor = Colors.blueGrey;
      rankIcon = '🥈';
    } else if (rankName.toLowerCase().contains('diamond')) {
      rankColor = AppColors.kManaBlue;
      rankIcon = '💎';
    } else if (rankName.toLowerCase().contains('legend')) {
      rankColor = AppColors.kMysticPurple;
      rankIcon = '👑';
    } else if (rankName.toLowerCase().contains('mythic')) {
      rankColor = AppColors.kHealthRed;
      rankIcon = '🌟';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Rank Icon / Badge
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [rankColor, rankColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rankIcon,
                      style: TextStyle(fontSize: size * 0.3),
                    ),
                    Text(
                      'Lv.$level',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: size * 0.12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Star Rating (1-5)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              Icons.star_rounded,
              color: index < (level % 5 + 1) ? AppColors.kPrimaryGold : Colors.grey[300],
              size: 16,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          rankName.toUpperCase(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.2,
            color: rankColor,
          ),
        ),
      ],
    );
  }
}
