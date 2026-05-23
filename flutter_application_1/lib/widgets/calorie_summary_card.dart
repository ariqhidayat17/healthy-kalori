import 'package:flutter/material.dart';

class CalorieSummaryCard extends StatelessWidget {
  final int totalCalories;
  final int targetCalories;

  const CalorieSummaryCard({
    super.key,
    required this.totalCalories,
    required this.targetCalories,
  });

  Widget _buildCalorieInfo(
    BuildContext context,
    String label,
    String value,
    Color color, {
    String prefix = '',
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          '$prefix$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text('kcal', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingCalories = targetCalories - totalCalories;
    final isOverCalories = remainingCalories < 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Ringkasan Kalori Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCalorieInfo(context, 'Target', '$targetCalories', const Color(0xFF00B4DB)),
                _buildCalorieInfo(
                  context,
                  'Dikonsumsi',
                  '$totalCalories',
                  theme.colorScheme.primary,
                ),
                _buildCalorieInfo(
                  context,
                  'Sisa',
                  '${remainingCalories.abs()}',
                  isOverCalories ? theme.colorScheme.error : const Color(0xFF38EF7D),
                  prefix: isOverCalories ? '+' : '',
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final progress = (targetCalories > 0)
                    ? (totalCalories / targetCalories).clamp(0.0, 1.0)
                    : 0.0;
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutQuart,
                      height: 10,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          colors: totalCalories > targetCalories
                              ? [theme.colorScheme.error, const Color(0xFFFF6B9D)]
                              : [theme.colorScheme.primary, theme.colorScheme.secondary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (totalCalories > targetCalories
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary)
                                .withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
