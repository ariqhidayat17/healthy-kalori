import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';
import '../utils/prefs_service.dart';
import '../utils/rpg_title_helper.dart';

/// AppBar RPG yang konsisten di semua screen — sesuai desain Stitch.
///
/// Layout:
///   [Avatar bulat] [Lvl. X Title]     [Ikon Rank]
///                  [SCREEN SUBTITLE]
///
/// Gunakan sebagai PreferredSizeWidget di Scaffold.appBar.
///
/// Contoh:
///   appBar: RPGAppBar(screenKey: 'food'),
///   appBar: RPGAppBar(screenKey: 'quest', actions: [...]),
class RPGAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenKey;
  final List<Widget>? actions;
  final bool showSubtitle;

  const RPGAppBar({
    super.key,
    required this.screenKey,
    this.actions,
    this.showSubtitle = true,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(showSubtitle ? 64 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.kDarkBg : AppColors.kBgCream;
    final textColor = isDark ? AppColors.kDarkText : const Color(0xFF211B11);
    final subColor = isDark ? AppColors.kDarkTextSub : const Color(0xFF837560);

    return Consumer<CalorieProvider>(
      builder: (context, provider, _) {
        final name = PrefsService.i.name;
        final level = provider.targetCalories > 0
            ? _readLevel()
            : 1;
        final rank = PrefsService.i.userLevel.isNotEmpty
            ? PrefsService.i.userLevel
            : 'Bronze';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Container(
            color: bgColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar ────────────────────────────────────────────────
                _AvatarCircle(rank: rank, isDark: isDark),
                const SizedBox(width: 10),

                // ── Title + Subtitle ──────────────────────────────────────
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RPGTitleHelper.fullTitle(level, rank),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      if (showSubtitle)
                        Text(
                          RPGTitleHelper.screenSubtitle(screenKey),
                          style: GoogleFonts.nunito(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Actions + Rank Icon ───────────────────────────────────
                if (actions != null) ...actions!,
                _RankIconButton(rank: rank, isDark: isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  int _readLevel() {
    final xp = PrefsService.i.userXP;
    return (xp / 150).floor() + 1;
  }
}

// ── Avatar bulat dengan initial nama ─────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String rank;
  final bool isDark;

  const _AvatarCircle({required this.rank, required this.isDark});

  Color get _ringColor => switch (rank) {
        'Gold'    => AppColors.kPrimaryGold,
        'Diamond' => AppColors.kManaBlue,
        'Spartan' => AppColors.kMysticPurple,
        'Silver'  => Colors.grey[400]!,
        _         => AppColors.kPrimaryOrange,
      };

  @override
  Widget build(BuildContext context) {
    final name = PrefsService.i.name;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppColors.kDarkSurface2 : const Color(0xFFF3E6D6),
        border: Border.all(color: _ringColor, width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _ringColor,
          ),
        ),
      ),
    );
  }
}

// ── Rank icon button (kanan) ──────────────────────────────────────────────────

class _RankIconButton extends StatelessWidget {
  final String rank;
  final bool isDark;

  const _RankIconButton({required this.rank, required this.isDark});

  // Ikon rank custom (SVG-style menggunakan icon bawaan)
  IconData get _icon => switch (rank) {
        'Gold'    => Icons.military_tech_rounded,
        'Diamond' => Icons.diamond_rounded,
        'Spartan' => Icons.shield_rounded,
        'Silver'  => Icons.workspace_premium_rounded,
        _         => Icons.emoji_events_outlined,
      };

  Color get _color => switch (rank) {
        'Gold'    => AppColors.kPrimaryGold,
        'Diamond' => AppColors.kManaBlue,
        'Spartan' => AppColors.kMysticPurple,
        'Silver'  => Colors.grey[400]!,
        _         => const Color(0xFFCD7F32),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.12),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Icon(_icon, color: _color, size: 20),
    );
  }
}
