import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../utils/rpg_title_helper.dart';

/// Hero card di HomeScreen — sesuai desain Stitch.
/// Menampilkan avatar RPG (karakter), Level + Streak badge, nama,
/// dan XP progress bar dalam card oranye-gold gradient.
class HeroStatsCard extends StatelessWidget {
  final String name;
  final int currentLevel;
  final int streakDays;
  final int currentXP;
  final int maxXP;
  final String rank;

  const HeroStatsCard({
    super.key,
    required this.name,
    required this.currentLevel,
    required this.streakDays,
    required this.currentXP,
    required this.maxXP,
    this.rank = 'Bronze',
  });

  @override
  Widget build(BuildContext context) {
    final xpProgress = maxXP > 0 ? (currentXP / maxXP).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8A020), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryOrange.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar RPG — sesuai desain Stitch (gambar karakter dalam lingkaran)
              ClipOval(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                  ),
                  child: Image.asset(
                    'assets/images/apex_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('⚔️', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level + Streak badges
                    Row(
                      children: [
                        _Badge(
                          label: 'LEVEL $currentLevel',
                          bg: Colors.white.withOpacity(0.25),
                        ),
                        const SizedBox(width: 8),
                        _Badge(
                          label: '🔥 $streakDays Hari',
                          bg: Colors.white.withOpacity(0.25),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Nama hero
                    Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      RPGTitleHelper.title(rank),
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // XP Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PENGALAMAN (XP)',
                style: GoogleFonts.nunitoSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                '$currentXP / $maxXP',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bar track
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: xpProgress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  const _Badge({required this.label, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
