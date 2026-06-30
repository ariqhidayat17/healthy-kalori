import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import 'home_screen.dart';
import 'calorie_tracker_screen.dart';
import 'ai_coach_screen.dart';
import 'mission_screen.dart';
import 'profile_screen.dart';
import 'rank_progress_screen.dart';

/// Bottom navigation.
///
/// CATATAN PENYIMPANGAN DARI SPEK STITCH (disengaja, dikonfirmasi user):
/// Desain asli Stitch hanya punya 5 tab: Quest | Food | Apex | Rank | Profile,
/// dengan "Quest" mengarah ke Misi Harian. Tapi project ini punya HomeScreen
/// (dashboard kalori/XP) yang juga harus selalu jadi tab pertama, karena
/// SplashScreen & OnboardingScreen selalu push ke MainScreen(initialIndex: 0).
///
/// Solusi: 6 tab. Home ditambahkan sebagai tab ekstra sebelum Quest.
/// Index lain (Food=2, Apex=3, Rank=4, Profile=5) bergeser +1 dari spek asli.
///
/// Style nav tetap presisi sesuai code.html Stitch:
/// - bg: surface-container (#f9ecdb)
/// - item aktif: pill rounded-full, bg primary-container (gold #ffb800)
/// - item inactive: flat, text on-surface-variant (#514532)
class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _screens => const [
        HomeScreen(),           // 0: Home (custom, di luar spek Stitch)
        MissionScreen(),        // 1: Quest
        CalorieTrackerScreen(), // 2: Food
        AiCoachScreen(),        // 3: Apex
        RankProgressScreen(),   // 4: Rank
        ProfileScreen(),        // 5: Profile
      ];

  static const _tabs = [
    _NavTab(icon: Icons.home_rounded, label: 'Home', index: 0),
    _NavTab(icon: Icons.fort_rounded, label: 'Quest', index: 1),
    _NavTab(icon: Icons.restaurant_rounded, label: 'Food', index: 2),
    _NavTab(icon: Icons.psychology_rounded, label: 'Apex', index: 3),
    _NavTab(icon: Icons.leaderboard_rounded, label: 'Rank', index: 4),
    _NavTab(icon: Icons.person_rounded, label: 'Profile', index: 5),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.kDarkSurface : AppColors.kBgSubtle;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          color: navBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: AppColors.kPrimaryGold.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              return _NavItem(
                tab: tab,
                isSelected: _selectedIndex == tab.index,
                isDark: isDark,
                onTap: () => _onItemTapped(tab.index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final int index;
  const _NavTab({required this.icon, required this.label, required this.index});
}

class _NavItem extends StatelessWidget {
  final _NavTab tab;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = AppColors.kPrimaryGold;
    final activeFg = const Color(0xFF6B4C00);
    final inactiveFg = isDark ? AppColors.kDarkTextSub : const Color(0xFF514532);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 21, color: isSelected ? activeFg : inactiveFg),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: GoogleFonts.nunitoSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? activeFg : inactiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
