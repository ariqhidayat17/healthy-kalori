import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/fuzzy_logic.dart';
import '../models/food_database.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import '../models/calorie_entry.dart';
import '../utils/notification_helper.dart';
import '../services/gemini_service.dart';
import '../services/openfoodfacts_service.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:image_picker/image_picker.dart';

// Import widget modular
import '../widgets/calorie_summary_card.dart';
import '../widgets/food_list_item.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final totalCalories = calorieProvider.totalConsumedCalories;
    final entries = calorieProvider.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Kalori'),
      ),
      body: Column(
        children: [
          CalorieSummaryCard(
            totalCalories: totalCalories,
            targetCalories: calorieProvider.targetCalories,
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty ? _buildEmptyState(context) : _buildFoodList(entries),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'ai_cam_btn',
            onPressed: _showAIScannerOptions,
            backgroundColor: const Color(0xFF00B4DB),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'scan_btn',
            onPressed: () async {
              var res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleBarcodeScannerPage(),
                ),
              );
              if (res is String && res != '-1') {
                _processBarcodeScan(res);
              }
            },
            backgroundColor: const Color(0xFFD4AF37),
            child: const Icon(Icons.qr_code_scanner, color: Colors.black),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'add_btn',
            onPressed: _showAddFoodDialog,
            child: const Icon(Icons.add),
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
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Pilih Sumber Foto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanFoodWithAI(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
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
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI sedang menganalisis makanan...'),
          ],
        ),
      ),
    );

    final result = await GeminiService().analyzeFoodImage(File(image.path));
    
    // ignore: use_build_context_synchronously
    Navigator.pop(context); // Tutup loading dialog

    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${result['error']}'), backgroundColor: Colors.red),
      );
      return;
    }

    _showAddFoodDialogWithPrefill(
      result['foodName'] ?? 'Makanan Tak Dikenal',
      (result['calories'] is num) ? (result['calories'] as num).toInt() : 0,
      (result['protein'] is num) ? (result['protein'] as num).toInt() : 0,
      (result['carbs'] is num) ? (result['carbs'] as num).toInt() : 0,
      (result['fats'] is num) ? (result['fats'] as num).toInt() : 0,
    );
  }

  Future<void> _processBarcodeScan(String barcode) async {
    // Tampilkan indikator loading saat memanggil API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mengecek database OpenFoodFacts...'),
          ],
        ),
      ),
    );

    final service = OpenFoodFactsService();
    try {
      final result = await service.getProductByBarcode(barcode);

      // Tutup dialog loading
      // ignore: use_build_context_synchronously
      if (mounted) Navigator.pop(context);

      if (result == null) {
      // Produk tidak ditemukan
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Produk Kosong'),
          content: Text('Barcode ($barcode) tidak dikenali atau belum terdaftar di OpenFoodFacts dunia.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddFoodDialog(); // Buka form manual
              },
              child: const Text('Isi Manual'),
            ),
          ],
        ),
      );
    } else {
      // Produk ditemukan! Langsung buka dialog prefill yang bisa diedit dan ada tombol AI-nya.
      _showAddFoodDialogWithPrefill(
        result['name'] as String,
        result['calories'] as int,
        result['protein'] as int,
        result['carbs'] as int,
        result['fats'] as int,
        nutriScore: result['nutriScore'] as String?,
      );
    }
    } on SocketException {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📶 Koneksi internet bermasalah. Periksa jaringan kamu.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _showAddFoodDialogWithPrefill(String name, int cals, int prot, int carbs, int fats, {String? nutriScore}) {
    final nameController = TextEditingController(text: name);
    final caloriesController = TextEditingController(text: cals.toString());
    final proteinController = TextEditingController(text: prot.toString());
    final carbsController = TextEditingController(text: carbs.toString());
    final fatsController = TextEditingController(text: fats.toString());
    final portionController = TextEditingController(text: '1.0');

    int baseCals = cals;
    int baseProt = prot;
    int baseCarbs = carbs;
    int baseFats = fats;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Konfirmasi Hasil Scan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nutriScore != null && nutriScore != '?') ...[
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: nutriScore == 'A' ? const Color(0xFF038141) :
                               nutriScore == 'B' ? const Color(0xFF85BB2F) :
                               nutriScore == 'C' ? const Color(0xFFFECB02) :
                               nutriScore == 'D' ? const Color(0xFFEE8100) :
                               nutriScore == 'E' ? const Color(0xFFE63E11) : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Nutri-Score: $nutriScore', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Anda bisa menyesuaikan porsi dan data sebelum menyimpan.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Makanan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: portionController,
                          decoration: const InputDecoration(
                            labelText: 'Porsi (X)', 
                            border: OutlineInputBorder(),
                            hintText: 'Misal: 0.5 atau 2',
                            prefixIcon: Icon(Icons.calculate_outlined, size: 20),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (val) {
                            final p = double.tryParse(val) ?? 1.0;
                            setDialogState(() {
                              caloriesController.text = (baseCals * p).round().toString();
                              proteinController.text = (baseProt * p).round().toString();
                              carbsController.text = (baseCarbs * p).round().toString();
                              fatsController.text = (baseFats * p).round().toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFFFD700)]),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.black),
                          tooltip: 'Isi Kalori via AI',
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            showDialog(
                              context: context, 
                              barrierDismissible: false,
                              builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                            );
                            try {
                              final foodName = nameController.text.trim();
                              final prompt = 'Estimasi kandungan gizi "${foodName}" untuk PORSI UMUM/WAJAR yang biasa dikonsumsi sekali makan (bukan per 100g). Balas HANYA JSON valid: {"calories": 200, "protein": 5, "carbs": 30, "fats": 8}. Nilai harus integer.';
                              final response = await GeminiService().getChatResponse([
                                {'role': 'system', 'content': 'Kamu adalah ahli gizi dan database nutrisi profesional. Selalu balas dengan satu JSON valid saja, tidak ada teks atau markdown lain sama sekali.'},
                                {'role': 'user', 'content': prompt}
                              ]);
                              Navigator.pop(context); // Tutup loading
                              final regex = RegExp(r'\{.*?\}', dotAll: true);
                              final match = regex.firstMatch(response);
                              if (match != null) {
                                final data = jsonDecode(match.group(0)!);
                                setDialogState(() {
                                  baseCals = data['calories'];
                                  baseProt = data['protein'];
                                  baseCarbs = data['carbs'];
                                  baseFats = data['fats'];
                                  
                                  final p = double.tryParse(portionController.text) ?? 1.0;
                                  caloriesController.text = (baseCals * p).round().toString();
                                  proteinController.text = (baseProt * p).round().toString();
                                  carbsController.text = (baseCarbs * p).round().toString();
                                  fatsController.text = (baseFats * p).round().toString();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Berhasil mengestimasi nutrisi!'), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi AI gagal.')));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: caloriesController,
                    decoration: const InputDecoration(labelText: 'Kalori (kcal)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => baseCals = (int.tryParse(val) ?? 0) ~/ (double.tryParse(portionController.text) ?? 1.0).clamp(0.1, 99.0),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: const InputDecoration(labelText: 'P', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: carbsController,
                          decoration: const InputDecoration(labelText: 'C', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: fatsController,
                          decoration: const InputDecoration(labelText: 'F', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
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
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<CalorieProvider>().addFood(
                    nameController.text,
                    int.tryParse(caloriesController.text) ?? baseCals,
                    protein: int.tryParse(proteinController.text) ?? baseProt,
                    carbs: int.tryParse(carbsController.text) ?? baseCarbs,
                    fats: int.tryParse(fatsController.text) ?? baseFats,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${nameController.text} berhasil ditambahkan! 🚀')),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.no_food_rounded, size: 64, color: theme.colorScheme.primary.withOpacity(0.8)),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2.seconds, color: theme.colorScheme.secondary.withOpacity(0.3))
           .animate() // independent floating animation
           .slideY(begin: -0.05, end: 0.05, duration: 1.5.seconds, curve: Curves.easeInOutSine)
           .then()
           .slideY(begin: 0.05, end: -0.05, duration: 1.5.seconds, curve: Curves.easeInOutSine),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Makanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + di bawah atau gunakan\nKamera AI untuk melacak makananmu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), height: 1.5),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }


  Widget _buildFoodList(List<CalorieEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Tambah padding bawah agar tidak tertutup tombol FAB
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return FoodListItem(
          entry: entry,
          onTap: () => _showEditFoodDialog(entry),
          onDelete: () => _confirmDeleteFood(context, entry),
        );
      },
    );
  }

  void _confirmDeleteFood(BuildContext context, CalorieEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Makanan?'),
        content: Text('Apakah kamu yakin ingin menghapus "${entry.foodName}" (${entry.calories} kcal)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (entry.id != null) {
                context.read<CalorieProvider>().removeFood(entry.id!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF6679),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
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
        title: const Text('Edit Makanan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Makanan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Karbo (g)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lemak (g)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
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
            child: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }


  void _showAddFoodDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatsController = TextEditingController();
    final searchController = TextEditingController();
    String? selectedFood;
    int selectedCalories = 0;

    // Gunakan database makanan Indonesia
    final Map<String, int> foodDatabase = FoodDatabase.indonesianFoods;
    List<String> filteredFoods = foodDatabase.keys.toList();

    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog tertutup saat klik di luar
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Tambah Makanan'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search bar untuk mencari makanan
                          TextField(
                            controller: searchController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Cari Makanan',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Ketik nama makanan...',
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value.isEmpty) {
                                  filteredFoods = foodDatabase.keys.toList();
                                } else {
                                  filteredFoods =
                                      foodDatabase.keys
                                          .where(
                                            (food) => food
                                                .toLowerCase()
                                                .contains(value.toLowerCase()),
                                          )
                                          .toList();
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Daftar makanan yang dapat di-scroll
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child:
                                filteredFoods.isEmpty
                                    ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Makanan tidak ditemukan'),
                                      ),
                                    )
                                    : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount:
                                          filteredFoods.length > 10
                                              ? 10
                                              : filteredFoods.length,
                                      itemBuilder: (context, index) {
                                        final food = filteredFoods[index];
                                        final calories = foodDatabase[food]!;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedFood = food;
                                              selectedCalories = calories;
                                              nameController.text = food;
                                              caloriesController.text =
                                                  calories.toString();
                                              
                                              // Menggunakan makronutrisi nyata dari database
                                              final macros = FoodDatabase.getMacros(food);
                                              if (macros != null) {
                                                proteinController.text = macros['protein'].toString();
                                                carbsController.text = macros['carbs'].toString();
                                                fatsController.text = macros['fats'].toString();
                                              } else {
                                                // Fallback ke 0 jika tidak ada
                                                proteinController.text = '0';
                                                carbsController.text = '0';
                                                fatsController.text = '0';
                                              }
                                            }); // Close setState
                                          },
                                          child: Container(
                                            color:
                                                selectedFood == food
                                                    ? Colors.blue.withAlpha(
                                                      (0.1 * 255).round(),
                                                    )
                                                    : null,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 16.0,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    food,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text('$calories kcal'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          ),

                          const Divider(height: 24),

                          // Tampilkan makanan yang dipilih
                          if (selectedFood != null)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(
                                  (0.1 * 255).round(),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dipilih: $selectedFood',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text('$selectedCalories kcal'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),
                          const Text('Atau masukkan makanan manual:'),
                          const SizedBox(height: 16),

                          // Input manual & AI Magic Request
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Makanan',
                                    border: OutlineInputBorder(),
                                    hintText: 'Cth: Sate Ayam 5 tusuk',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(colors: [Color(0xFFCD7F32), Color(0xFFFFD700)]),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.auto_awesome, color: Colors.black),
                                  tooltip: 'Isi Kalori via AI',
                                  onPressed: () async {
                                    if (nameController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ketik nama makanan dulu!')));
                                      return;
                                    }
                                    
                                    showDialog(
                                      context: context, 
                                      barrierDismissible: false,
                                      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                                    );
                                    
                                    try {
                                      final prompt = 'Estimasi kalori & makro dari "${nameController.text}". Balas HANYA dengan JSON valid, tanpa teks pembuka/penutup. Contoh: {"calories": 100, "protein": 10, "carbs": 20, "fats": 5}. Harus berisi integer.';
                                      final response = await GeminiService().getChatResponse([
                                        {'role': 'user', 'content': prompt}
                                      ]);
                                      
                                      Navigator.pop(context); // Tutup loading dialog
                                      
                                      final regex = RegExp(r'\{.*?\}', dotAll: true);
                                      final match = regex.firstMatch(response);
                                      if (match != null) {
                                        final jsonStr = match.group(0);
                                        final Map<String, dynamic> data = jsonDecode(jsonStr!);
                                        setState(() {
                                          selectedCalories = (data['calories'] is num) ? data['calories'].toInt() : 0;
                                          caloriesController.text = data['calories'].toString();
                                          proteinController.text = data['protein'].toString();
                                          carbsController.text = data['carbs'].toString();
                                          fatsController.text = data['fats'].toString();
                                          selectedFood = null;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Berhasil mengestimasi nutrisi!'), backgroundColor: Colors.green));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menerjemahkan respons AI.')));
                                      }
                                    } catch (e) {
                                      Navigator.pop(context); // Tutup loading dialog
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi AI gagal atau waktu habis.')));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'Kalori (kcal)',
                              border: OutlineInputBorder(),
                              hintText: 'Masukkan jumlah kalori',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: proteinController,
                                  decoration: const InputDecoration(
                                    labelText: 'Protein (g)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: carbsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Karbo (g)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: fatsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Lemak (g)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                      ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final calories = selectedFood != null
                            ? selectedCalories
                            : (int.tryParse(caloriesController.text) ?? 0);

                        // Validasi: nama tidak boleh kosong
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama makanan tidak boleh kosong'),
                              backgroundColor: Color(0xFFCF6679),
                            ),
                          );
                          return;
                        }

                        // Validasi: kalori harus lebih dari 0
                        if (calories <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kalori harus lebih dari 0 kcal'),
                              backgroundColor: Color(0xFFCF6679),
                            ),
                          );
                          return;
                        }

                        context.read<CalorieProvider>().addFood(
                          name,
                          calories,
                          protein: int.tryParse(proteinController.text) ?? 0,
                          carbs: int.tryParse(carbsController.text) ?? 0,
                          fats: int.tryParse(fatsController.text) ?? 0,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$name" ditambahkan ($calories kcal)'),
                            backgroundColor: const Color(0xFF1A1A1A),
                          ),
                        );
                      },
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
          ),
    );
  }
}
