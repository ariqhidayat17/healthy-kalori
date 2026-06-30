import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/prefs_service.dart';
import '../models/calorie_provider.dart';
import '../models/user_profile.dart';
import '../screens/main_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/rank_progress_screen.dart';
import '../services/gamification_service.dart';
import '../widgets/rank_badge_widget.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/circular_calorie_ring.dart';

class WelcomeCard extends StatefulWidget {
  final UserProfile? userProfile;

  const WelcomeCard({super.key, this.userProfile});

  @override
  State<WelcomeCard> createState() => _WelcomeCardState();
}

class _WelcomeCardState extends State<WelcomeCard> {
  int _currentXP = 0;
  String _currentRank = 'Bronze';
  int _minXP = 0;
  int _maxXP = 500;

  @override
  void initState() {
    super.initState();
    _loadGamificationData();
  }

  Future<void> _loadGamificationData() async {
    final service = GamificationService();
    int xp = await service.getCurrentXP();
    Map<String, int> progress = service.getRankProgress(xp);
    
    if (mounted) {
      setState(() {
        _currentXP = progress['current_xp']!;
        _minXP = progress['min_xp']!;
        _maxXP = progress['max_xp']!;
        _currentRank = service.getCurrentRank(xp);
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  Future<void> _checkProfileAndNavigate(BuildContext context) async {
    final prefs = PrefsService.i.raw;
    final hasProfile = prefs.getBool('has_profile') ?? false;

    if (!hasProfile) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8))),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    height: 8,
                    width: constraints.maxWidth * percentage,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text('${current}g / ${target}g', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final name = widget.userProfile?.name ?? 'Bodybuilder';
    final calorieProvider = context.watch<CalorieProvider>();
    
    final consumedCalories = calorieProvider.totalConsumedCalories;
    final targetCalories = calorieProvider.targetCalories;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Background bersih
        borderRadius: BorderRadius.circular(32), // Sudut sangat melengkung (Duolingo style)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // HEADER: Avatar + Nama + Rank Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                  child: const Icon(Icons.person, size: 36, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const RankProgressScreen()));
                            },
                            child: RankBadgeWidget(rank: _currentRank, size: 16, showText: false),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // XP PROGRESS BAR
            XPProgressBar(
              currentXP: _currentXP,
              minXP: _minXP,
              maxXP: _maxXP,
            ),
            
            const SizedBox(height: 32),

            if (targetCalories > 0) ...[
              // CIRCULAR CALORIE RING
              Center(
                child: CircularCalorieRing(
                  consumed: consumedCalories,
                  target: targetCalories,
                  size: 200, // Ukuran besar agar dominan
                ),
              ),
              
              const SizedBox(height: 32),
              
              // MACRO CARDS
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _buildMacroIndicator(context, 'Protein', calorieProvider.totalConsumedProtein, calorieProvider.targetProtein, const [Color(0xFF2196F3), Color(0xFF64B5F6)]),
                    const SizedBox(width: 16),
                    _buildMacroIndicator(context, 'Karbo', calorieProvider.totalConsumedCarbs, calorieProvider.targetCarbs, const [Color(0xFFFF9800), Color(0xFFFFB74D)]),
                    const SizedBox(width: 16),
                    _buildMacroIndicator(context, 'Lemak', calorieProvider.totalConsumedFats, calorieProvider.targetFats, const [Color(0xFFE91E63), Color(0xFFF06292)]),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () => _checkProfileAndNavigate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Hijau ceria
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('Catat Kalori Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
