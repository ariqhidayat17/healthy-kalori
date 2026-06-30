
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/debug_overlay.dart';
import 'models/calorie_provider.dart';
import 'utils/notification_helper.dart';
import 'utils/prefs_service.dart';
import 'services/smart_notification_service.dart';
import 'config/app_colors.dart';
import 'config/app_theme.dart';
import 'models/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await PrefsService.init();
  await NotificationHelper.init();

  // Jadwalkan smart notifications berdasarkan data user terkini
  if (PrefsService.i.notificationsEnabled) {
    SmartNotificationService.refreshAndReschedule();
  }

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalorieProvider()..loadTodayCalories()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bnbDarkTheme = BottomNavigationBarThemeData(
      backgroundColor: AppColors.kDarkSurface,
      selectedItemColor: AppColors.kPrimaryOrange,
      unselectedItemColor: AppColors.kDarkTextSub,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
    const bnbLightTheme = BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.kPrimaryOrange,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
    return MaterialApp(
      title: 'Healthy Calories',
      theme: AppTheme.light.copyWith(bottomNavigationBarTheme: bnbLightTheme),
      darkTheme: AppTheme.dark.copyWith(bottomNavigationBarTheme: bnbDarkTheme),
      themeMode: themeProvider.themeMode,
      home: kDebugMode
          ? DebugOverlay(child: const SplashScreen())
          : const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

