import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/fuzzy_logic.dart';
import '../models/food_database.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import '../models/calorie_entry.dart';
import '../utils/notification_helper.dart';

class CalorieTrackerScreen extends StatefulWidget {
  const CalorieTrackerScreen({super.key});

  @override
  State<CalorieTrackerScreen> createState() => _CalorieTrackerScreenState();
}

class _CalorieTrackerScreenState extends State<CalorieTrackerScreen> {
  int _targetCalories = 2500; // Default target
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationSettings();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasProfile = prefs.getBool('has_profile') ?? false;

      if (hasProfile) {
        // Baca data profil
        final name = prefs.getString('name') ?? '';
        final age = prefs.getInt('age') ?? 0;
        final weight = prefs.getDouble('weight') ?? 0;
        final height = prefs.getDouble('height') ?? 0;
        final gender = prefs.getString('gender') ?? 'Pria';
        final activityLevel = prefs.getString('activity_level') ?? 'Sedang';
        final goal = prefs.getString('goal') ?? 'Bulking';

        // Buat objek UserProfile
        final userProfile = UserProfile(
          name: name,
          age: age,
          weight: weight,
          height: height,
          gender: gender,
          activityLevel: activityLevel,
          goal: goal,
        );

        // Gunakan FuzzyLogic untuk menghitung kebutuhan kalori
        final fuzzyLogic = FuzzyLogic();
        final calculatedCalories = fuzzyLogic.calculateCalories(userProfile);

        setState(() {
          _targetCalories = calculatedCalories;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final calorieProvider = context.watch<CalorieProvider>();
    final totalCalories = calorieProvider.totalConsumedCalories;
    final entries = calorieProvider.entries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Kalori'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalorieSummary(totalCalories),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty ? _buildEmptyState() : _buildFoodList(entries),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalorieSummary(int totalCalories) {
    final remainingCalories = _targetCalories - totalCalories;
    final isOverCalories = remainingCalories < 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Ringkasan Kalori Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalorieInfo('Target', '$_targetCalories', Colors.blue),
                _buildCalorieInfo(
                  'Dikonsumsi',
                  '$totalCalories',
                  Colors.green,
                ),
                _buildCalorieInfo(
                  'Sisa',
                  '${remainingCalories.abs()}',
                  isOverCalories ? Colors.red : Colors.orange,
                  prefix: isOverCalories ? '+' : '',
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_targetCalories > 0) ? (totalCalories / _targetCalories).clamp(0.0, 1.0) : 0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                totalCalories > _targetCalories ? Colors.red : Colors.green,
              ),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieInfo(
    String label,
    String value,
    Color color, {
    String prefix = '',
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '$prefix$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text('kcal', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada makanan yang ditambahkan',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tekan tombol + untuk menambahkan makanan',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<CalorieEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(entry.foodName),
            subtitle: Text('${entry.calories} kcal | P: ${entry.protein}g | C: ${entry.carbs}g | F: ${entry.fats}g'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                if (entry.id != null) {
                  context.read<CalorieProvider>().removeFood(entry.id!);
                }
              },
            ),
          ),
        );
      },
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
                                              
                                              // Estimasi sederhana makronutrisi harian
                                              proteinController.text = (calories * 0.30 / 4).round().toString();
                                              carbsController.text = (calories * 0.50 / 4).round().toString();
                                              fatsController.text = (calories * 0.20 / 9).round().toString();
                                            });
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

                          // Input manual
                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Makanan',
                              border: OutlineInputBorder(),
                              hintText: 'Masukkan nama makanan',
                            ),
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
                        if (nameController.text.isNotEmpty) {
                          context.read<CalorieProvider>().addFood(
                            nameController.text,
                            selectedFood != null
                                ? selectedCalories
                                : (int.tryParse(caloriesController.text) ?? 0),
                            protein: int.tryParse(proteinController.text) ?? 0,
                            carbs: int.tryParse(carbsController.text) ?? 0,
                            fats: int.tryParse(fatsController.text) ?? 0,
                          );
                          Navigator.pop(context);
                        } else {
                          // Tampilkan pesan error jika nama makanan kosong
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nama makanan tidak boleh kosong'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Pengaturan Notifikasi'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aktifkan notifikasi untuk mengingatkan Anda tentang target kalori harian.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Notifikasi Kalori'),
                      subtitle: const Text('Pengingat target kalori harian'),
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setDialogState(() {
                          _notificationsEnabled = value;
                        });
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveNotificationSettings(value);

                        // Show confirmation message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Notifikasi diaktifkan'
                                  : 'Notifikasi dinonaktifkan',
                            ),
                            backgroundColor:
                                value ? Colors.green : Colors.orange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  // Save notification settings to SharedPreferences
  Future<void> _saveNotificationSettings(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      // Minta permission lalu jadwalkan notifikasi harian
      await NotificationHelper.requestPermission();
      await NotificationHelper.scheduleDailyNotifications();
    } else {
      // Batalkan semua notifikasi
      await NotificationHelper.cancelAllNotifications();
    }
  }
}
