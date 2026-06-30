import 'package:flutter/material.dart';
import '../screens/workout_logger_screen.dart';

class WorkoutTrackerCard extends StatelessWidget {
  final int streakDays;
  final String lastWorkoutDate;
  final VoidCallback onLogAdded;

  const WorkoutTrackerCard({
    super.key,
    required this.streakDays,
    required this.lastWorkoutDate,
    required this.onLogAdded,
  });

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

  Future<void> _logWorkout(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WorkoutLoggerScreen()),
    ).then((_) {
      onLogAdded();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: Color(0xFFFF9800)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tracking Latihan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWorkoutStat(
                  context,
                  'Streak',
                  '$streakDays hari',
                  Icons.local_fire_department,
                ),
                Container(width: 1, height: 50, color: Colors.grey[300]),
                _buildWorkoutStat(
                  context,
                  'Terakhir Latihan',
                  lastWorkoutDate,
                  Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _logWorkout(context),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Catat Latihan Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800), // Orange ceria
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
