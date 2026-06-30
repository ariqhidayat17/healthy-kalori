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

  // Shadows
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
}