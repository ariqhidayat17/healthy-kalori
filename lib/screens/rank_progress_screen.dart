import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';
import '../widgets/fantasy_rank_badge.dart';
import '../widgets/fantasy_card.dart';
import '../utils/prefs_service.dart';
import '../models/calorie_provider.dart';
import 'package:provider/provider.dart';

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
            const SizedBox(height: 24),

            // 4. Papan Peringkat
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Papan Peringkat', style: GoogleFonts.montserrat(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                )),
                Text('Lihat Semua', style: GoogleFonts.nunitoSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.stPrimaryFixed : AppColors.stPrimary,
                )),
              ],
            ),
            const SizedBox(height: 12),
            _buildLeaderboard(isDark),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ─────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isDark) {
    final rankName = _getRankDisplayName(_currentRank);
    final xpNeeded = (_xpForNextRank - _currentXP).clamp(0, _xpForNextRank);
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
      // arena-gradient: radial-gradient dark background
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.2,
          colors: [Color(0xFF362F24), Color(0xFF211B11)],
        ),
        borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
        // glow-pulse shadow: rgba(255,184,0,0.4)
        boxShadow: [BoxShadow(color: AppColors.stPrimaryContainer.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Rank badge — w-40 h-40, glow-pulse
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.stPrimaryContainer.withOpacity(0.2),
              boxShadow: [
                BoxShadow(color: AppColors.stPrimaryContainer.withOpacity(0.4), blurRadius: 25),
                BoxShadow(color: AppColors.stPrimaryContainer.withOpacity(0.8), blurRadius: 50),
              ],
            ),
            child: Center(
              child: Text(
                _getRankEmoji(_currentRank),
                style: const TextStyle(fontSize: 80),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .custom(duration: 3.seconds, curve: Curves.easeInOut,
                  builder: (ctx, v, child) => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: AppColors.stPrimaryContainer.withOpacity(0.4 + v * 0.4),
                        blurRadius: 10 + v * 15,
                      )],
                    ),
                    child: child,
                  )),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16), // mb-lg

          // Rank name — display-hero font
          Text(rankName, style: GoogleFonts.montserrat(
            fontSize: 36, fontWeight: FontWeight.w900,
            letterSpacing: -0.02 * 36, height: 40 / 36,
            color: AppColors.stPrimaryContainer,
          )),

          // 5 bintang
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (_) =>
              Icon(Icons.star_rounded, color: AppColors.stPrimary, size: 24)),
          ),
          const SizedBox(height: 16), // mb-md

          // XP bar — max-w-[280px]
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('XP', style: GoogleFonts.nunitoSans(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.stOutline,
                    )),
                    Text('${fmt(_currentXP)} / ${fmt(_xpForNextRank)}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.stOutline,
                      )),
                  ],
                ),
                const SizedBox(height: 4),
                // h-4, bg-surface-container-high, gradient primary→secondary-container
                Stack(children: [
                  Container(height: 16, decoration: BoxDecoration(
                    color: AppColors.stSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                    border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3), width: 1),
                  )),
                  FractionallySizedBox(
                    widthFactor: _progress,
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.stPrimary, AppColors.stSecondaryContainer],
                        ),
                        borderRadius: BorderRadius.circular(AppColors.stRadiusFull),
                      ),
                      // animated shimmer overlay
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
      ('Legend', Icons.workspace_premium_rounded),
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
              _RewardItem(icon: Icons.smart_toy_rounded, label: 'Coach Premium', isDark: isDark),
              _RewardItem(icon: Icons.trending_up_rounded, label: 'Bonus XP +10%', isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────
  Widget _buildLeaderboard(bool isDark) {
    // Mock leaderboard data — sesuai HTML asli
    final entries = [
      (_currentXP, PrefsService.i.name, _currentRank, true),
      (12840, 'Arya_Storm', 'Mythic Legend', false),
      (11200, 'Green_Arrow', 'Mythic Legend', false),
      (9850, 'Pyromancer99', 'Legend IV', false),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    final userRank = entries.indexWhere((e) => e.$4) + 1;

    return Column(
      children: [
        // User row highlighted — bg-primary-container + ring-2 ring-primary
        _LeaderboardRow(
          position: userRank,
          name: '${PrefsService.i.name} (Paladin)',
          subtitle: '$_currentRank',
          xp: _currentXP,
          isHighlighted: true,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        ...entries.where((e) => !e.$4).take(3).toList().asMap().entries.map((e) {
          final pos = e.key + 1;
          final (xp, name, title, _) = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LeaderboardRow(
              position: pos,
              name: name,
              subtitle: title,
              xp: xp,
              isHighlighted: false,
              isDark: isDark,
              opacity: pos == 1 ? 1.0 : (pos == 2 ? 0.9 : 0.8),
            ),
          );
        }),
      ],
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

class _LeaderboardRow extends StatelessWidget {
  final int position;
  final String name, subtitle;
  final int xp;
  final bool isHighlighted, isDark;
  final double opacity;

  const _LeaderboardRow({
    required this.position, required this.name, required this.subtitle,
    required this.xp, required this.isHighlighted, required this.isDark,
    this.opacity = 1.0,
  });

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fg = isHighlighted ? AppColors.stOnPrimaryContainer
        : (isDark ? AppColors.kDarkText : AppColors.stOnSurface);
    final sub = isHighlighted ? AppColors.stOnPrimaryContainer.withOpacity(0.8)
        : (isDark ? AppColors.kDarkTextSub : AppColors.stOnSurfaceVariant);

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(AppColors.stSpaceMd),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.stPrimaryContainer
              : (isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer),
          borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
          border: isHighlighted
              ? Border.all(color: AppColors.stPrimary, width: 2)
              : Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
          boxShadow: isHighlighted
              ? [BoxShadow(color: AppColors.stPrimary.withOpacity(0.15), blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 32,
              child: Text('$position', style: GoogleFonts.montserrat(
                fontSize: 20, fontWeight: FontWeight.w900, color: fg))),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighlighted ? AppColors.stPrimaryFixed
                    : (isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHigh),
                border: Border.all(
                  color: isHighlighted ? AppColors.stOnPrimaryContainer.withOpacity(0.2)
                      : AppColors.stOutlineVariant.withOpacity(0.3), width: 2),
              ),
              child: Center(child: Icon(Icons.person_rounded,
                color: isHighlighted ? AppColors.stOnPrimaryContainer : AppColors.stOutline, size: 24)),
            ),
            const SizedBox(width: AppColors.stSpaceMd),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.nunitoSans(
                  fontSize: 14, fontWeight: FontWeight.w700, color: fg),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: sub)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_fmt(xp), style: GoogleFonts.montserrat(
                fontSize: 18, fontWeight: FontWeight.w900, color: fg)),
              Text('XP', style: GoogleFonts.nunitoSans(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1, color: sub)),
            ]),
          ],
        ),
      ),
    );
  }
}
