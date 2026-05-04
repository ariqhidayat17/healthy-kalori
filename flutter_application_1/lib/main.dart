
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';
import 'screens/debug_overlay.dart';
import 'models/calorie_provider.dart';
import 'utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Muat environment variables dari .env
  await dotenv.load(fileName: '.env');
  await NotificationHelper.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CalorieProvider()..loadTodayCalories()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your AI Coach',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFD4AF37),           // Emas utama
          secondary: Color(0xFFF5D76E),         // Emas muda / highlight
          tertiary: Color(0xFFB8860B),          // Emas tua / shadow
          surface: Color(0xFF1A1A1A),           // Surface abu gelap
          surfaceContainer: Color(0xFF222222),  // Card background
          surfaceContainerHighest: Color(0xFF2A2A2A),
          surfaceContainerLow: Color(0xFF111111),
          onPrimary: Color(0xFF0D0D0D),         // Teks di atas emas
          onSecondary: Color(0xFF0D0D0D),
          onSurface: Color(0xFFF0E6C8),         // Teks utama (krem hangat)
          onSurfaceVariant: Color(0xFFBBAA88),  // Teks sekunder
          error: Color(0xFFCF6679),
        ),
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          foregroundColor: Color(0xFFD4AF37),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF1A1A1A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFF2E2A1E), width: 1),
          ),
          shadowColor: Color(0xFFD4AF3740),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFD4AF37),
            foregroundColor: Color(0xFF0D0D0D),
            textStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: Color(0xFFD4AF3780),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFFD4AF37),
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF3A3020)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF3A3020)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          labelStyle: TextStyle(color: Color(0xFFBBAA88)),
          hintStyle: TextStyle(color: Color(0xFF665C44)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Color(0xFFD4AF37) : Color(0xFF555555)),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? Color(0xFFD4AF3760) : Color(0xFF2A2A2A)),
        ),
        listTileTheme: ListTileThemeData(
          tileColor: Color(0xFF1A1A1A),
          textColor: Color(0xFFF0E6C8),
          iconColor: Color(0xFFD4AF37),
        ),
        dividerTheme: DividerThemeData(color: Color(0xFF2E2A1E)),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF111111),
          selectedItemColor: Color(0xFFD4AF37),
          unselectedItemColor: Color(0xFF555555),
          type: BottomNavigationBarType.fixed,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          contentTextStyle: TextStyle(color: Color(0xFFF0E6C8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Color(0xFFD4AF37),
          linearTrackColor: Color(0xFF2A2A2A),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: kDebugMode
          ? DebugOverlay(child: const SplashScreen())
          : const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
