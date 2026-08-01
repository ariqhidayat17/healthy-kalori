import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import 'fantasy_card.dart';

class FantasyQuestCard extends StatelessWidget {
  final String title;
  final String progressText;
  final double progress;
  final int xpReward;
  final bool isCompleted;
  final bool isClaimed;
  final String icon;
  final VoidCallback? onClaim;

  const FantasyQuestCard({
    super.key,
    required this.title,
    required this.progressText,
    required this.progress,
    required this.xpReward,
    required this.isCompleted,
    required this.isClaimed,
    required this.icon,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.kDarkText : Colors.black87;
    final subColor = isDark ? AppColors.kDarkTextSub : Colors.black54;

    return FantasyCard(
      padding: const EdgeInsets.all(16),
      border: Border(
        left: BorderSide(
          color: isCompleted ? AppColors.kNatureGreen : AppColors.kPrimaryOrange,
          width: 4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      progressText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClaimed)
                const Icon(Icons.check_circle, color: AppColors.kNatureGreen)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      const Text('⚡ ', style: TextStyle(fontSize: 12)),
                      Text(
                        '+$xpReward XP',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.kPrimaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.kDarkSurface2 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [AppColors.kNatureGreen, AppColors.kNatureGreen.withValues(alpha: 0.7)]
                          : [AppColors.kPrimaryOrange, AppColors.kPrimaryGold],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
          if (isCompleted && !isClaimed) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('CLAIM'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}