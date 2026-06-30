import 'package:flutter/material.dart';

class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int minXP;
  final int maxXP;
  
  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.minXP,
    required this.maxXP,
  });

  @override
  Widget build(BuildContext context) {
    // Hindari pembagian dengan nol
    double range = (maxXP - minXP).toDouble();
    if (range <= 0) range = 1.0;
    
    // Hitung progress 0.0 sampai 1.0
    double progress = (currentXP - minXP) / range;
    if (progress < 0) progress = 0.0;
    if (progress > 1) progress = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('XP PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('$currentXP / $maxXP XP', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background bar
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Warna background cerah
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Fill bar dengan animasi sederhana
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutQuart,
                  height: 12,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)], // Hijau segar (Duolingo style)
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}
