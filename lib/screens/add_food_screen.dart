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
import '../widgets/add_food_widgets.dart';

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
        // px-container-margin (20) mt-lg (24) gap-xl (32) — sesuai <main>
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(isDark),
            const SizedBox(height: 32), // gap-xl
            Text(
              'Temuan Cepat',
              style: GoogleFonts.montserrat( // font-headline-md
                fontSize: 20, // text-headline-md
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
              ),
            ),
            const SizedBox(height: 16), // mb-md
            _buildQuickFindsGrid(isDark),
            const SizedBox(height: 12),
            if (_searchController.text.isNotEmpty) _buildSearchResults(isDark),
            const SizedBox(height: 32), // gap-xl sebelum Manual Input Form
            _buildFormCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    // Spek HTML: input pl-12 pr-32 py-4, bg-surface-container,
    // border-2 outline-variant, rounded-full, shadow-sm.
    // 3 tombol kanan: qr_code_scanner (bg primary), mic (bg surface-container-highest),
    // psychology (bg tertiary-container).
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.stSurfaceContainer : AppColors.stSurfaceContainer,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.stOutlineVariant,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Icon(Icons.search_rounded,
              color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w700), // font-label-bold
              decoration: InputDecoration(
                hintText: 'Cari makanan atau scan...',
                hintStyle: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          // qr_code_scanner — bg primary solid, icon primary-container (gold)
          _CircleIconBtn(
            icon: Icons.qr_code_scanner_rounded,
            bg: AppColors.stPrimary,
            iconColor: AppColors.stPrimaryContainer,
            onTap: _scanBarcode,
          ),
          const SizedBox(width: 4), // gap-xs
          // mic — bg surface-container-highest, icon on-surface-variant
          _CircleIconBtn(
            icon: Icons.mic_rounded,
            bg: AppColors.stSurfaceContainerHighest,
            iconColor: AppColors.stOnSurfaceVariant,
            onTap: () => AppSnackbar.info(context, 'Voice input segera tersedia!'),
          ),
          const SizedBox(width: 4),
          // psychology (BUKAN auto_awesome) — bg tertiary-container, icon on-tertiary
          _CircleIconBtn(
            icon: Icons.psychology_rounded,
            bg: AppColors.stTertiaryContainer,
            iconColor: AppColors.stOnTertiary,
            onTap: _scanWithAIVision,
            isLoading: _isLoadingAI,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFindsGrid(bool isDark) {
    // Item & warna persis dari HTML:
    // 1. Ayam Bakar  → icon egg_alt,        bg secondary-container/20, icon color secondary,  label "RARE ITEM"
    // 2. Nasi Putih  → icon rice_bowl,      bg primary-container/20,   icon color primary,     label "COMMON"
    // 3. Telur Rebus → icon cooking,        bg tertiary-container/20,  icon color tertiary,    label "COMMON"
    // 4. Whey Protein→ icon vaping_rooms,   bg inverse-primary/20,     icon color primary,     label "EPIC ITEM"
    final items = [
      (name: 'Ayam Bakar', icon: Icons.egg_alt_rounded, iconColor: AppColors.stSecondary, bg: AppColors.stSecondaryContainer.withOpacity(0.2), rarity: 'Rare', badge: 'RARE ITEM'),
      (name: 'Nasi Putih', icon: Icons.rice_bowl_rounded, iconColor: AppColors.stPrimary, bg: AppColors.stPrimaryContainer.withOpacity(0.2), rarity: 'Common', badge: 'COMMON'),
      (name: 'Telur Rebus', icon: Icons.outdoor_grill_rounded, iconColor: AppColors.stTertiary, bg: AppColors.stTertiaryContainer.withOpacity(0.2), rarity: 'Common', badge: 'COMMON'),
      (name: 'Whey Protein', icon: Icons.icecream_rounded, iconColor: AppColors.stPrimary, bg: AppColors.stInversePrimary.withOpacity(0.2), rarity: 'Epic', badge: 'EPIC ITEM'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16, // gap-md
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: items.map((item) {
        return GestureDetector(
          onTap: () => _selectQuickFind(item.name, item.rarity),
          child: Container(
            padding: const EdgeInsets.all(16), // p-md
            decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerLow,
              borderRadius: BorderRadius.circular(12), // rounded-xl
              border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.3)),
              boxShadow: [
                // inner-bevel: inset 0 1px 1px rgba(255,255,255,0.6)
                BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 1, offset: const Offset(0, 1)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48, // w-12
                  height: 48,
                  decoration: BoxDecoration(color: item.bg, shape: BoxShape.circle),
                  child: Icon(item.icon, color: item.iconColor, size: 28), // text-3xl
                ),
                const SizedBox(height: 4), // gap-xs
                Text(
                  item.name,
                  style: GoogleFonts.nunitoSans( // font-label-bold
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
                  ),
                ),
                Text(
                  item.badge,
                  style: GoogleFonts.inter( // text-[10px], bukan label-bold
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.stOutline,
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
    // Manual Input Form — bg surface-container-high, p-lg, rounded-xl,
    // border-2 outline-variant/50, shadow-inner. Tombol Simpan ADA DI DALAM
    // card ini (bukan terpisah di luar seperti implementasi sebelumnya).
    return Container(
      padding: const EdgeInsets.all(24), // p-lg
      decoration: BoxDecoration(
        color: isDark ? AppColors.kDarkSurface2 : AppColors.stSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: AppColors.stOutlineVariant.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Nama Item', isDark),
          const SizedBox(height: 8), // gap-sm
          _StyledTextField(controller: _nameController, hint: 'Masukkan nama makanan...', isDark: isDark),
          const SizedBox(height: 24), // gap-lg antar field section

          // Apex Button — apex-gradient: linear-gradient(135deg, #6366f1, #a855f7)
          GestureDetector(
            onTap: _isLoadingAI ? null : _autoFillWithAI,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // py-4 px-lg
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12), // rounded-xl
                boxShadow: [
                  // pulse-glow keyframe disederhanakan jadi static glow ungu
                  BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.4), blurRadius: 12),
                ],
              ),
              child: _isLoadingAI
                  ? const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32, height: 32, // w-8 h-8
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 16), // gap-md
                        Text(
                          'ISI OTOMATIS DENGAN APEX',
                          style: GoogleFonts.montserrat( // font-headline-md
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24), // gap-lg

          // Macros Grid — font stat-number (Montserrat), warna BERBEDA per field
          Row(
            children: [
              Expanded(child: _buildMacroInput('Kalori (kcal)', _caloriesController, isDark, AppColors.stPrimary)),
              const SizedBox(width: 16), // gap-md
              Expanded(child: _buildMacroInput('Protein (g)', _proteinController, isDark, AppColors.stSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMacroInput('Karbohidrat (g)', _carbsController, isDark, AppColors.stTertiary)),
              const SizedBox(width: 16),
              Expanded(child: _buildMacroInput('Lemak (g)', _fatsController, isDark, AppColors.stOnSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 24),

          // Portion Stepper — button bulat primary-container, BUKAN gold custom
          _FieldLabel('Porsi (gram)', isDark),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8), // p-2
            decoration: BoxDecoration(
              color: isDark ? AppColors.kDarkSurface : AppColors.stSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _RoundStepperBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => setState(() {
                    _portion = (_portion - 10).clamp(10, 9999);
                    _recalculate();
                  }),
                ),
                Text(
                  '$_portion',
                  style: GoogleFonts.montserrat( // font-stat-number
                    fontSize: 20, // text-headline-md
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.kDarkText : AppColors.stOnSurface,
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
          ),
          const SizedBox(height: 24),

    // Rarity Selector
    _FieldLabel('Tingkat Kelangkaan (Rarity)', isDark),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.stSurfaceContainerHigh : AppColors.stSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stOutlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRarity,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.stSurfaceContainerHigh : AppColors.stSurfaceContainerHigh,
          style: GoogleFonts.nunitoSans(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.stOnSurface : AppColors.stOnSurface,
          ),
          items: const [
            DropdownMenuItem(value: 'Common', child: Text('Common (Makanan Biasa)')),
            DropdownMenuItem(value: 'Rare', child: Text('Rare (Nutrisi Tinggi)')),
            DropdownMenuItem(value: 'Epic', child: Text('Epic (Superfood)')),
            DropdownMenuItem(value: 'Legendary', child: Text('Legendary (Sempurna)')),
          ],
                onChanged: (v) => setState(() => _selectedRarity = v!),
              ),
            ),
          ),
          const SizedBox(height: 24), // gap-lg sebelum Save Button

          // Save Button — DI DALAM card ini, btn-gradient-primary dengan
          // efek "3D button" (shadow bawah solid + translateY saat ditekan)
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller, bool isDark, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // text-[11px] font-label-bold text-outline uppercase
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunitoSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.kDarkTextSub : AppColors.stOutline,
          ),
        ),
        const SizedBox(height: 4), // gap-xs
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.kDarkSurface : AppColors.stSurface,
            borderRadius: BorderRadius.circular(8), // rounded-lg
            border: Border.all(color: isDark ? AppColors.kDarkBorder : AppColors.stOutlineVariant),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat( // font-stat-number, warna per-field
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: valueColor,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), // p-sm
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return _SaveButton(onTap: _saveToLog);
  }
}

// ── Save Button — efek "3D button" persis btn-gradient-primary ──────────────
//
// CSS asli:
//   background: linear-gradient(180deg, #ffb800 0%, #fc8a40 100%);
//   box-shadow: 0 4px 0 #9b4500, 0 8px 15px rgba(252,138,64,0.3);
//   :active { box-shadow: 0 1px 0 #9b4500; transform: translateY(3px); }
//
// Efek "tombol fisik" ini SEBELUMNYA TIDAK ADA — implementasi lama cuma
// gradient solid datar tanpa physical-button feedback.
class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20), // py-5
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: _pressed
              ? [const BoxShadow(color: Color(0xFF9B4500), offset: Offset(0, 1))]
              : [
                  const BoxShadow(color: Color(0xFF9B4500), offset: Offset(0, 4)),
                  BoxShadow(color: const Color(0xFFFC8A40).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 16), // gap-md
                Text(
                  'SIMPAN KE LOG',
                  style: GoogleFonts.montserrat( // font-headline-lg
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.3), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _FieldLabel(this.text, this.isDark);

  @override
  Widget build(BuildContext context) {
    // font-label-bold text-primary px-1
    return Text(
      text,
      style: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.kDarkText : AppColors.stPrimary,
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
        // bg-primary-container, icon text-on-primary-container
        decoration: const BoxDecoration(
          color: AppColors.stPrimaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.stOnPrimaryContainer, size: 22),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _CircleIconBtn({
    required this.icon,
    required this.bg,
    this.iconColor = Colors.white,
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
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: iconColor),
              )
            : Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
