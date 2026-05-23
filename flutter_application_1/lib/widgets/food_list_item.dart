import 'package:flutter/material.dart';
import '../models/calorie_entry.dart';

class FoodListItem extends StatelessWidget {
  final CalorieEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const FoodListItem({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(
          entry.foodName,
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        subtitle: Text(
          '${entry.calories} kcal  •  P: ${entry.protein}g  •  C: ${entry.carbs}g  •  L: ${entry.fats}g',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: 'Hapus makanan',
          onPressed: onDelete,
        ),
      ),
    );
  }
}
