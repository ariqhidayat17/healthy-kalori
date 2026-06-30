import 'package:flutter/material.dart';

class RankBadgeWidget extends StatelessWidget {
  final String rank;
  final double size;
  final bool showText;

  const RankBadgeWidget({
    super.key, 
    required this.rank, 
    this.size = 24.0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String emoji;
    
    switch (rank.toLowerCase()) {
      case 'silver':
        badgeColor = const Color(0xFFC0C0C0);
        emoji = '🥈';
        break;
      case 'gold':
        badgeColor = const Color(0xFFFFD700);
        emoji = '🥇';
        break;
      case 'diamond':
        badgeColor = const Color(0xFF00E5FF);
        emoji = '💎';
        break;
      case 'spartan':
        badgeColor = const Color(0xFFFF0055);
        emoji = '🔥';
        break;
      case 'bronze':
      default:
        badgeColor = const Color(0xFFCD7F32);
        emoji = '🥉';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: size)),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              rank.toUpperCase(),
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.7,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
