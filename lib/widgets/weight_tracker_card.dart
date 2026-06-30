import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../screens/weight_log_screen.dart';

class WeightTrackerCard extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback onLogAdded;

  const WeightTrackerCard({super.key, this.userProfile, required this.onLogAdded});

  Widget _buildWorkoutStat(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double weight = userProfile?.weight ?? 0.0;
    final double height = userProfile?.height ?? 0.0;
    
    double bmi = 0.0;
    String bmiCategory = 'Belum ada data';
    Color bmiColor = theme.colorScheme.onSurfaceVariant;

    if (weight > 0 && height > 0) {
      final heightInMeters = height / 100;
      bmi = weight / (heightInMeters * heightInMeters);

      if (bmi < 18.5) {
        bmiCategory = 'Kurus (Underweight)';
        bmiColor = const Color(0xFF00B4DB); // Biru
      } else if (bmi < 24.9) {
        bmiCategory = 'Normal (Sehat)';
        bmiColor = const Color(0xFF38EF7D); // Hijau
      } else if (bmi < 29.9) {
        bmiCategory = 'Overweight';
        bmiColor = const Color(0xFFF2C94C); // Kuning
      } else {
        bmiCategory = 'Obesitas';
        bmiColor = theme.colorScheme.error; // Merah/Error
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF4CAF50)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Berat Badan & BMI',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WeightLogScreen()),
                    ).then((_) {
                      onLogAdded();
                    });
                  },
                  child: const Text('Log', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWorkoutStat(
                  context,
                  'Berat (kg)',
                  weight > 0 ? weight.toStringAsFixed(1) : '-',
                  Icons.monitor_weight,
                ),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                Column(
                  children: [
                    const Icon(Icons.speed, size: 28, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 8),
                    Text(
                      bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: bmiColor,
                      ),
                    ),
                    Text(bmiCategory, style: TextStyle(fontSize: 12, color: bmiColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
