import 'package:flutter/material.dart';

class MacroProgressBar extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final IconData icon;
  final Color color;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    double progress = target > 0 ? current / target : 0.0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 8),
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$current / $target',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
