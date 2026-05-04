import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_entry.dart';
import '../utils/database_helper.dart';

class WorkoutLoggerScreen extends StatefulWidget {
  const WorkoutLoggerScreen({super.key});

  @override
  State<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends State<WorkoutLoggerScreen> {
  List<WorkoutEntry> _todayWorkouts = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  final _formKey = GlobalKey<FormState>();
  String _exerciseName = '';
  int _sets = 0;
  int _reps = 0;
  double _weight = 0.0;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
      final logs = await DatabaseHelper.instance.getWorkoutsByDate(dateStr);
      
      if (mounted) {
        setState(() {
          _todayWorkouts = logs;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      _loadWorkouts();
    }
  }

  Future<void> _addWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final newEntry = WorkoutEntry(
      date: today,
      exerciseName: _exerciseName,
      sets: _sets,
      reps: _reps,
      weight: _weight,
    );

    await DatabaseHelper.instance.insertWorkout(newEntry);
    
    // Perbarui streak jika perlu
    final prefs = await SharedPreferences.getInstance();
    final lastWorkout = prefs.getString('last_workout_date') ?? '';
    if (lastWorkout != today) {
      int streak = prefs.getInt('workout_streak') ?? 0;
      final yesterday = DateFormat('dd/MM/yyyy').format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastWorkout == yesterday) {
        streak++;
      } else if (lastWorkout != '') {
        streak = 1;
      } else {
        streak = 1;
      }
      await prefs.setString('last_workout_date', today);
      await prefs.setInt('workout_streak', streak);
    }

    _formKey.currentState!.reset(); // Bersihkan form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Angkatan berhasil dicatat! 🚀')),
    );
    await _loadWorkouts();
  }

  Future<void> _deleteWorkout(int id) async {
    await DatabaseHelper.instance.deleteWorkout(id);
    await _loadWorkouts();
  }

  void _showAddWorkoutDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Color(0xFFF0E6C8)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catat Angkatan Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      final List<String> library = [
                        'Bench Press (Barbell)', 'Bench Press (Dumbbell)', 'Incline Bench Press', 'Decline Bench Press',
                        'Squat (Barbell)', 'Leg Press', 'Lunges', 'Leg Extension', 'Leg Curl', 'Calf Raise',
                        'Deadlift', 'Pull Up', 'Lat Pulldown', 'Barbell Row', 'Dumbbell Row', 'T-Bar Row',
                        'Overhead Press', 'Lateral Raise', 'Front Raise', 'Face Pull', 'Shrugs',
                        'Bicep Curl (Barbell)', 'Bicep Curl (Dumbbell)', 'Hammer Curl', 'Preacher Curl',
                        'Tricep Pushdown', 'Skull Crusher', 'Overhead Tricep Extension', 'Tricep Dip',
                        'Crunch', 'Sit Up', 'Russian Twist', 'Plank', 'Leg Raise', 'Push Up'
                      ];
                      return library.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      _exerciseName = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nama Latihan', 
                          hintText: 'Mulai ketik... (cth: Bench Press)',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
                        onSaved: (val) {
                           // Menyimpan input entah dari Autocomplete atau ketikan bebas
                           _exerciseName = val!;
                        },
                        onEditingComplete: onEditingComplete,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Beban (Kg)', hintText: 'opsional', prefixIcon: Icon(Icons.fitness_center, size: 16)),
                          onSaved: (val) => _weight = double.tryParse(val ?? '') ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Set'),
                          validator: (val) => val == null || val.isEmpty ? 'Isi' : null,
                          onSaved: (val) => _sets = int.tryParse(val!) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Rep'),
                          validator: (val) => val == null || val.isEmpty ? 'Isi' : null,
                          onSaved: (val) => _reps = int.tryParse(val!) ?? 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _addWorkout();
                        Navigator.pop(context);
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Logger')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate.day == DateTime.now().day &&
                              _selectedDate.month == DateTime.now().month &&
                              _selectedDate.year == DateTime.now().year
                          ? 'Catatan Latihan Hari Ini'
                          : 'Latihan: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range, color: Color(0xFFD4AF37)),
                      onPressed: () => _selectDate(context),
                      tooltip: 'Pilih Tanggal',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _todayWorkouts.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada angkatan tercatat hari ini.\nSaatnya masuk set pertama!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _todayWorkouts.length,
                        itemBuilder: (context, index) {
                          final w = _todayWorkouts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF2A2A2A),
                                child: Icon(Icons.fitness_center, color: Color(0xFFD4AF37)),
                              ),
                              title: Text(w.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${w.sets} Set x ${w.reps} Reps @ ${w.weight} kg', style: const TextStyle(color: Color(0xFFBBAA88))),
                              trailing: _selectedDate.day == DateTime.now().day &&
                                      _selectedDate.month == DateTime.now().month &&
                                      _selectedDate.year == DateTime.now().year
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFFCF6679)),
                                      onPressed: () {
                                        _deleteWorkout(w.id!);
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
      floatingActionButton: _selectedDate.day == DateTime.now().day &&
              _selectedDate.month == DateTime.now().month &&
              _selectedDate.year == DateTime.now().year
          ? FloatingActionButton.extended(
              onPressed: _showAddWorkoutDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Latihan'),
              backgroundColor: const Color(0xFFD4AF37),
            )
          : null,
    );
  }
}
