import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/calorie_provider.dart';

// Import Widgets Baru
import '../widgets/welcome_card.dart';
import '../widgets/weight_tracker_card.dart';
import '../widgets/water_tracker_card.dart';
import '../widgets/workout_tracker_card.dart';
import '../widgets/home_info_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  String _lastWorkoutDate = 'Belum ada data';
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWorkoutStats();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyWrapUp();
    });
  }

  Future<void> _checkDailyWrapUp() async {
    final now = DateTime.now();
    if (now.hour >= 20) { // Setelah jam 8 malam
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('dd/MM/yyyy').format(now);
      final lastWrapup = prefs.getString('last_wrapup_date') ?? '';

      if (lastWrapup != today && mounted) {
        await prefs.setString('last_wrapup_date', today);
        _showWrapUpModal();
      }
    }
  }

  void _showWrapUpModal() {
    final calorieProvider = context.read<CalorieProvider>();
    final consumed = calorieProvider.totalConsumedCalories;
    final target = calorieProvider.targetCalories;
    final isSurplus = consumed > target;
    final difference = (consumed - target).abs();

    String title;
    String message;
    IconData icon;
    Color iconColor;

    if (consumed == 0) {
      title = "Hari Ini Kosong?";
      message = "Kamu belum mencatat apapun hari ini. Jangan lupa makan dan catat ya!";
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.orange;
    } else if (difference <= 200) {
      title = "Sempurna! 🎯";
      message = "Hebat! Kalorimu hari ini ($consumed kcal) sangat mendekati target ($target kcal). Pertahankan konsistensi ini!";
      icon = Icons.star_rounded;
      iconColor = Colors.yellow;
    } else if (isSurplus) {
      title = "Surplus Kalori 📈";
      message = "Kamu kelebihan $difference kcal hari ini. Cocok jika sedang bulking, tapi hati-hati jika sedang cutting!";
      icon = Icons.trending_up_rounded;
      iconColor = Colors.greenAccent;
    } else {
      title = "Defisit Kalori 📉";
      message = "Kamu masih kurang $difference kcal hari ini. Sangat bagus untuk fat loss, tapi pastikan nutrisimu tetap cukup!";
      icon = Icons.trending_down_rounded;
      iconColor = Colors.blueAccent;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Siap Untuk Besok!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hasProfile = prefs.getBool('has_profile') ?? false;

    if (hasProfile) {
      setState(() {
        _userProfile = UserProfile(
          name: prefs.getString('name') ?? '',
          age: prefs.getInt('age') ?? 0,
          weight: prefs.getDouble('weight') ?? 0,
          height: prefs.getDouble('height') ?? 0,
          gender: prefs.getString('gender') ?? 'Pria',
          activityLevel: prefs.getString('activity_level') ?? 'Sedang',
          goal: prefs.getString('goal') ?? 'Bulking',
        );
      });
    }
  }

  Future<void> _loadWorkoutStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String lastWorkoutStr = prefs.getString('last_workout_date') ?? '';
    int streak = prefs.getInt('workout_streak') ?? 0;

    if (lastWorkoutStr.isNotEmpty) {
      final now = DateTime.now();
      final today = DateFormat('dd/MM/yyyy').format(now);
      final yesterday = DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1)));

      if (lastWorkoutStr != today && lastWorkoutStr != yesterday) {
        // Streak hilang jika tidak latihan hari ini atau kemarin
        streak = 0;
        await prefs.setInt('workout_streak', 0);
      }
    }

    setState(() {
      _lastWorkoutDate = lastWorkoutStr.isEmpty ? 'Belum ada data' : lastWorkoutStr;
      _streakDays = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your AI Coach')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WelcomeCard(userProfile: _userProfile),
            const SizedBox(height: 20),
            WeightTrackerCard(
              userProfile: _userProfile,
              onLogAdded: _loadUserProfile,
            ),
            const SizedBox(height: 20),
            const WaterTrackerCard(),
            const SizedBox(height: 20),
            WorkoutTrackerCard(
              streakDays: _streakDays,
              lastWorkoutDate: _lastWorkoutDate,
              onLogAdded: _loadWorkoutStats,
            ),
            const SizedBox(height: 20),
            const HomeInfoSection(),
          ],
        ),
      ),
    );
  }
}
