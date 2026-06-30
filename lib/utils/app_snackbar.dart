import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Helper untuk snackbar yang konsisten di seluruh app.
///
/// Usage:
///   AppSnackbar.success(context, 'Makanan berhasil ditambahkan!');
///   AppSnackbar.error(context, 'Terjadi kesalahan, coba lagi.');
///   AppSnackbar.info(context, 'Data disinkronkan.');
///   AppSnackbar.xp(context, '+20 XP — Quest selesai!');
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message, {String? emoji}) {
    _show(
      context,
      message: message,
      emoji: emoji ?? '✅',
      backgroundColor: const Color(0xFF1B5E20),
      duration: const Duration(seconds: 2),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      emoji: '❌',
      backgroundColor: const Color(0xFFB71C1C),
      duration: const Duration(seconds: 3),
    );
  }

  static void info(BuildContext context, String message, {String? emoji}) {
    _show(
      context,
      message: message,
      emoji: emoji ?? 'ℹ️',
      backgroundColor: const Color(0xFF1A237E),
      duration: const Duration(seconds: 2),
    );
  }

  /// Snackbar khusus XP gain — gold themed
  static void xp(BuildContext context, String message) {
    _show(
      context,
      message: message,
      emoji: '⚡',
      backgroundColor: const Color(0xFF7B4F00),
      duration: const Duration(seconds: 2),
    );
  }

  /// Snackbar saat food ditambahkan dengan rarity color
  static void foodAdded(BuildContext context, String foodName, String rarity) {
    final color = switch (rarity) {
      'Legendary' => const Color(0xFF7B4F00),
      'Epic'      => const Color(0xFF4A148C),
      'Rare'      => const Color(0xFFBF360C),
      _           => const Color(0xFF263238),
    };
    final emoji = switch (rarity) {
      'Legendary' => '👑',
      'Epic'      => '💜',
      'Rare'      => '🔶',
      _           => '✅',
    };
    _show(
      context,
      message: '$foodName ditambahkan!${rarity != "Common" ? " [$rarity]" : ""}',
      emoji: emoji,
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required String emoji,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
