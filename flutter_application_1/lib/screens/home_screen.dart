import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/fuzzy_logic.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  int _targetCalories = 0;
  String _lastWorkoutDate = 'Belum ada data';
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadWorkoutStats();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final hasProfile = prefs.getBool('has_profile') ?? false;

    if (hasProfile) {
      final name = prefs.getString('name') ?? '';
      final age = prefs.getInt('age') ?? 0;
      final weight = prefs.getDouble('weight') ?? 0;
      final height = prefs.getDouble('height') ?? 0;
      final gender = prefs.getString('gender') ?? 'Pria';
      final activityLevel = prefs.getString('activity_level') ?? 'Sedang';
      final goal = prefs.getString('goal') ?? 'Bulking';

      final userProfile = UserProfile(
        name: name,
        age: age,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: activityLevel,
        goal: goal,
      );

      final fuzzyLogic = FuzzyLogic();
      final calculatedCalories = fuzzyLogic.calculateCalories(userProfile);

      setState(() {
        _userProfile = userProfile;
        _targetCalories = calculatedCalories;
      });
    }
  }

  Future<void> _loadWorkoutStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastWorkoutDate =
          prefs.getString('last_workout_date') ?? 'Belum ada data';
      _streakDays = prefs.getInt('workout_streak') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bodybuilder Calorie Control')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 20),
            // Removed nutrition summary section
            _buildWorkoutTracker(context),
            const SizedBox(height: 20),
            _buildInfoSection(context),
            const SizedBox(height: 20),
            _buildTipsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final greeting = _getGreeting();
    final name = _userProfile?.name ?? 'Bodybuilder';
    final calorieProvider = context.watch<CalorieProvider>();
    final consumedCalories = calorieProvider.totalConsumedCalories;
    final consumedProtein = calorieProvider.totalConsumedProtein;
    final consumedCarbs = calorieProvider.totalConsumedCarbs;
    final consumedFats = calorieProvider.totalConsumedFats;

    // Hitung target makronutrisi (Estimasi Bodybuilding Default: 30% P, 50% C, 20% F)
    final targetProtein = (_targetCalories * 0.30 / 4).round();
    final targetCarbs = (_targetCalories * 0.50 / 4).round();
    final targetFats = (_targetCalories * 0.20 / 9).round();

    // Hitung persentase kalori yang sudah dikonsumsi
    double caloriePercentage =
        _targetCalories > 0
            ? (consumedCalories / _targetCalories).clamp(0.0, 1.0)
            : 0.0;

    // Format persentase untuk ditampilkan
    String percentageText = '${(caloriePercentage * 100).round()}%';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $name!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationalQuote(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_targetCalories > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kalori hari ini: $percentageText',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            caloriePercentage < 0.8
                                                ? const Color(0xFFD4AF37)
                                                : caloriePercentage < 1.0
                                                ? const Color(0xFFB8860B)
                                                : const Color(0xFFCF6679),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: caloriePercentage,
                                      backgroundColor: const Color(0xFF2A2A2A),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        caloriePercentage < 0.8
                                            ? const Color(0xFFD4AF37)
                                            : caloriePercentage < 1.0
                                            ? const Color(0xFFB8860B)
                                            : const Color(0xFFCF6679),
                                      ),
                                      minHeight: 8,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$consumedCalories / $_targetCalories kcal',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildMacroIndicator('Pro', consumedProtein, targetProtein, const Color(0xFFE07070)),
                                        const SizedBox(width: 8),
                                        _buildMacroIndicator('Karbo', consumedCarbs, targetCarbs, const Color(0xFFD4AF37)),
                                        const SizedBox(width: 8),
                                        _buildMacroIndicator('Lmk', consumedFats, targetFats, const Color(0xFFB8860B)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF2A2A2A),
                  child: Icon(
                    Icons.fitness_center,
                    size: 30,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _checkProfileAndNavigate(context);
              },
              child: const Text('Mulai Tracking Kalori'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroIndicator(String label, int current, int target, Color color) {
    double percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: $current / ${target}g',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTracker(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking Latihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWorkoutStat(
                  'Streak',
                  '$_streakDays hari',
                  Icons.local_fire_department,
                ),
                _buildWorkoutStat(
                  'Terakhir Latihan',
                  _lastWorkoutDate,
                  Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _logWorkout(context);
              },
              icon: const Icon(Icons.fitness_center),
              label: const Text('Catat Latihan Hari Ini'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<void> _logWorkout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final lastWorkout = prefs.getString('last_workout_date') ?? '';

    // Hitung streak
    int streak = prefs.getInt('workout_streak') ?? 0;

    if (lastWorkout != today) {
      final yesterday = DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.now().subtract(const Duration(days: 1)));

      if (lastWorkout == yesterday) {
        // Jika latihan kemarin, tambah streak
        streak++;
      } else if (lastWorkout != '') {
        // Jika tidak latihan kemarin, reset streak
        streak = 1;
      } else {
        // Pertama kali latihan
        streak = 1;
      }

      await prefs.setString('last_workout_date', today);
      await prefs.setInt('workout_streak', streak);

      setState(() {
        _lastWorkoutDate = today;
        _streakDays = streak;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Latihan berhasil dicatat! Streak: $streak hari'),
            backgroundColor: const Color(0xFF1A1A1A),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah mencatat latihan hari ini'),
            backgroundColor: Color(0xFF1A1A1A),
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 17) {
      return 'Selamat Siang';
    } else {
      return 'Selamat Malam';
    }
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Tidak ada yang bisa menghentikan orang dengan sikap mental yang benar dari mencapai tujuannya.',
      'Sukses bukan tentang keberuntungan. Ini tentang kerja keras dan konsistensi.',
      'Badan yang kuat dimulai dengan pikiran yang kuat.',
      'Jangan berhenti ketika lelah, berhentilah ketika selesai.',
      'Rasa sakit itu sementara, kebanggaan itu selamanya.',
    ];

    final random = DateTime.now().millisecond % quotes.length;
    return quotes[random];
  }

  Future<void> _checkProfileAndNavigate(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasProfile = prefs.getBool('has_profile') ?? false;

    if (!hasProfile) {
      // Jika profil belum ada, arahkan ke halaman profil
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Profil Diperlukan'),
                content: const Text(
                  'Anda perlu mengisi profil terlebih dahulu untuk melacak kalori dengan akurat.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: const Text('Isi Profil'),
                  ),
                ],
              ),
        );
      }
    } else {
      // Jika profil sudah ada, langsung ke halaman tracking kalori
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 1),
          ),
        );
      }
    }
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Penting',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.fitness_center,
          title: 'Kalori untuk Bodybuilder',
          description:
              'Bodybuilder membutuhkan kalori lebih untuk membangun massa otot. Biasanya 15-20% lebih tinggi dari kebutuhan normal.',
        ),
        const SizedBox(height: 8),
        _buildInfoCard(
          icon: Icons.restaurant_menu,
          title: 'Tracking yang Konsisten',
          description:
              'Lacak kalori Anda setiap hari untuk hasil yang optimal. Konsistensi adalah kunci keberhasilan.',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFD4AF37)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips Kalori untuk Bodybuilder',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
              title: Text('Makan 5-6 kali sehari dengan porsi lebih kecil'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
              title: Text('Konsumsi protein 1.6-2.2g per kg berat badan'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
              title: Text('Minum minimal 3-4 liter air per hari'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
              title: Text('Konsumsi karbohidrat kompleks untuk energi'),
            ),
          ],
        ),
      ],
    );
  }
}
