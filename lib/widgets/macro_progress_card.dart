import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fantasy_card.dart';

class MacroProgressCard extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String icon;
  final String unit;

  const MacroProgressCard({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.icon,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (current / target).clamp(0.0, 1.0);
    final int percentage = (progress * 100).toInt();

    return Expanded(
      child: FantasyCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vertical Progress Bar (Debossed Well style)
            Container(
              width: 12,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: progress,
                    child: Container(
                      width: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Macro Label
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Colors.black45,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            // Current Value
            Text(
              '${current.toInt()}$unit',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            // Target Value
            Text(
              '/ ${target.toInt()}$unit',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black38,
              ),
            ),
            const SizedBox(height: 8),
            // Percentage
            Text(
              '$percentage%',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
