import 'package:flutter/material.dart';

class AppColors {
  // Primary — Warm Fantasy Gold/Orange
  static const Color kPrimaryGold   = Color(0xFFFFB800);      // Gold utama (primary-container Stitch)
  static const Color kPrimaryOrange  = Color(0xFFFF8C42);    // Orange cerah (secondary-container)
  static const Color kPrimaryAmber   = Color(0xFFFFD93D);    // Kuning keemasan (tertiary-container)
  static const Color kPrimaryDark    = Color(0xFF7C5800);    // Primary dark gold (Stitch primary)
  static const Color kSecondaryDark  = Color(0xFF9B4500);    // Secondary deep orange

  // Accent Colors — Fantasy Elements
  static const Color kHealthRed = Color(0xFFFF6B6B);        // HP/Darah
  static const Color kManaBlue = Color(0xFF6BCBFF);         // Mana/Air
  static const Color kNatureGreen = Color(0xFF6EE7B7);      // Nature/Heal
  static const Color kMysticPurple = Color(0xFFBFA1FF);     // Epic/Legendary
  static const Color kSunsetPink = Color(0xFFFF9ECD);       // Accent lembut

  // ── Light Mode Backgrounds ────────────────────────────────────────────────
  static const Color kBgCream  = Color(0xFFFFF8F3);         // Background utama (Stitch surface)
  static const Color kBgCard   = Color(0xFFFFFFFF);          // Card surface
  static const Color kBgModal  = Color(0xFFFFF3E0);          // Bottom sheet
  static const Color kBgSubtle = Color(0xFFF9ECDB);          // Surface container (Stitch)
  static const Color kOutline  = Color(0xFF837560);          // Outline (Stitch)
  static const Color kOnSurface= Color(0xFF211B11);          // On-surface text (Stitch)

  // ── Dark Mode Backgrounds ─────────────────────────────────────────────────
  static const Color kDarkBg      = Color(0xFF0F0F14);      // Background utama dark
  static const Color kDarkSurface = Color(0xFF1A1A24);      // Card dark
  static const Color kDarkSurface2= Color(0xFF22222F);      // Surface elevated
  static const Color kDarkModal   = Color(0xFF1E1E2C);      // Bottom sheet dark
  static const Color kDarkBorder  = Color(0xFF2E2E3E);      // Border dark
  static const Color kDarkText    = Color(0xFFF0F0F8);      // Primary text dark
  static const Color kDarkTextSub = Color(0xFFAAAAAE);      // Secondary text dark

