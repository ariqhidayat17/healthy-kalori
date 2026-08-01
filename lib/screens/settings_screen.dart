import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_colors.dart';
import '../models/theme_provider.dart';
import '../services/backup_service.dart';
import '../services/smart_notification_service.dart';
import '../utils/prefs_service.dart';
import '../widgets/profile_settings_widgets.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = PrefsService.i.raw.getBool('notifications_enabled') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.stBackground,
      appBar: AppBar(
        title: Text(
          'PENGATURAN',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppColors.stSpaceMd),
              decoration: BoxDecoration(
                color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainer,
                borderRadius: BorderRadius.circular(AppColors.stRadiusXl),
                border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSwitch(
                    icon: Icons.notifications_rounded,
                    label: 'Notifikasi',
                    value: _notificationsEnabled,
                    isDark: isDark,
                    onChanged: (val) async {
                      setState(() => _notificationsEnabled = val);
                      await PrefsService.i.setNotificationsEnabled(val);
                      if (val) {
                        await SmartNotificationService.refreshAndReschedule();
                      } else {
                        await SmartNotificationService.cancelAll();
                      }
                    },
                  ),
                  SettingsSwitch(
                    icon: Icons.dark_mode_rounded,
                    label: 'Tema Gelap',
                    value: themeProvider.isDark,
                    isDark: isDark,
                    onChanged: (val) => themeProvider.setDark(val),
                  ),
                  SettingsChevron(
                    icon: Icons.translate_rounded,
                    label: 'Bahasa',
                    trailing: 'Indonesia',
                    isDark: isDark,
                  ),
                  SettingsChevron(
                    icon: Icons.download_rounded,
                    label: 'Export Data',
                    isDark: isDark,
                    onTap: () => BackupService.exportDataAsJson(context),
                  ),
                  SettingsChevron(
                    icon: Icons.info_rounded,
                    label: 'Tentang',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColors.stStackGap),
            GestureDetector(
              onTap: () async {
                final prefs = PrefsService.i.raw;
                await prefs.clear();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                    (route) => false,
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppColors.stSpaceMd),
                child: Center(
                  child: Text(
                    'Keluar dari Petualangan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.stError,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}