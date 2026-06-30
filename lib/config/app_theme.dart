import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized theme untuk Healthy Calories App.
///
/// Gunakan [AppTheme.light] di MaterialApp.theme.
/// Akses spacing via [AppSpacing], radius via [AppRadius].
/// Gunakan [AppTextStyle] untuk typography yang konsisten.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.kPrimaryOrange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.kBgCream,
        fontFamily: GoogleFonts.nunito().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.kBgCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          color: AppColors.kBgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.kPrimaryOrange,
            textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kPrimaryOrange,
            side: const BorderSide(color: AppColors.kPrimaryOrange),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.kPrimaryOrange, width: 1.5),
          ),
          labelStyle: GoogleFonts.nunito(
              color: Colors.black54, fontWeight: FontWeight.w600),
          hintStyle: GoogleFonts.nunito(color: Colors.black38),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          backgroundColor: const Color(0xFF1A1A2E),
          contentTextStyle: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.grey[400]),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.kPrimaryOrange
                  : Colors.grey[300]),
        ),
        dividerTheme: DividerThemeData(
            color: Colors.grey[100], thickness: 1, space: 1),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: AppPageTransitionBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );

  // ── Dark Theme ─────────────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.kPrimaryOrange,
          brightness: Brightness.dark,
          surface: AppColors.kDarkSurface,
          onSurface: AppColors.kDarkText,
        ),
        scaffoldBackgroundColor: AppColors.kDarkBg,
        fontFamily: GoogleFonts.nunito().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.kDarkBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.kDarkText),
          iconTheme:
              const IconThemeData(color: AppColors.kDarkText),
        ),
        cardTheme: CardThemeData(
          color: AppColors.kDarkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.kPrimaryOrange,
            textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kPrimaryOrange,
            side: const BorderSide(color: AppColors.kPrimaryOrange),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.kDarkSurface2,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.kDarkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.kDarkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.kPrimaryOrange, width: 1.5),
          ),
          labelStyle: GoogleFonts.nunito(
              color: AppColors.kDarkTextSub, fontWeight: FontWeight.w600),
          hintStyle: GoogleFonts.nunito(color: AppColors.kDarkTextSub),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          backgroundColor: AppColors.kDarkSurface2,
          contentTextStyle: GoogleFonts.nunito(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.kDarkModal,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.grey[600]),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected)
                  ? AppColors.kPrimaryOrange
                  : AppColors.kDarkBorder),
        ),
        dividerTheme: const DividerThemeData(
            color: AppColors.kDarkBorder, thickness: 1, space: 1),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: AppPageTransitionBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );
}

// ─── Spacing ──────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─── Border Radius ────────────────────────────────────────────────────────────

class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 20;
  static const double xl  = 28;
  static const double full = 100;
}

// ─── Text Styles ──────────────────────────────────────────────────────────────

/// Typography sesuai spesifikasi Stitch "Adventurer's Vitality":
/// - Montserrat ExtraBold/Black → angka, judul besar (display-hero, stat-number)
/// - Inter → body text panjang, deskripsi nutrisi
/// - Nunito Sans → label tombol, tag, caption
class AppTextStyle {
  AppTextStyle._();

  // ── Display / Hero (Montserrat) ──────────────────────────────────────────
  static TextStyle displayHero = GoogleFonts.montserrat(
      fontSize: 32, fontWeight: FontWeight.w800,
      letterSpacing: -0.02 * 32, height: 1.25);
  static TextStyle headlineLg = GoogleFonts.montserrat(
      fontSize: 24, fontWeight: FontWeight.w800, height: 1.33);
  static TextStyle headlineMd = GoogleFonts.montserrat(
      fontSize: 20, fontWeight: FontWeight.w700, height: 1.4);

  // ── Stat Numbers (Montserrat Black) ──────────────────────────────────────
  /// Angka kalori besar, XP, dll
  static TextStyle statNumber = GoogleFonts.montserrat(
      fontSize: 28, fontWeight: FontWeight.w900,
      letterSpacing: 0.02 * 28, height: 1.14);
  static TextStyle numericXl = GoogleFonts.montserrat(
      fontSize: 32, fontWeight: FontWeight.w900);
  static TextStyle numericLg = GoogleFonts.montserrat(
      fontSize: 22, fontWeight: FontWeight.w800);
  static TextStyle numericMd = GoogleFonts.montserrat(
      fontSize: 16, fontWeight: FontWeight.w700);

  // ── Body (Inter) ─────────────────────────────────────────────────────────
  static TextStyle bodyLg = GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle bodyMd = GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, height: 1.43);
  static TextStyle bodySm = GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  // ── Label / Button / Tag (Nunito Sans) ───────────────────────────────────
  static TextStyle labelBold = GoogleFonts.nunitoSans(
      fontSize: 14, fontWeight: FontWeight.w700, height: 1.29);
  static TextStyle labelSm = GoogleFonts.nunitoSans(
      fontSize: 12, fontWeight: FontWeight.w700);
  static TextStyle caption = GoogleFonts.nunitoSans(
      fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5);
}

// ─── Custom Page Transition ───────────────────────────────────────────────────

/// Slide-up + fade dari bawah — lebih halus dari default Android
class AppPageTransitionBuilder extends PageTransitionsBuilder {
  const AppPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeOutCubic;
    final tween = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .chain(CurveTween(curve: curve));
    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve))),
        child: child,
      ),
    );
  }
}
