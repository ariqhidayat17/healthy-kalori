import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/calorie_provider.dart';
import '../utils/prefs_service.dart';
import '../utils/rpg_title_helper.dart';
import '../screens/settings_screen.dart';
import '../screens/rank_progress_screen.dart';

/// AppBar — diterjemahkan presisi dari <header> di setiap code.html Stitch.
///
/// Spek HTML asli:
/// ```html
/// <header class="bg-surface shadow-sm flex justify-between items-center
///   w-full px-container-margin py-sm border-b border-outline-variant/30
///   sticky top-0 z-40">
///   <div class="flex items-center gap-3">
///     <div class="w-10 h-10 rounded-full border-2 border-primary-container
///       p-0.5 overflow-hidden">
///       <img class="w-full h-full object-cover rounded-full" src="..."/>
///     </div>
///     <h1 class="text-headline-md-mobile font-headline-md-mobile
///       text-primary">Lvl. 24 Paladin</h1>
///   </div>
///   <button class="material-symbols-outlined text-primary"
///     data-icon="military_tech">military_tech</button>
/// </header>
/// ```
///
/// PENTING — perbedaan dari versi sebelumnya (sudah diperbaiki):
/// - Avatar adalah FOTO statis (object-cover), bukan inisial nama
/// - Border avatar SELALU primary-container (gold #ffb800), bukan warna
///   yang berubah-ubah sesuai rank
/// - Icon kanan SELALU military_tech dengan warna primary (#7c5800) solid,
///   bukan icon dinamis (diamond/shield/dst) per rank
/// - Title pakai headline-md-mobile: Montserrat 22px/800, warna primary
/// - Tidak ada subtitle baris kedua di HTML asli — opsi showSubtitle
///   dipertahankan sebagai extension non-spek untuk screen yang butuh,
///   default false agar match HTML
class RPGAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String screenKey;
  final List<Widget>? actions;
  final bool showSubtitle;

  const RPGAppBar({
    super.key,
    required this.screenKey,
    this.actions,
    this.showSubtitle = false, // default false — HTML tidak punya subtitle
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(showSubtitle ? 64 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.kDarkBg : AppColors.stSurface;
    final borderColor = isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant.withOpacity(0.3);

    return Consumer<CalorieProvider>(
      builder: (context, provider, _) {
        final level = _readLevel();
        final rank = PrefsService.i.userLevel.isNotEmpty
            ? PrefsService.i.userLevel
            : 'Bronze';

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: Container(
            color: bgColor,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              boxShadow: [
                // shadow-sm
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8, // py-sm
              left: 20, // px-container-margin
              right: 20,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // gap-3 (12px)
                Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const _AvatarPhoto(),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          RPGTitleHelper.fullTitle(level, rank),
                          style: GoogleFonts.montserrat(
                            // headline-md-mobile: 22px, lineHeight 28px, weight 800
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 28 / 22,
                            color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
                          ),
                        ),
                        // Subtitle non-spek, ditampilkan hanya jika diminta eksplisit
                        if (showSubtitle)
                          Text(
                            RPGTitleHelper.screenSubtitle(screenKey),
                            style: GoogleFonts.nunitoSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (actions != null) ...actions!,
                    // Icon kanan: profile → settings, lainnya → rank progress
                    IconButton(
                      onPressed: () {
                        if (screenKey == 'profile') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        } else if (screenKey != 'rank') {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RankProgressScreen()),
                          );
                        }
                      },
                      icon: Icon(
                        screenKey == 'profile' ? Icons.settings_rounded : Icons.military_tech_rounded,
                        color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
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

// ── Avatar foto — w-10 h-10, rounded-full, border-2 primary-container ────────

class _AvatarPhoto extends StatelessWidget {
  const _AvatarPhoto();

  @override
  Widget build(BuildContext context) {
    final rank = PrefsService.i.userLevel;
    final hasFrame = ['Bronze', 'Silver', 'Gold', 'Diamond', 'Spartan'].contains(rank);

    return Container(
      width: 40,
      height: 40,
      padding: hasFrame ? EdgeInsets.zero : const EdgeInsets.all(2), // p-0.5 (border inset)
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: hasFrame
            ? null
            : const Border.fromBorderSide(
                BorderSide(color: AppColors.stPrimaryContainer, width: 2),
              ),
      ),
      child: ClipOval(
        child: Image.asset(
          rank == 'Bronze' ? 'assets/images/bronze.png' :
          rank == 'Silver' ? 'assets/images/silver.png' :
          rank == 'Gold' ? 'assets/images/gold.png' :
          rank == 'Diamond' ? 'assets/images/diamond.png' :
          rank == 'Spartan' ? 'assets/images/spartan.png' :
          'assets/images/apex_avatar.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.stPrimaryContainer.withOpacity(0.2),
            child: Icon(Icons.person_rounded, color: AppColors.stPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
