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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final entries = calorieProvider.entries;

    return Scaffold(
      backgroundColor: AppColors.stBackground,
      appBar: RPGAppBar(screenKey: 'food'),
      body: Column(
        children: [
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
                const SizedBox(height: 24),

                // 2. Daftar Makanan (Flat List)
                Text(
                  'DAFTAR MAKANAN HARI INI',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
                        Icon(Icons.restaurant_menu_rounded, color: Colors.grey[300], size: 36),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada makanan',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catat petualangan kulinermu hari ini!',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.black38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return FoodListItem(
                        entry: entry,
                        onTap: () => _showEditFoodDialog(entry),
                        onDelete: () => _confirmDeleteFood(context, entry),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
                    },
                  ),
                const SizedBox(height: 80),
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
                AddFoodOptionButton(
                  emoji: '✍️',
                  label: 'Manual',
                  color: AppColors.kPrimaryOrange,
                  onTap: _showAddFoodDialog,
                  popOnTap: true,
                ),
                AddFoodOptionButton(
                  emoji: '📸',
                  label: 'AI Scan',
                  color: AppColors.kManaBlue,
                  onTap: _showAIScannerOptions,
                  popOnTap: true,
                ),
                AddFoodOptionButton(
                  emoji: '🔍',
                  label: 'Barcode',
                  color: AppColors.kNatureGreen,
                  onTap: () async {
                    Navigator.pop(context);
                    var res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
                    );
                    if (res is String && res != '-1') _processBarcodeScan(res);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
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
