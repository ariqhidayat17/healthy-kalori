import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calorie_provider.dart';
import '../models/user_profile.dart';
import '../screens/main_screen.dart';
import '../screens/profile_screen.dart';

class WelcomeCard extends StatelessWidget {
  final UserProfile? userProfile;

  const WelcomeCard({super.key, this.userProfile});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
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
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Profil Diperlukan'),
            content: const Text('Anda perlu mengisi profil terlebih dahulu untuk melacak kalori dengan akurat.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
                child: const Text('Isi Profil'),
              ),
            ],
          ),
        );
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 1)),
        );
      }
    }
  }

  Widget _buildMacroIndicator(BuildContext context, String label, int current, int target, List<Color> gradientColors) {
    double percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text('${current}g', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 6, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(4))),
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
          Text('Tgt: ${target}g', style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();
    final name = userProfile?.name ?? 'Bodybuilder';
    final calorieProvider = context.watch<CalorieProvider>();
    
    final consumedCalories = calorieProvider.totalConsumedCalories;
    final targetCalories = calorieProvider.targetCalories;
    double caloriePercentage = targetCalories > 0 ? (consumedCalories / targetCalories).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerTheme.color ?? Colors.white.withOpacity(0.08), width: 1),
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
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getMotivationalQuote(),
                        style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.fitness_center, size: 32, color: theme.colorScheme.onPrimary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (targetCalories > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kalori Hari Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: caloriePercentage),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Text(
                        '${(value * 100).round()}%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
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
                      Container(height: 10, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutQuart,
                        height: 10,
                        width: constraints.maxWidth * caloriePercentage,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                          boxShadow: [
                            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    _buildMacroIndicator(context, 'Pro', calorieProvider.totalConsumedProtein, calorieProvider.targetProtein, const [Color(0xFFFF512F), Color(0xFFDD2476)]),
                    const SizedBox(width: 12),
                    _buildMacroIndicator(context, 'Karbo', calorieProvider.totalConsumedCarbs, calorieProvider.targetCarbs, const [Color(0xFFF2C94C), Color(0xFFF2994A)]),
                    const SizedBox(width: 12),
                    _buildMacroIndicator(context, 'Lemak', calorieProvider.totalConsumedFats, calorieProvider.targetFats, const [Color(0xFF38EF7D), Color(0xFF11998E)]),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _checkProfileAndNavigate(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Mulai Tracking Kalori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
