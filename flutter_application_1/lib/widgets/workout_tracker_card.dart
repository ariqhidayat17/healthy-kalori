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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking Latihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                _buildWorkoutStat(
                  context,
                  'Terakhir Latihan',
                  lastWorkoutDate,
                  Icons.calendar_today,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _logWorkout(context),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Catat Latihan Hari Ini'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
