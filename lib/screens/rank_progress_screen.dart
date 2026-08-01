import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/fantasy_card.dart';
import '../utils/prefs_service.dart';
import '../models/calorie_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_hero_card.dart';

class RankProgressScreen extends StatefulWidget {
  const RankProgressScreen({super.key});

  @override
  State<RankProgressScreen> createState() => _RankProgressScreenState();
}

class _RankProgressScreenState extends State<RankProgressScreen> {
  int _currentXP = 0;
  String _currentRank = 'Bronze';
  String _nextRank = 'Silver';
  int _xpForNextRank = 500;
  double _progress = 0.0;

  static const List<String> _rankOrder = ['Bronze', 'Silver', 'Gold', 'Diamond', 'Spartan'];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final stats = await GamificationService().getUserStats();
    final xp = stats['xp'] as int? ?? 0;
    final rank = stats['rank'] as String? ?? 'Bronze';
    final thresholds = GamificationService.rankThresholds;

    int currentRankBaseXP = thresholds[rank] ?? 0;
    int nextRankXP = xp;
    String nextRankName = 'Max Rank';

    final currentIndex = _rankOrder.indexOf(rank);
    if (currentIndex >= 0 && currentIndex < _rankOrder.length - 1) {
      final nextRankKey = _rankOrder[currentIndex + 1];
      nextRankXP = thresholds[nextRankKey] ?? xp;
      nextRankName = nextRankKey;
    }

    double progress = 0.0;
    if (nextRankXP > currentRankBaseXP) {
      progress = (xp - currentRankBaseXP) / (nextRankXP - currentRankBaseXP);
    } else {
      progress = 1.0;
    }

    setState(() {
      _currentXP = xp;
      _currentRank = rank;
      _nextRank = nextRankName;
      _xpForNextRank = nextRankXP;
      _progress = progress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // arena-gradient: radial-gradient(circle at top, #362f24 0%, #211b11 100%)
    // dipakai sebagai bg hero section (bukan seluruh screen)
    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.stBackground,
      appBar: RPGAppBar(screenKey: 'rank', showSubtitle: true), // rank punya subtitle "Gold Warrior"
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Section — arena-gradient bg, rank badge, 5 stars, XP bar
            _buildHeroSection(isDark),
            const SizedBox(height: 24), // space-y-lg

            // 2. Jalur Pendakian (timeline)
            Text('Jalur Pendakian', style: GoogleFonts.montserrat(
              fontSize: 18, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
            )),
            const SizedBox(height: 16),
            _buildRankTimeline(isDark),
            const SizedBox(height: 24),

            // 3. Next Rank Card
            _buildNextRankCard(isDark),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ─────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDark) {
    final rankName = _getRankDisplayName(_currentRank);
    final rankTheme = RankTheme.fromRank(_currentRank);

    // Format ribuan
    String fmt(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20), // py-xl
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: rankTheme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        border: Border.all(color: rankTheme.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rankTheme.glowColor,
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Rank badge
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rankTheme.borderColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: rankTheme.borderColor.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                _currentRank == 'Bronze' ? 'assets/images/bronze.png' :
                _currentRank == 'Silver' ? 'assets/images/silver.png' :
                _currentRank == 'Gold' ? 'assets/images/gold.png' :
                _currentRank == 'Diamond' ? 'assets/images/diamond.png' :
                _currentRank == 'Spartan' ? 'assets/images/spartan.png' :
                'assets/images/apex_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white10,
                  child: Center(
                    child: Text(
                      _getRankEmoji(_currentRank),
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .custom(duration: 3.seconds, curve: Curves.easeInOut,
              builder: (ctx, v, child) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: rankTheme.borderColor.withOpacity(0.4 + v * 0.4),
                    blurRadius: 10 + v * 15,
                  )],
                ),
                child: child,
              )),
          const SizedBox(height: 16), // mb-lg

          // Rank name
          Text(
            rankTheme.title,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: rankTheme.borderColor,
            ),
          ),

