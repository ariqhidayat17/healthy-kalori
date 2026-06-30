import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';

/// Provider untuk mengelola tema light/dark.
/// Persisten via PrefsService — setting tema tersimpan antar sesi.
///
/// Usage di widget:
///   // Baca tema saat ini
///   final isDark = context.watch<ThemeProvider>().isDark;
///
///   // Toggle
///   context.read<ThemeProvider>().toggle();
class ThemeProvider extends ChangeNotifier {
  static const _kDarkMode = 'dark_mode_enabled';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isLight => _mode == ThemeMode.light;

  /// Inisialisasi dari pref yang tersimpan. Panggil di main() setelah
  /// PrefsService.init().
  Future<void> init() async {
    final saved = PrefsService.i.raw.getBool(_kDarkMode);
    if (saved == null) {
      _mode = ThemeMode.system; // Ikuti sistem jika belum pernah di-set
    } else {
      _mode = saved ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }

  /// Toggle antara dark dan light. Jika sebelumnya system → set ke dark.
  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    await PrefsService.i.raw.setBool(_kDarkMode, isDark);
    notifyListeners();
  }

  /// Set secara eksplisit.
  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    await PrefsService.i.raw.setBool(_kDarkMode, dark);
    notifyListeners();
  }

  /// Ikuti tema sistem (hapus preferensi tersimpan).
  Future<void> useSystemTheme() async {
    _mode = ThemeMode.system;
    await PrefsService.i.raw.remove(_kDarkMode);
    notifyListeners();
  }
}
