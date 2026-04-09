import 'package:flutter/material.dart';

class SimpleCalorieTrackerScreen extends StatefulWidget {
  const SimpleCalorieTrackerScreen({super.key});

  @override
  State<SimpleCalorieTrackerScreen> createState() => _SimpleCalorieTrackerScreenState();
}

class _SimpleCalorieTrackerScreenState extends State<SimpleCalorieTrackerScreen> {
  final List<CalorieEntry> _calorieEntries = [];
  int _totalCalories = 0;
  final int _targetCalories = 2000; // Default target

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Kalori'),
      ),
      body: Column(
        children: [
          _buildCalorieCard(),
          Expanded(
            child: _calorieEntries.isEmpty
                ? _buildEmptyState()
                : _buildFoodList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalorieCard() {
    final remainingCalories = _targetCalories - _totalCalories;
    final isOverCalories = remainingCalories < 0;

    return Card(
      margin: const EdgeInsets.all(16),
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
                _buildCalorieInfo('Dikonsumsi', '$_totalCalories', Colors.green),
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
              value: (_totalCalories / _targetCalories).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _totalCalories > _targetCalories ? Colors.red : Colors.green,
              ),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieInfo(String label, String value, Color color, {String prefix = ''}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
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

  Widget _buildFoodList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calorieEntries.length,
      itemBuilder: (context, index) {
        final entry = _calorieEntries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(entry.foodName),
            subtitle: Text('${entry.calories} kcal'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeFood(index),
            ),
          ),
        );
      },
    );
  }

  void _showAddFoodDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Makanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Makanan'),
            ),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  caloriesController.text.isNotEmpty) {
                _addFood(
                  nameController.text,
                  int.tryParse(caloriesController.text) ?? 0,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _addFood(String name, int calories) {
    setState(() {
      _calorieEntries.add(CalorieEntry(
        foodName: name,
        calories: calories,
      ));
      _updateCalorieTotal();
    });
  }

  void _removeFood(int index) {
    setState(() {
      _calorieEntries.removeAt(index);
      _updateCalorieTotal();
    });
  }

  void _updateCalorieTotal() {
    _totalCalories = 0;
    for (final entry in _calorieEntries) {
      _totalCalories += entry.calories;
    }
  }
}

class CalorieEntry {
  final String foodName;
  final int calories;

  CalorieEntry({
    required this.foodName,
    required this.calories,
  });
}