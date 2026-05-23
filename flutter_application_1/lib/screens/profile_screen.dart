import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';
import 'main_screen.dart';
import '../utils/notification_helper.dart';
import 'progress_photo_screen.dart';
import 'weight_log_screen.dart';
import '../services/backup_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileComplete;
  
  const ProfileScreen({super.key, this.onProfileComplete});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Data profil
  String _name = '';
  int _age = 0;
  double _weight = 0;
  double _height = 0;
  String _gender = 'Pria';
  String _activityLevel = 'Sedang';
  String _goal = 'Bulking';
  bool _notificationsEnabled = false;
  
  // Controller untuk form
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Muat data profil yang tersimpan
    _loadSavedProfile();
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, [String? suffix]) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFBBAA88)),
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Color(0xFFD4AF37)),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCF6679), width: 2),
      ),
    );
  }
  
  Future<void> _loadSavedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasProfile = prefs.getBool('has_profile') ?? false;
      
      if (hasProfile) {
        setState(() {
          _name = prefs.getString('name') ?? '';
          _age = prefs.getInt('age') ?? 0;
          _weight = prefs.getDouble('weight') ?? 0;
          _height = prefs.getDouble('height') ?? 0;
          _gender = prefs.getString('gender') ?? 'Pria';
          _activityLevel = prefs.getString('activity_level') ?? 'Sedang';
          _goal = prefs.getString('goal') ?? 'Bulking';
          _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
          
          // Update controllers
          _nameController.text = _name;
          _ageController.text = _age > 0 ? _age.toString() : '';
          _weightController.text = _weight > 0 ? _weight.toString() : '';
          _heightController.text = _height > 0 ? _height.toString() : '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFD4AF37),
                  child: Icon(Icons.person, size: 50, color: Color(0xFF111111)),
                ),
              ),
              const SizedBox(height: 24),
              
              // Card: Log Berat Badan
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD4AF37),
                    child: Icon(Icons.monitor_weight_outlined, color: Colors.black),
                  ),
                  title: const Text('Log Berat Badan'),
                  subtitle: const Text('Pantau tren berat & BMI kamu'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeightLogScreen()),
                    );
                  },
                ),
              ),
              // Card: Log Progres Foto
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFD4AF37),
                    child: Icon(Icons.fitness_center, color: Colors.black),
                  ),
                  title: const Text('Log Progres Fisik Badan'),
                  subtitle: const Text('Simpan foto Before-After bulananmu'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProgressPhotoScreen()),
                    );
                  },
                ),
              ),

              // Informasi Dasar
              const Text(
                'Informasi Dasar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Nama', Icons.person),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              
              // Usia & Jenis Kelamin
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _ageController,
                      decoration: _buildInputDecoration('Usia', Icons.calendar_today, 'thn'),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib' : null,
                      onSaved: (value) => _age = int.tryParse(value!) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      decoration: _buildInputDecoration('Gender', Icons.wc),
                      value: _gender,
                      items: ['Pria', 'Wanita'].map((gender) => DropdownMenuItem(value: gender, child: Text(gender))).toList(),
                      onChanged: (value) => setState(() => _gender = value ?? 'Pria'),
                      onSaved: (value) => _gender = value ?? 'Pria',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bagian: Dimensi Tubuh (Berat & Tinggi)
              const Text(
                'Dimensi Tubuh',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: _buildInputDecoration('Berat Badan', Icons.monitor_weight_outlined, 'kg'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib' : null,
                      onSaved: (value) => _weight = double.tryParse(value!) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: _buildInputDecoration('Tinggi Badan', Icons.height, 'cm'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => (value == null || value.isEmpty) ? 'Wajib' : null,
                      onSaved: (value) => _height = double.tryParse(value!) ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bagian: Aktivitas & Target
              const Text(
                'Aktivitas & Target',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Level Aktivitas
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration('Level Aktivitas', Icons.directions_run),
                value: _activityLevel,
                items: const [
                  DropdownMenuItem(value: 'Ringan', child: Text('Ringan (1-3 hari/minggu)')),
                  DropdownMenuItem(value: 'Sedang', child: Text('Sedang (3-5 hari/minggu)')),
                  DropdownMenuItem(value: 'Berat', child: Text('Berat (6-7 hari/minggu)')),
                  DropdownMenuItem(value: 'Sangat Berat', child: Text('Sangat Berat (2x sehari)')),
                ],
                onChanged: (value) => setState(() => _activityLevel = value!),
                onSaved: (value) => _activityLevel = value!,
              ),
              const SizedBox(height: 16),

              // Goal Fitness
              DropdownButtonFormField<String>(
                decoration: _buildInputDecoration('Goal Fitness', Icons.emoji_events_outlined),
                value: _goal,
                items: const [
                  DropdownMenuItem(value: 'Bulking', child: Text('Bulking (Menambah Massa Otot)')),
                  DropdownMenuItem(value: 'Cutting', child: Text('Cutting (Menurunkan Lemak)')),
                  DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance (Mempertahankan)')),
                ],
                onChanged: (value) => setState(() => _goal = value!),
                onSaved: (value) => _goal = value!,
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF2E2A1E)),
              const SizedBox(height: 16),
              const Text(
                'Pengaturan Notifikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pengingat Harian (Makan & Gym)'),
                subtitle: const Text('Menerima pengingat pintar teratur pada pagi, sore, dan malam hari.'),
                value: _notificationsEnabled,
                activeColor: const Color(0xFFD4AF37),
                onChanged: (bool value) async {
                  if (value) {
                    final granted = await NotificationHelper.requestPermission();
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Izin notifikasi tidak diberikan.')),
                      );
                      return;
                    }
                  }
                  
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  
                  // Langsung simpan dan jadwalkan (Instant Apply)
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications_enabled', value);
                  
                  if (value) {
                    await NotificationHelper.scheduleDailyNotifications();
                  } else {
                    await NotificationHelper.cancelAllNotifications();
                  }
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Notifikasi Harian Diaktifkan' : 'Notifikasi Dinonaktifkan',
                        ),
                        backgroundColor: value ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              
              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      
                      try {
                        // Simpan status bahwa profil sudah dibuat
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_profile', true);
                        
                        // Simpan data profil
                        await prefs.setString('name', _name);
                        await prefs.setInt('age', _age);
                        await prefs.setDouble('weight', _weight);
                        await prefs.setDouble('height', _height);
                        await prefs.setString('gender', _gender);
                        await prefs.setString('activity_level', _activityLevel);
                        await prefs.setString('goal', _goal);
                        await prefs.setBool('notifications_enabled', _notificationsEnabled);

                        if (_notificationsEnabled) {
                          await NotificationHelper.scheduleDailyNotifications();
                        } else {
                          await NotificationHelper.cancelAllNotifications();
                        }
                        
                        if (context.mounted) {
                          // Hitung ulang target kalori otomatis berdasarkan profil yang baru diupdate
                          await context.read<CalorieProvider>().calculateTargets();

                          // Tampilkan pesan sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil berhasil disimpan!')),
                          );
                          
                          // Panggil callback jika ada
                          if (widget.onProfileComplete != null) {
                            widget.onProfileComplete!();
                          } else {
                            // Navigasi ke halaman utama setelah profil disimpan
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 1)),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0D0D0D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menyiapkan file cadangan...')),
                    );
                    BackupService.exportDataAsJson(context);
                  },
                  icon: const Icon(Icons.backup_outlined, color: Color(0xFFD4AF37)),
                  label: const Text('Cadangkan Data (JSON)', style: TextStyle(color: Color(0xFFD4AF37))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD4AF37)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
