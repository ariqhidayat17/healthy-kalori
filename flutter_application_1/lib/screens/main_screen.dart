import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calorie_tracker_screen.dart';
import 'profile_screen.dart';
import 'ai_coach_screen.dart';
import 'stats_screen.dart';

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
  
  // Buat daftar screen sebagai getter agar selalu mendapatkan instance baru
  List<Widget> get _screens => [
    const HomeScreen(),
    const CalorieTrackerScreen(),
    const StatsScreen(), // Tab 3: Statistik
    const AiCoachScreen(), // Tab 4: AI Coach
    const ProfileScreen(), // Tab 5: Profil
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department),
            label: 'Kalori',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Pastikan 5 tab tidak shifting
        onTap: _onItemTapped,
      ),
    );
  }
}


