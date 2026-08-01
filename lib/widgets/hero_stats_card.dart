import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Hero Stats Card — diterjemahkan presisi dari section
/// "Header: Hero Stats Card" di beranda/code.html.
///
/// Perbedaan penting dari implementasi sebelumnya (yang salah):
/// - Avatar BUKAN lingkaran (ClipOval) — itu rounded-xl (12px), persegi 64x64
/// - Border avatar 4px warna #ffdea8 (primary-fixed), BUKAN putih transparan
/// - Badge Level pakai bg #ffdea8 + text on-primary-fixed-variant (#5e4200),
///   BUKAN Colors.white.withOpacity(0.25)
/// - Badge streak pakai bg black/20, BUKAN warna sama dengan badge level
/// - Card pakai padding 16 (p-md), BUKAN 20
/// - Border radius card 12px (rounded-xl), BUKAN 24
/// - Tidak ada subtitle "Title" di bawah nama — HTML cuma render nama
///   (h2.font-headline-md) tanpa baris title RPG terpisah
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
      padding: const EdgeInsets.all(16), // p-md
      decoration: BoxDecoration(
        // .hero-gradient: linear-gradient(135deg, #ffb800 0%, #fc8a40 100%)
        gradient: const LinearGradient(
          colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // rounded-xl
        boxShadow: [
          // shadow-lg dari Tailwind
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 10)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // mb-sm (8px)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar — w-16 h-16 (64px), rounded-xl, border-4 #ffdea8
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                    border: ['Bronze', 'Silver', 'Gold', 'Diamond', 'Spartan'].contains(rank)
                        ? null
                        : Border.all(color: AppColors.stPrimaryFixed, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8), // sedikit lebih kecil dari border luar
                    child: Image.asset(
                      rank == 'Bronze' ? 'assets/images/bronze.png' :
                      rank == 'Silver' ? 'assets/images/silver.png' :
                      rank == 'Gold' ? 'assets/images/gold.png' :
                      rank == 'Diamond' ? 'assets/images/diamond.png' :
                      rank == 'Spartan' ? 'assets/images/spartan.png' :
                      'assets/images/apex_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white.withOpacity(0.3),
                        child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 28))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // gap-sm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // gap-xs row: badge Level + badge Streak
                      Row(
                        children: [
                          // bg #ffdea8, text on-primary-fixed-variant (#5e4200)
                          _Badge(
                            label: 'LEVEL $currentLevel',
                            bg: AppColors.stPrimaryFixed,
                            fg: AppColors.stOnPrimaryFixedVariant,
                          ),
                          const SizedBox(width: 4), // gap-xs
                          // bg black/20, text putih (default)
                          _Badge(
                            label: '🔥 $streakDays Hari',
                            bg: Colors.black.withOpacity(0.2),
                            fg: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4), // mt-1
                      // h2.font-headline-md text-lg leading-tight — HANYA nama,
                      // tidak ada subtitle title RPG di bawahnya (HTML tidak punya itu)
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w700, // headline-md weight 700
                          color: Colors.white,
                          height: 1.2, // leading-tight
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // XP section — space-y-1
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PENGALAMAN (XP)',
                    style: GoogleFonts.nunitoSans( // font-label-bold
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9), // opacity-90
                    ),
                  ),
                  Text(
                    '$currentXP / $maxXP',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // h-3 (12px) bar, bg black/20, rounded-full, progress-gloss
              Container(
                height: 12,
                padding: const EdgeInsets.all(1), // p-[1px]
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: xpProgress),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v,
                      child: Container(color: Colors.white),
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
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100), // rounded-full
      ),
      child: Text(
        label,
        style: GoogleFonts.nunitoSans( // font-label-bold
          fontSize: 10, // text-[10px] untuk Level badge; streak text-xs(12px) tapi disamakan utk konsistensi
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.5, // tracking-wider
        ),
      ),
    );
  }
}
