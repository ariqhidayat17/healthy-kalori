import 'package:flutter/material.dart';

class HomeInfoSection extends StatelessWidget {
  const HomeInfoSection({super.key});

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String description}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Penting',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          icon: Icons.fitness_center,
          title: 'Kalori untuk Bodybuilder',
          description: 'Bodybuilder membutuhkan kalori lebih untuk membangun massa otot. Biasanya 15-20% lebih tinggi dari kebutuhan normal.',
        ),
        const SizedBox(height: 8),
        _buildInfoCard(
          context,
          icon: Icons.restaurant_menu,
          title: 'Tracking yang Konsisten',
          description: 'Lacak kalori Anda setiap hari untuk hasil yang optimal. Konsistensi adalah kunci keberhasilan.',
        ),
        const SizedBox(height: 24),
        Text(
          'Tips Kalori untuk Bodybuilder',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              title: Text('Makan 5-6 kali sehari dengan porsi lebih kecil', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              title: Text('Konsumsi protein 1.6-2.2g per kg berat badan', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              title: Text('Minum minimal 3-4 liter air per hari', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: theme.colorScheme.primary),
              title: Text('Konsumsi karbohidrat kompleks untuk energi', style: TextStyle(color: theme.colorScheme.onSurface)),
            ),
          ],
        ),
      ],
    );
  }
}
