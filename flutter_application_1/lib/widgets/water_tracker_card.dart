import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/calorie_provider.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({super.key});

  void _showEditWaterTargetDialog(BuildContext context, int currentTarget) {
    final controller = TextEditingController(text: currentTarget.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Target Air Minum (ml)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target per hari',
            suffixText: 'ml',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 4000;
              if (val > 0) {
                context.read<CalorieProvider>().updateTargetWater(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterAddButton(BuildContext context, int amount, IconData icon) {
    return InkWell(
      onTap: () {
        context.read<CalorieProvider>().addWater(amount);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2632).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00B4DB), size: 18),
            const SizedBox(width: 6),
            Text('+$amount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calorieProvider = context.watch<CalorieProvider>();
    final consumedWater = calorieProvider.totalConsumedWater;
    final targetWater = calorieProvider.targetWater;
    final double waterPercentage = targetWater > 0 ? (consumedWater / targetWater).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2632), Color(0xFF13171F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Color(0xFF00B4DB), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Water Tracker',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (consumedWater > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            context.read<CalorieProvider>().addWater(-250);
                          },
                          child: Icon(Icons.undo, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        ),
                      ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: consumedWater),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return InkWell(
                          onTap: () => _showEditWaterTargetDialog(context, targetWater),
                          child: Text(
                            '$value / $targetWater ml',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4DB), fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(height: 14, decoration: BoxDecoration(color: const Color(0xFF0C1014), borderRadius: BorderRadius.circular(10))),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1400),
                      curve: Curves.elasticOut,
                      height: 14,
                      width: constraints.maxWidth * waterPercentage,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00B4DB).withOpacity(0.5), blurRadius: 8),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterAddButton(context, 250, Icons.local_drink),
                _buildWaterAddButton(context, 500, Icons.water_drop),
                _buildWaterAddButton(context, 1000, Icons.sports_mma), // Shaker
              ],
            ),
          ],
        ),
      ),
    );
  }
}