  // Gradient Backgrounds
  static const LinearGradient kGradientSunset = LinearGradient(
    colors: [Color(0xFFFF8C42), Color(0xFFFFB800), Color(0xFFFFD93D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient kGradientOcean = LinearGradient(
    colors: [Color(0xFF6BCBFF), Color(0xFF4A90FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient kGradientForest = LinearGradient(
    colors: [Color(0xFF6EE7B7), Color(0xFF27C693)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Rarity Colors
  static const Color kRarityCommon    = Color(0xFFB0BEC5);
  static const Color kRarityRare      = Color(0xFFFF8C42);
  static const Color kRarityEpic      = Color(0xFFBFA1FF);
  static const Color kRarityLegendary = Color(0xFFFFD93D);

  // ── Shadows ────────────────────────────────────────────────────────────────
  static List<BoxShadow> kSoftShadow = [
    BoxShadow(
      color: kPrimaryOrange.withValues(alpha: 0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> kDarkSoftShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ───────────────────────────────────────────────────────────────────────────
  // STITCH MATERIAL 3 TOKENS — diekstrak langsung dari tailwind.config
  // di setiap code.html Stitch. Ini sumber kebenaran warna yang presisi,
  // BUKAN tebakan dari screenshot. Gunakan token ini untuk widget baru
  // yang mengikuti desain Stitch "Adventurer's Vitality".
  // ───────────────────────────────────────────────────────────────────────────
  static const Color stPrimary               = Color(0xFF7C5800);
  static const Color stOnPrimary              = Color(0xFFFFFFFF);
  static const Color stPrimaryContainer       = Color(0xFFFFB800);
  static const Color stOnPrimaryContainer     = Color(0xFF6B4C00);
  static const Color stPrimaryFixed           = Color(0xFFFFDEA8);
  static const Color stPrimaryFixedDim        = Color(0xFFFFBA20);
  static const Color stOnPrimaryFixed         = Color(0xFF271900);
  static const Color stOnPrimaryFixedVariant  = Color(0xFF5E4200);
  static const Color stInversePrimary         = Color(0xFFFFBA20);

  static const Color stSecondary              = Color(0xFF9B4500);
  static const Color stOnSecondary            = Color(0xFFFFFFFF);
  static const Color stSecondaryContainer     = Color(0xFFFC8A40);
  static const Color stOnSecondaryContainer   = Color(0xFF672C00);
  static const Color stSecondaryFixed         = Color(0xFFFFDBC9);
  static const Color stSecondaryFixedDim      = Color(0xFFFFB68D);
  static const Color stOnSecondaryFixed       = Color(0xFF331200);
  static const Color stOnSecondaryFixedVariant= Color(0xFF763300);

  static const Color stTertiary               = Color(0xFF705D00);
  static const Color stTertiaryContainer      = Color(0xFFE6C224);
  static const Color stOnTertiaryContainer    = Color(0xFF615000);
  static const Color stTertiaryFixed          = Color(0xFFFFE173);
  static const Color stTertiaryFixedDim       = Color(0xFFE8C426);
  static const Color stOnTertiary             = Color(0xFFFFFFFF);
  static const Color stOnTertiaryFixed        = Color(0xFF221B00);
  static const Color stOnTertiaryFixedVariant = Color(0xFF554500);

  static const Color stBackground             = Color(0xFFFFF8F3);
  static const Color stOnBackground           = Color(0xFF211B11);
  static const Color stSurface                = Color(0xFFFFF8F3);
  static const Color stSurfaceTint             = Color(0xFF7C5800);
  static const Color stSurfaceBright           = Color(0xFFFFF8F3);
  static const Color stSurfaceDim              = Color(0xFFE5D8C8);
  static const Color stOnSurface               = Color(0xFF211B11);
  static const Color stOnSurfaceVariant         = Color(0xFF514532);
  static const Color stSurfaceVariant           = Color(0xFFEDE1D0);
  static const Color stSurfaceContainerLowest   = Color(0xFFFFFFFF);
  static const Color stSurfaceContainerLow      = Color(0xFFFFF2E1);
  static const Color stSurfaceContainer         = Color(0xFFF9ECDB);
  static const Color stSurfaceContainerHigh     = Color(0xFFF3E6D6);
  static const Color stSurfaceContainerHighest  = Color(0xFFEDE1D0);
  static const Color stInverseSurface           = Color(0xFF362F24);
  static const Color stInverseOnSurface         = Color(0xFFFCEFDE);

  static const Color stOutline                  = Color(0xFF837560);
  static const Color stOutlineVariant           = Color(0xFFD5C4AB);

  static const Color stError                    = Color(0xFFBA1A1A);
  static const Color stOnError                  = Color(0xFFFFFFFF);
  static const Color stErrorContainer           = Color(0xFFFFDAD6);
  static const Color stOnErrorContainer         = Color(0xFF93000A);

  // ── Spacing tokens (dari tailwind.config "spacing") ───────────────────────
  static const double stSpaceXs   = 4;
  static const double stSpaceSm   = 8;
  static const double stSpaceMd   = 16;
  static const double stSpaceLg   = 24;
  static const double stSpaceXl   = 32;
  static const double stContainerMargin = 20;
  static const double stStackGap  = 12;

  // ── Border radius tokens ───────────────────────────────────────────────────
  static const double stRadiusDefault = 4;
  static const double stRadiusLg      = 8;
  static const double stRadiusXl      = 12;
  static const double stRadiusFull    = 9999;
}