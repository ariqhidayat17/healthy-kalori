import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

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
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              
              // Informasi Dasar
              const Text(
                'Informasi Dasar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
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
              
              // Jenis Kelamin
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                value: _gender,
                items: ['Pria', 'Wanita'].map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value ?? 'Pria';
                  });
                },
                onSaved: (value) {
                  _gender = value ?? 'Pria';
                },
              ),
              const SizedBox(height: 16),
              
              // Usia, Berat, dan Tinggi
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Usia',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixText: 'tahun',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _age = int.tryParse(value!) ?? 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'Berat Badan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.monitor_weight),
                        suffixText: 'kg',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _weight = double.tryParse(value!) ?? 0;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: 'Tinggi Badan',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.height),
                        suffixText: 'cm',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _height = double.tryParse(value!) ?? 0;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Level Aktivitas
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Level Aktivitas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_run),
                ),
                value: _activityLevel,
                items: const [
                  DropdownMenuItem(value: 'Ringan', child: Text('Ringan (1-3 hari/minggu)')),
                  DropdownMenuItem(value: 'Sedang', child: Text('Sedang (3-5 hari/minggu)')),
                  DropdownMenuItem(value: 'Berat', child: Text('Berat (6-7 hari/minggu)')),
                  DropdownMenuItem(value: 'Sangat Berat', child: Text('Sangat Berat (2x sehari)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value!;
                  });
                },
                onSaved: (value) {
                  _activityLevel = value!;
                },
              ),
              const SizedBox(height: 16),
              
              // Goal Fitness
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Goal Fitness',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                value: _goal,
                items: const [
                  DropdownMenuItem(value: 'Bulking', child: Text('Bulking (Menambah Massa Otot)')),
                  DropdownMenuItem(value: 'Cutting', child: Text('Cutting (Menurunkan Lemak)')),
                  DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance (Mempertahankan)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _goal = value!;
                  });
                },
                onSaved: (value) {
                  _goal = value!;
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
                        
                        if (context.mounted) {
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
                  child: const Text('Simpan Profil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
