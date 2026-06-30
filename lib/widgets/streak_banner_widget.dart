import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../services/streak_service.dart';

/// Banner streak harian yang ditampilkan di HomeScreen.
/// Menampilkan jumlah hari berturut-turut, XP yang didapat hari ini,
/// dan bar visual 7-hari terakhir.
class StreakBannerWidget extends StatelessWidget {
  final int streak;
  final int longestStreak;
  final int xpGained; // 0 jika bukan hari baru

  const StreakBannerWidget({
    super.key,
    required this.streak,
    required this.longestStreak,
    this.xpGained = 0,
  });

  Color get _flameColor {
    if (streak >= 30) return const Color(0xFFFFD700); // Gold
    if (streak >= 14) return const Color(0xFFFF4500); // OrangeRed
    if (streak >= 7)  return AppColors.kPrimaryOrange;
    return const Color(0xFFFF8C42);
  }

  String get _flameEmoji {
    if (streak >= 30) return '👑';
    if (streak >= 14) return '⚡';
    if (streak >= 7)  return '🔥';
    if (streak >= 3)  return '🔥';
    return '✨';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _flameColor.withOpacity(0.15),
            _flameColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _flameColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // ── Api / ikon streak ──────────────────────────────────────────
          Text(_flameEmoji, style: const TextStyle(fontSize: 28))
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.1, duration: 800.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(end: 1.0, duration: 800.ms, curve: Curves.easeInOut),

          const SizedBox(width: 12),

          // ── Angka streak + label ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak Hari',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _flameColor,
                      ),
                    ),
                    if (xpGained > 0) ...[
                      const SizedBox(width: 8),
                      _XpBadge(xp: xpGained),
                    ],
                  ],
                ),
                Text(
                  StreakService.motivationMessage(streak),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Rekor terpanjang ───────────────────────────────────────────
          if (longestStreak > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Rekor',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$longestStreak hari',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.kNatureGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kNatureGreen.withOpacity(0.5)),
      ),
      child: Text(
        '+$xp XP',
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1B8A5A),
        ),
      ),
    );
  }
}

/// Dialog yang muncul saat hari pertama streak baru / streak putus.
class StreakDialog extends StatelessWidget {
  final StreakResult result;
  final VoidCallback onClose;

  const StreakDialog({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isReset = result.isStreakBroken && result.streak == 1;
    final isMilestone = [3, 7, 14, 30].contains(result.streak);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isReset ? '😅' : (isMilestone ? '🏆' : '🔥'),
              style: const TextStyle(fontSize: 64),
            ).animate().scaleXY(
                  begin: 0.5,
                  end: 1.0,
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 12),
            Text(
              isReset
                  ? 'Streak Reset!'
                  : (isMilestone
                      ? '🎉 Milestone ${result.streak} Hari!'
                      : '${result.streak} Hari Berturut-turut!'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isReset
                  ? 'Jangan menyerah! Mulai lagi dari hari ini 💪'
                  : StreakService.motivationMessage(result.streak),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.xpGained > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.kNatureGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${result.xpGained} XP hari ini',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B8A5A),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Lanjutkan Quest! ⚔️',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
