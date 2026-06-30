import 'package:flutter/material.dart';
import '../utils/prefs_service.dart';
import 'main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Selamat Datang di AI Coach',
      'description': 'Asisten pribadi Anda untuk melacak nutrisi dan perjalanan kebugaran secara cerdas.',
      'icon': 'fitness_center',
    },
    {
      'title': 'Target TDEE & Makro Dinamis',
      'description': 'Target kalori dan persentase protein, karbohidrat, dan lemak Anda dihitung otomatis menggunakan standar sains (Mifflin-St Jeor) sesuai profil Anda.',
      'icon': 'analytics',
    },
    {
      'title': 'Log Berat Badan & Progres',
      'description': 'Catat perubahan berat badan Anda. AI Coach akan secara otomatis menyesuaikan target kalori Anda seiring dengan pertumbuhan otot atau penurunan lemak Anda.',
      'icon': 'monitor_weight',
    },
    {
      'title': 'Capai Tujuan Anda',
      'description': 'Baik Bulking maupun Cutting, semua data Anda tersinkronisasi. Konsistensi adalah kunci. Mari kita mulai!',
      'icon': 'emoji_events',
    },
  ];

  IconData _getIcon(String name) {
    switch (name) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'analytics':
        return Icons.analytics;
      case 'monitor_weight':
        return Icons.monitor_weight;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  void _completeOnboarding() async {
    final prefs = PrefsService.i.raw;
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF9800).withOpacity(0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getIcon(_onboardingData[index]['icon']!),
                            size: 80,
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          _onboardingData[index]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _onboardingData[index]['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFFF9800)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text(
                          'LEWATI',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _onboardingData.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _onboardingData.length - 1 ? 'MULAI' : 'LANJUT',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
