import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../config/app_colors.dart';

class FantasyCalorieRing extends StatelessWidget {
  final double current;
  final double target;
  final double size;

  const FantasyCalorieRing({
    super.key,
    required this.current,
    required this.target,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final double remaining = (target - current).clamp(0, target);
    final double progress = (current / target).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow (Subtle)
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.kPrimaryOrange.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Custom Painter for the Ring
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              trackColor: Colors.grey[200]!,
              progressGradient: AppColors.kGradientSunset,
            ),
          ),
          // Text Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${current.toInt()}',
                style: GoogleFonts.montserrat(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                '/ ${target.toInt()} kcal',
                style: GoogleFonts.poppins(
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kPrimaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥 ', style: TextStyle(fontSize: 12)),
                    Text(
                      'Sisa ${remaining.toInt()} kcal',
                      style: GoogleFonts.nunito(
                        fontSize: size * 0.06,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Gradient progressGradient;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.08;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Draw Track
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Draw Progress
    if (progress > 0) {
      final Paint progressPaint = Paint()
        ..shader = progressGradient.createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
