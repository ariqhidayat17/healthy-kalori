import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

class SemiCircleCalorieGauge extends StatelessWidget {
  final int currentCalories;
  final int targetCalories;

  const SemiCircleCalorieGauge({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    double progress = targetCalories > 0 ? (currentCalories / targetCalories) : 0.0;
    if (progress > 1.0) progress = 1.0;

    bool isSafe = currentCalories <= targetCalories;
    String statusText = isSafe ? 'Core Stabilized' : 'Overload Detected';
    Color statusColor = isSafe ? AppColors.kNatureGreen : AppColors.kHealthRed;
    IconData statusIcon = isSafe ? Icons.bolt_rounded : Icons.warning_amber_rounded;

    return Column(
      children: [
        Text(
          'ENERGY CORE OUTPUT',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.black45,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 240,
          height: 120,
          child: CustomPaint(
            painter: _SemiCirclePainter(progress: progress),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currentCalories',
                      style: GoogleFonts.poppins(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '/ $targetCalories KCAL',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.black38,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: 4),
            Text(
              statusText.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: statusColor,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SemiCirclePainter extends CustomPainter {
  final double progress;

  _SemiCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: size.width,
      height: size.width,
    );

    canvas.drawArc(rect, pi, pi, false, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = AppColors.kGradientSunset.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, pi, pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