          // 5 bintang
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (_) =>
              Icon(Icons.star_rounded, color: rankTheme.borderColor, size: 24)),
          ),
          const SizedBox(height: 16), // mb-md

          // XP bar
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XP PROGRESS', style: GoogleFonts.nunitoSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                      letterSpacing: 1,
                    )),
                    Text('${fmt(_currentXP)} / ${fmt(_xpForNextRank)}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      )),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: _progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.stPrimaryFixed,
                            rankTheme.borderColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Jalur Pendakian (Timeline) ───────────────────────────────────────────
  Widget _buildRankTimeline(bool isDark) {
    final ranks = [
      ('Bronze', Icons.shield_rounded),
      ('Silver', Icons.shield_moon_rounded),
      ('Gold', Icons.military_tech_rounded),
      ('Diamond', Icons.diamond_rounded),
      ('Spartan', Icons.workspace_premium_rounded),
    ];
    final currentIdx = _rankOrder.indexOf(_currentRank);

    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base line — surface-container-highest
          Positioned(
            left: 0, right: 0, top: 20,
            child: Container(height: 4,
              color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHighest),
          ),
          // Progress line — primary with glow
          Positioned(
            left: 0, top: 20,
            child: Container(
              height: 4,
              width: (MediaQuery.of(context).size.width - 80) * ((currentIdx + 1) / ranks.length),
              decoration: BoxDecoration(
                color: isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary,
                boxShadow: [BoxShadow(color: AppColors.stPrimary.withOpacity(0.5), blurRadius: 8)],
              ),
            ),
          ),
          // Nodes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ranks.asMap().entries.map((e) {
              final idx = e.key;
              final (label, icon) = e.value;
              final isActive = idx <= currentIdx;
              final isCurrent = idx == currentIdx;
              return Column(
                children: [
                  Container(
                    width: isCurrent ? 48 : 40,
                    height: isCurrent ? 48 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? (isCurrent ? AppColors.stPrimaryContainer : AppColors.stPrimary)
                          : (isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHighest),
                      border: Border.all(
                        color: isDark ? AppColors.kDarkBg : AppColors.stBackground,
                        width: 4, // ring-4 ring-background
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                      ] : null,
                    ),
                    child: Icon(
                      icon,
                      size: isCurrent ? 22 : 18,
                      color: isActive
                          ? (isCurrent ? AppColors.stOnPrimaryContainer : AppColors.stOnPrimary)
                          : (isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: isActive ? 1.0 : 0.5,
                    child: Text(label, style: GoogleFonts.nunitoSans(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: isActive
                          ? (isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary)
                          : (isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant),
                    )),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Next Rank Card ────────────────────────────────────────────────────────
  Widget _buildNextRankCard(bool isDark) {
    if (_nextRank == 'Max Rank') {
      return Container(
        padding: const EdgeInsets.all(AppColors.stSpaceMd),
        decoration: BoxDecoration(
          color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLow,
          borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
          border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(child: Text('Kamu sudah mencapai rank tertinggi!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? AppColors.kDarkText : AppColors.stOnSurface))),
          ],
        ),
      );
    }

    final xpNeeded = (_xpForNextRank - _currentXP).clamp(0, _xpForNextRank);
    return Container(
      padding: const EdgeInsets.all(AppColors.stSpaceMd),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLow,
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank preview box — w-20 h-20 bg-surface border rounded-lg
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurface,
                  borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
                  border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
                ),
                child: Center(child: Text(_getRankEmoji(_nextRank), style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_nextRank Warrior', style: GoogleFonts.montserrat(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                        )),
                        // bg-secondary text-on-secondary, rounded-full, uppercase
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.stSecondary,
                            borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                          ),
                          child: Text('Next Rank', style: GoogleFonts.nunitoSans(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppColors.stOnSecondary, letterSpacing: 0.5,
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Butuh $xpNeeded XP lagi untuk naik tingkat.',
                      style: GoogleFonts.inter(fontSize: 14,
                        color: isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          // Divider + reward grid 2x2
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Divider(color: AppColors.stOutlineVariant.withOpacity(0.3), height: 1),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: [
              _RewardItem(icon: Icons.face_retouching_natural_rounded, label: 'Avatar Frame', isDark: isDark),
              _RewardItem(icon: Icons.verified_rounded, label: 'Gelar Eksklusif', isDark: isDark),
              _RewardItem(icon: Icons.face_rounded, label: 'Desain Avatar', isDark: isDark),
              _RewardItem(icon: Icons.trending_up_rounded, label: 'Bonus XP +10%', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  String _getRankDisplayName(String rank) => switch (rank) {
    'Bronze' => 'Bronze Warrior',
    'Silver' => 'Silver Warrior',
    'Gold'   => 'Gold Warrior',
    'Diamond'=> 'Diamond Warrior',
    _        => 'Spartan',
  };

  String _getRankEmoji(String rank) => switch (rank) {
    'Bronze' => '🥉',
    'Silver' => '🥈',
    'Gold'   => '🥇',
    'Diamond'=> '💎',
    _        => '👑',
  };

  String _getRankIcon(String rank) => rank; // kept for compat
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _RewardItem({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface.withOpacity(0.5) : AppColors.stSurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppColors.stRadiusDefault),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.stSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
              style: GoogleFonts.nunitoSans(fontSize: 11, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.kDarkText : AppColors.stOnSurface),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
