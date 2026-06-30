import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_colors.dart';
import '../models/food_database.dart';
import '../models/calorie_provider.dart';
import '../services/gemini_service.dart';
import '../services/gamification_service.dart';
import '../utils/app_snackbar.dart';
import '../widgets/rpg_app_bar.dart';

/// Screen "Tambah Makanan" full-page — menggantikan AlertDialog lama.
/// Sesuai desain Stitch: search bar rounded, grid "Temuan Cepat",
/// tombol AI auto-fill, input porsi dengan +/-, dropdown rarity.
///
/// Semua fitur lama dipertahankan:
/// - Search database makanan Indonesia
/// - Auto-fill via Gemini AI
/// - Prefill dari barcode scan (nutri-score) atau AI vision scan
/// - Reward XP saat simpan
class AddFoodScreen extends StatefulWidget {
  final String initialMealTime;
  final String? prefillName;
  final int? prefillCalories;
  final int? prefillProtein;
  final int? prefillCarbs;
  final int? prefillFats;
  final String? nutriScore;

  const AddFoodScreen({
    super.key,
    this.initialMealTime = 'Breakfast',
    this.prefillName,
    this.prefillCalories,
    this.prefillProtein,
    this.prefillCarbs,
    this.prefillFats,
    this.nutriScore,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController(text: '0');
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatsController = TextEditingController(text: '0');

  int _portion = 100;
  int _baseCals = 0, _baseProt = 0, _baseCarbs = 0, _baseFats = 0;
  String _selectedMealTime = 'Breakfast';
  String _selectedRarity = 'Common';
  bool _isLoadingAI = false;
  List<String> _filteredFoods = [];

  static const _quickFinds = [
    ('Ayam Bakar', '🍗', 'Rare'),
    ('Nasi Putih', '🍚', 'Common'),
    ('Telur Rebus', '🥚', 'Common'),
    ('Whey Protein', '🥤', 'Epic'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedMealTime = widget.initialMealTime;
    _filteredFoods = FoodDatabase.indonesianFoods.keys.toList();

    if (widget.prefillName != null) {
      _nameController.text = widget.prefillName!;
      _baseCals = widget.prefillCalories ?? 0;
      _baseProt = widget.prefillProtein ?? 0;
      _baseCarbs = widget.prefillCarbs ?? 0;
      _baseFats = widget.prefillFats ?? 0;
      _recalculate();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final p = _portion / 100.0;
    _caloriesController.text = (_baseCals * p).round().toString();
    _proteinController.text = (_baseProt * p).round().toString();
    _carbsController.text = (_baseCarbs * p).round().toString();
    _fatsController.text = (_baseFats * p).round().toString();
  }

  void _onSearchChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredFoods = FoodDatabase.indonesianFoods.keys.toList();
      } else {
        _filteredFoods = FoodDatabase.indonesianFoods.keys
            .where((f) => f.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectFood(String foodName) {
    final macros = FoodDatabase.getMacros(foodName);
    final calories = FoodDatabase.indonesianFoods[foodName] ?? 0;
    setState(() {
      _nameController.text = foodName;
      _baseCals = calories;
      _baseProt = macros?['protein'] ?? 0;
      _baseCarbs = macros?['carbs'] ?? 0;
      _baseFats = macros?['fats'] ?? 0;
      _portion = 100;
      _recalculate();
      _searchController.clear();
      _filteredFoods = FoodDatabase.indonesianFoods.keys.toList();
    });
  }

  void _selectQuickFind(String name, String rarity) {
    final macros = FoodDatabase.getMacros(name) ??
        FoodDatabase.foods.entries
            .firstWhere(
                (e) => e.key.toLowerCase().contains(name.toLowerCase()),
                orElse: () => const MapEntry(
                    '', {'calories': 150, 'protein': 10, 'carbs': 15, 'fats': 5}))
            .value;
    final fullName = FoodDatabase.foods.keys.firstWhere(
        (k) => k.toLowerCase().contains(name.toLowerCase()),
        orElse: () => name);

    setState(() {
      _nameController.text = fullName;
      _baseCals = macros['calories'] ?? 150;
      _baseProt = macros['protein'] ?? 10;
      _baseCarbs = macros['carbs'] ?? 15;
      _baseFats = macros['fats'] ?? 5;
      _selectedRarity = rarity;
      _portion = 100;
      _recalculate();
    });
  }

  Future<void> _autoFillWithAI() async {
    final foodName = _nameController.text.trim();
    if (foodName.isEmpty) {
      AppSnackbar.info(context, 'Masukkan nama makanan dulu ya!');
      return;
    }

    setState(() => _isLoadingAI = true);
    try {
      final prompt = 'Estimasi kandungan gizi "$foodName" untuk porsi normal. '
          'Balas HANYA JSON: {"calories": 200, "protein": 5, "carbs": 30, "fats": 8}.';
      final response = await GeminiService().getChatResponse([
        {'role': 'system', 'content': 'Balas hanya JSON valid.'},
        {'role': 'user', 'content': prompt},
      ]);

      final regex = RegExp(r'\{.*?\}', dotAll: true);
      final match = regex.firstMatch(response);
      if (match != null) {
        final data = jsonDecode(match.group(0)!);
        setState(() {
          _baseCals = data['calories'] ?? 0;
          _baseProt = data['protein'] ?? 0;
          _baseCarbs = data['carbs'] ?? 0;
          _baseFats = data['fats'] ?? 0;
          _recalculate();
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal menghubungi Apex. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  Future<void> _saveToLog() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.info(context, 'Nama makanan tidak boleh kosong.');
      return;
    }

    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = int.tryParse(_proteinController.text) ?? 0;
    final carbs = int.tryParse(_carbsController.text) ?? 0;
    final fats = int.tryParse(_fatsController.text) ?? 0;

    await context.read<CalorieProvider>().addFood(
          name,
          calories,
          protein: protein,
          carbs: carbs,
          fats: fats,
          mealTime: _selectedMealTime,
          rarity: _selectedRarity,
        );

    await GamificationService().addXP(10);

    if (mounted) {
      AppSnackbar.foodAdded(context, name, _selectedRarity);
      Navigator.pop(context);
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const SimpleBarcodeScannerPage()),
    );
    if (result != null && result != '-1' && mounted) {
      AppSnackbar.info(context, 'Barcode: $result — cari di database OpenFoodFacts.');
    }
  }

  Future<void> _scanWithAIVision() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null) return;

    setState(() => _isLoadingAI = true);
    try {
      final result = await GeminiService().analyzeFoodImage(File(image.path));
      if (result['success'] == true) {
        setState(() {
          _nameController.text = result['name'] ?? '';
          _baseCals = result['calories'] ?? 0;
          _baseProt = result['protein'] ?? 0;
          _baseCarbs = result['carbs'] ?? 0;
          _baseFats = result['fats'] ?? 0;
          _recalculate();
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Gagal menganalisis foto.');
    } finally {
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.kDarkBg : AppColors.kBgCream,
      appBar: const RPGAppBar(screenKey: 'food', showSubtitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(isDark),
            const SizedBox(height: 24),
            Text(
              'Temuan Cepat',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.kDarkText : const Color(0xFF211B11),
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickFindsGrid(isDark),
            const SizedBox(height: 12),
            if (_searchController.text.isNotEmpty) _buildSearchResults(isDark),
            const SizedBox(height: 16),
            _buildFormCard(isDark),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? AppColors.kDarkBorder : const Color(0xFFEDE1D0),
        ),
        boxShadow: isDark ? null : AppColors.kSoftShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(Icons.search_rounded,
              color: isDark ? AppColors.kDarkTextSub : Colors.grey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari makanan atau scan...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppColors.kDarkTextSub : Colors.grey[500],
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          _CircleIconBtn(
            icon: Icons.qr_code_scanner_rounded,
            bg: const Color(0xFF6B4F1E),
            onTap: _scanBarcode,
          ),
          const SizedBox(width: 6),
          _CircleIconBtn(
            icon: Icons.mic_rounded,
            bg: Colors.grey[400]!,
            onTap: () => AppSnackbar.info(context, 'Voice input segera tersedia!'),
          ),
          const SizedBox(width: 6),
          _CircleIconBtn(
            icon: Icons.auto_awesome_rounded,
            bg: AppColors.kPrimaryGold,
            onTap: _scanWithAIVision,
            isLoading: _isLoadingAI,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFindsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: _quickFinds.map((item) {
        final (name, emoji, rarity) = item;
        final rarityColor = switch (rarity) {
          'Legendary' => AppColors.kRarityLegendary,
          'Epic' => AppColors.kRarityEpic,
          'Rare' => AppColors.kRarityRare,
          _ => AppColors.kRarityCommon,
        };
        return GestureDetector(
          onTap: () => _selectQuickFind(name, rarity),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkSurface2 : const Color(0xFFFBF1E3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rarityColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.kDarkText : const Color(0xFF211B11),
                  ),
                ),
                Text(
                  rarity.toUpperCase(),
                  style: GoogleFonts.nunitoSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: rarityColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSearchResults(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.kDarkBorder : Colors.grey[200]!),
      ),
      child: _filteredFoods.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Tidak ditemukan', style: GoogleFonts.inter(color: Colors.grey)),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredFoods.length > 15 ? 15 : _filteredFoods.length,
              itemBuilder: (context, i) {
                final food = _filteredFoods[i];
                final cal = FoodDatabase.indonesianFoods[food] ?? 0;
                return ListTile(
                  dense: true,
                  title: Text(food, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Text('$cal kcal', style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.kPrimaryOrange)),
                  onTap: () => _selectFood(food),
                );
              },
            ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface2 : const Color(0xFFFBF1E3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Nama Item', isDark),
          const SizedBox(height: 6),
          _StyledTextField(controller: _nameController, hint: 'Masukkan nama makanan...', isDark: isDark),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isLoadingAI ? null : _autoFillWithAI,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A4FE0), Color(0xFF9B7BFF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _isLoadingAI
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'ISI OTOMATIS DENGAN APEX',
                            style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildMacroInput('KALORI (KCAL)', _caloriesController, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildMacroInput('PROTEIN (G)', _proteinController, isDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMacroInput('KARBOHIDRAT (G)', _carbsController, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _buildMacroInput('LEMAK (G)', _fatsController, isDark)),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel('Porsi (gram)', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              _RoundStepperBtn(
                icon: Icons.remove_rounded,
                onTap: () => setState(() {
                  _portion = (_portion - 10).clamp(10, 9999);
                  _recalculate();
                }),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$_portion',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.kDarkText : const Color(0xFF211B11),
                    ),
                  ),
                ),
              ),
              _RoundStepperBtn(
                icon: Icons.add_rounded,
                onTap: () => setState(() {
                  _portion = (_portion + 10).clamp(10, 9999);
                  _recalculate();
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FieldLabel('Tingkat Kelangkaan (Rarity)', isDark),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.kDarkBorder : Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRarity,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Common', child: Text('Common (Makanan Biasa)')),
                  DropdownMenuItem(value: 'Rare', child: Text('Rare')),
                  DropdownMenuItem(value: 'Epic', child: Text('Epic')),
                  DropdownMenuItem(value: 'Legendary', child: Text('Legendary')),
                ],
                onChanged: (v) => setState(() => _selectedRarity = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, isDark, small: true),
        const SizedBox(height: 6),
        _StyledTextField(controller: controller, hint: '0', isDark: isDark, isNumber: true),
      ],
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveToLog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.kPrimaryGold, AppColors.kPrimaryOrange]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.kPrimaryOrange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('SIMPAN KE LOG', style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool small;
  const _FieldLabel(this.text, this.isDark, {this.small = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: small ? 10 : 12,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.kDarkTextSub : const Color(0xFF8A5A1E),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool isNumber;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.kDarkBorder : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.kDarkText : const Color(0xFF211B11),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RoundStepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundStepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: AppColors.kPrimaryGold, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final VoidCallback onTap;
  final bool isLoading;

  const _CircleIconBtn({
    required this.icon,
    required this.bg,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
