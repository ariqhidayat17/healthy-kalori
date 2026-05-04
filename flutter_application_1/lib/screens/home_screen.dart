import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/user_profile.dart';
import '../models/fuzzy_logic.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import 'workout_logger_screen.dart';
import 'weight_log_screen.dart';

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

      setState(() {
        _userProfile = userProfile;
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
            _buildWelcomeCard(context),
            const SizedBox(height: 20),
            _buildWeightTracker(context),
            const SizedBox(height: 20),
            _buildWaterTracker(context),
            const SizedBox(height: 20),
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

    final targetCalories = calorieProvider.targetCalories;
    final targetProtein = calorieProvider.targetProtein;
    final targetCarbs = calorieProvider.targetCarbs;
    final targetFats = calorieProvider.targetFats;

    // Hitung persentase kalori yang sudah dikonsumsi
    double caloriePercentage =
        targetCalories > 0
            ? (consumedCalories / targetCalories).clamp(0.0, 1.0)
            : 0.0;

    // Format persentase untuk ditampilkan
    String percentageText = '${(caloriePercentage * 100).round()}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
                        '$greeting,\n$name!',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationalQuote(),
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCD7F32), Color(0xFFFFD700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    size: 32,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (targetCalories > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kalori Hari Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: caloriePercentage),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Text(
                        '${(value * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFFD700)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(height: 10, decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutQuart,
                        height: 10,
                        width: constraints.maxWidth * caloriePercentage,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFFFD700)]),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: consumedCalories),
                duration: const Duration(milliseconds: 1500),
                builder: (context, value, child) {
                  return Text(
                    '$value / $targetCalories kcal',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildMacroIndicator('Pro', consumedProtein, targetProtein, const [Color(0xFFFF512F), Color(0xFFDD2476)]),
                    const SizedBox(width: 12),
                    _buildMacroIndicator('Karbo', consumedCarbs, targetCarbs, const [Color(0xFFF2C94C), Color(0xFFF2994A)]),
                    const SizedBox(width: 12),
                    _buildMacroIndicator('Lemak', consumedFats, targetFats, const [Color(0xFF38EF7D), Color(0xFF11998E)]),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _checkProfileAndNavigate(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                foregroundColor: const Color(0xFFFFD700),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mulai Tracking Kalori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroIndicator(String label, int current, int target, List<Color> gradientColors) {
    double percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
              Text('${current}g', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(4))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: 6,
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Text('Tgt: ${target}g', style: const TextStyle(fontSize: 9, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildWeightTracker(BuildContext context) {
    final double weight = _userProfile?.weight ?? 0.0;
    final double height = _userProfile?.height ?? 0.0;
    
    double bmi = 0.0;
    String bmiCategory = 'Belum ada data';
    Color bmiColor = Colors.grey;

    if (weight > 0 && height > 0) {
      final heightInMeters = height / 100;
      bmi = weight / (heightInMeters * heightInMeters);

      if (bmi < 18.5) {
        bmiCategory = 'Kurus (Underweight)';
        bmiColor = const Color(0xFF00B4DB); // Biru
      } else if (bmi < 24.9) {
        bmiCategory = 'Normal (Sehat)';
        bmiColor = const Color(0xFF38EF7D); // Hijau
      } else if (bmi < 29.9) {
        bmiCategory = 'Overweight';
        bmiColor = const Color(0xFFF2C94C); // Kuning
      } else {
        bmiCategory = 'Obesitas';
        bmiColor = const Color(0xFFFF512F); // Merah
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, color: Color(0xFFD4AF37)),
                    SizedBox(width: 8),
                    Text(
                      'Berat Badan & BMI',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeightLogScreen()),
                    ).then((_) {
                      _loadUserProfile();
                    });
                  },
                  child: const Text('Log', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWorkoutStat(
                  'Berat (kg)',
                  weight > 0 ? weight.toStringAsFixed(1) : '-',
                  Icons.monitor_weight,
                ),
                Container(width: 1, height: 50, color: Colors.white24),
                Column(
                  children: [
                    const Icon(Icons.speed, size: 28, color: Color(0xFFD4AF37)),
                    const SizedBox(height: 8),
                    Text(
                      bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: bmiColor,
                      ),
                    ),
                    Text(bmiCategory, style: TextStyle(fontSize: 12, color: bmiColor)),
                  ],
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildWaterTracker(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final consumedWater = calorieProvider.totalConsumedWater;
    final targetWater = calorieProvider.targetWater;
    final double waterPercentage = targetWater > 0 ? (consumedWater / targetWater).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2632), Color(0xFF13171F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop, color: Color(0xFF00B4DB), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Water Tracker',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (consumedWater > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            context.read<CalorieProvider>().addWater(-250);
                          },
                          child: const Icon(Icons.undo, color: Colors.white54, size: 20),
                        ),
                      ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: consumedWater),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return InkWell(
                          onTap: () => _showEditWaterTargetDialog(context, targetWater),
                          child: Text(
                            '$value / $targetWater ml',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4DB), fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF0C1014), borderRadius: BorderRadius.circular(10))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.elasticOut,
                      height: 14,
                      width: constraints.maxWidth * waterPercentage,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00B4DB).withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterAddButton(context, 250, Icons.local_drink),
                _buildWaterAddButton(context, 500, Icons.water_drop),
                _buildWaterAddButton(context, 1000, Icons.sports_mma), // Shaker
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterAddButton(BuildContext context, int amount, IconData icon) {
    return InkWell(
      onTap: () {
        context.read<CalorieProvider>().addWater(amount);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2632).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00B4DB), size: 18),
            const SizedBox(width: 6),
            Text('+$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutLoggerScreen()),
    ).then((_) {
      // Refresh workout stats when returning from Logger (streak & last date UI)
      _loadWorkoutStats();
    });
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
      'Disiplin adalah jembatan antara tujuan dan pencapaian.',
      'Setiap repetisi membawamu selangkah lebih dekat ke versi terbaikmu.',
    ];
    return quotes[DateTime.now().day % quotes.length];
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
  void _showEditWaterTargetDialog(BuildContext context, int currentTarget) {
    final controller = TextEditingController(text: currentTarget.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Target Air Minum (ml)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target per hari',
            suffixText: 'ml',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 4000;
              if (val > 0) {
                context.read<CalorieProvider>().updateTargetWater(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
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
