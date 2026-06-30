import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/prefs_service.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';

import '../models/food_database.dart';
import '../models/calorie_provider.dart';
import '../models/calorie_entry.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/openfoodfacts_service.dart';
import '../services/gamification_service.dart';
import '../config/app_colors.dart';
import '../widgets/rpg_app_bar.dart';

// Import widget modular
import '../widgets/food_list_item.dart';
import '../widgets/fantasy_card.dart';
import '../widgets/calorie_summary_header.dart';
import '../widgets/add_food_option_button.dart';
import 'rank_progress_screen.dart';
import 'add_food_screen.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  UserProfile? _userProfile;
  int _currentXP = 0;
  int _currentLevel = 1;
  String _currentRank = 'Bronze';
  int _maxXP = 500;
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadGamificationData();
    _loadWorkoutStats();
  }

  Future<void> _loadUserProfile() async {
    final prefs = PrefsService.i.raw;
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

  Future<void> _loadGamificationData() async {
    final service = GamificationService();
    int xp = await service.getCurrentXP();
    Map<String, int> progress = service.getRankProgress(xp);
    if (mounted) {
      setState(() {
        _currentXP = xp;
        _currentLevel = GamificationService.getCurrentLevel(xp);
        _currentRank = service.getCurrentRank(xp);
        _maxXP = progress['max_xp']!;
      });
    }
  }

  Future<void> _loadWorkoutStats() async {
    final prefs = PrefsService.i.raw;
    setState(() {
      _streakDays = prefs.getInt('workout_streak') ?? 0;
    });
  }

 Widget _buildXPStreakBar() {
    final xpProgress = _maxXP > 0
        ? ((_currentXP - _getMinXPForRank()) / (_maxXP - _getMinXPForRank())).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kPrimaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.kPrimaryOrange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '$_streakDays hari',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.kPrimaryOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // XP Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '⚡ $_currentRank · Lvl $_currentLevel',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '$_currentXP / $_maxXP XP',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.kPrimaryGold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getMinXPForRank() {
    const thresholds = {
      'Bronze': 0, 'Silver': 500, 'Gold': 1500, 'Diamond': 3000, 'Spartan': 5000,
    };
    return thresholds[_currentRank] ?? 0;
  }

  Widget _buildMacroSummaryBar(CalorieProvider calorieProvider) {
    final target = calorieProvider.targetCalories;
    final consumed = calorieProvider.totalConsumedCalories;
    final remaining = (target - consumed).clamp(0, target);
    final double progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return FantasyCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENERGI TERSISA',
                    style: GoogleFonts.nunito(
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remaining ',
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.kPrimaryOrange,
                          ),
                        ),
                        TextSpan(
                          text: 'Kcal',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TARGET',
                    style: GoogleFonts.nunito(
                      color: Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$target',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mana Bar Style Progress
          Stack(
            children: [
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFC8A40), Color(0xFF9B4500)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildMiniMacrosRow(CalorieProvider calorieProvider) {
    final double waterLiters = calorieProvider.totalConsumedWater / 1000.0;
    return Row(
      children: [
        _buildMiniMacroItem('PROTEIN', '${calorieProvider.totalConsumedProtein.toInt()}g', AppColors.kPrimaryOrange),
        const SizedBox(width: 8),
        _buildMiniMacroItem('KARBO', '${calorieProvider.totalConsumedCarbs.toInt()}g', AppColors.kManaBlue),
        const SizedBox(width: 8),
        _buildMiniMacroItem('LEMAK', '${calorieProvider.totalConsumedFats.toInt()}g', AppColors.kNatureGreen),
        const SizedBox(width: 8),
        _buildMiniMacroItem('AIR', '${waterLiters.toStringAsFixed(1)}L', const Color(0xFF03A9F4)),
      ],
    );
  }

  Widget _buildMiniMacroItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealGroup(
    BuildContext context,
    String title,
    List<CalorieEntry> mealEntries,
    String mealTime,
    IconData icon,
    Color themeColor,
  ) {
    int totalCals = mealEntries.fold(0, (sum, item) => sum + item.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(icon, color: themeColor, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 1.0,
                  ),
                ),
                if (totalCals > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalCals kcal',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            IconButton(
              onPressed: () => _showAddFoodDialogWithMealTime(mealTime),
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.kPrimaryOrange, size: 22),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (mealEntries.isEmpty)
          _buildEmptyMealState(mealTime)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mealEntries.length,
            itemBuilder: (context, index) {
              final entry = mealEntries[index];
              return FoodListItem(
                entry: entry,
                onTap: () => _showEditFoodDialog(entry),
                onDelete: () => _confirmDeleteFood(context, entry),
              ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyMealState(String mealTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, color: Colors.grey[300], size: 28),
          const SizedBox(height: 8),
          Text(
            'Belum ada makanan',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
          ),
          Text(
            'Catat petualangan kulinermu untuk $mealTime!',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final entries = calorieProvider.entries;

    // Grouping by meal time
    Map<String, List<CalorieEntry>> groupedEntries = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };
    for (var entry in entries) {
      if (groupedEntries.containsKey(entry.mealTime)) {
        groupedEntries[entry.mealTime]!.add(entry);
      } else {
        groupedEntries['Snack']!.add(entry);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.kBgCream,
      appBar: RPGAppBar(screenKey: 'food'),
      body: Column(
        children: [
          _buildXPStreakBar(),
          Expanded(
            child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Macro Summary Card
                CalorieSummaryHeader(calorieProvider: calorieProvider).animate().fadeIn().slideY(begin: -0.1),
                const SizedBox(height: 16),

                // 2. Mini Macros Grid
                _buildMiniMacrosRow(calorieProvider).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),

                // 3. Meal Groups
                _buildMealGroup(context, '🌅 SARAPAN', groupedEntries['Breakfast']!, 'Breakfast', Icons.wb_twilight_rounded, AppColors.kPrimaryOrange),
                _buildMealGroup(context, '☀️ MAKAN SIANG', groupedEntries['Lunch']!, 'Lunch', Icons.light_mode_rounded, AppColors.kPrimaryOrange),
                _buildMealGroup(context, '🌙 MAKAN MALAM', groupedEntries['Dinner']!, 'Dinner', Icons.dark_mode_rounded, AppColors.kPrimaryGold),
                _buildMealGroup(context, '🍪 SNACK', groupedEntries['Snack']!, 'Snack', Icons.cookie_rounded, AppColors.kPrimaryOrange),
              ],
            ),
          ),
          
          // Floating CTA
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: FloatingActionButton.extended(
                onPressed: _showAddOptionsModal,
                backgroundColor: AppColors.kPrimaryOrange,
                foregroundColor: Colors.white,
                elevation: 6,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'TAMBAH MAKANAN BARU',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialogWithMealTime(String mealTime) {
    _showAddFoodDialog(initialMealTime: mealTime);
  }

  void _showAddOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 24),
            Text(
              'ITEM DISCOVERY',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOptionBtn('✍️', 'Manual', AppColors.kPrimaryOrange, _showAddFoodDialog),
                _buildOptionBtn('📸', 'AI Scan', AppColors.kManaBlue, _showAIScannerOptions),
                _buildOptionBtn('🔍', 'Barcode', AppColors.kNatureGreen, () async {
                  Navigator.pop(context);
                  var res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
                  );
                  if (res is String && res != '-1') _processBarcodeScan(res);
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionBtn(String emoji, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        if (label == 'Manual' || label == 'AI Scan') Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _showAIScannerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Pilih Sumber Foto', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanFoodWithAI(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanFoodWithAI(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scanFoodWithAI(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source, 
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Apex sedang menganalisis item...', style: GoogleFonts.inter()),
          ],
        ),
      ),
    );

    final result = await GeminiService().analyzeFoodImage(File(image.path));
    
    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    if (result.containsKey('error')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${result['error']}'), backgroundColor: AppColors.kHealthRed),
      );
      return;
    }

    _showAddFoodDialogWithPrefill(
      result['foodName'] ?? 'Item Tak Dikenal',
      (result['calories'] is num) ? (result['calories'] as num).toInt() : 0,
      (result['protein'] is num) ? (result['protein'] as num).toInt() : 0,
      (result['carbs'] is num) ? (result['carbs'] as num).toInt() : 0,
      (result['fats'] is num) ? (result['fats'] as num).toInt() : 0,
    );
  }

  Future<void> _processBarcodeScan(String barcode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari data item...'),
          ],
        ),
      ),
    );

    final service = OpenFoodFactsService();
    try {
      final result = await service.getProductByBarcode(barcode);

      if (mounted) Navigator.pop(context);

      if (result == null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Item Tidak Ditemukan'),
            content: Text('Barcode ($barcode) tidak dikenali. Masukkan data secara manual?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddFoodDialog();
                },
                child: const Text('Isi Manual'),
              ),
            ],
          ),
        );
      } else {
        _showAddFoodDialogWithPrefill(
          result['name'] as String,
          result['calories'] as int,
          result['protein'] as int,
          result['carbs'] as int,
          result['fats'] as int,
          nutriScore: result['nutriScore'] as String?,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _showAddFoodDialogWithPrefill(String name, int cals, int prot, int carbs, int fats, {String? nutriScore}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(
          prefillName: name,
          prefillCalories: cals,
          prefillProtein: prot,
          prefillCarbs: carbs,
          prefillFats: fats,
          nutriScore: nutriScore,
        ),
      ),
    );
  }

  void _confirmDeleteFood(BuildContext context, CalorieEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buang Item?'),
        content: Text('Apakah kamu yakin ingin membuang "${entry.foodName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (entry.id != null) {
                context.read<CalorieProvider>().removeFood(entry.id!);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.kHealthRed),
            child: const Text('BUANG'),
          ),
        ],
      ),
    );
  }

  void _showEditFoodDialog(CalorieEntry entry) {
    final nameController = TextEditingController(text: entry.foodName);
    final caloriesController = TextEditingController(text: entry.calories.toString());
    final proteinController = TextEditingController(text: entry.protein.toString());
    final carbsController = TextEditingController(text: entry.carbs.toString());
    final fatsController = TextEditingController(text: entry.fats.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('EDIT ITEM', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Item'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'P'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'C'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'F'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedEntry = CalorieEntry(
                id: entry.id,
                date: entry.date,
                foodName: nameController.text,
                calories: int.tryParse(caloriesController.text) ?? 0,
                protein: int.tryParse(proteinController.text) ?? 0,
                carbs: int.tryParse(carbsController.text) ?? 0,
                fats: int.tryParse(fatsController.text) ?? 0,
              );
              context.read<CalorieProvider>().updateFood(updatedEntry);
              Navigator.pop(ctx);
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _showAddFoodDialog({String? initialMealTime}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddFoodScreen(initialMealTime: initialMealTime ?? 'Breakfast'),
      ),
    );
  }
}
