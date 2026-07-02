import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../config/app_colors.dart';

/// Ring kalori — diterjemahkan presisi dari section "Calorie Ring Section"
/// di beranda/code.html.
///
/// Spek asli (SVG):
/// - Ukuran 200×200, radius lingkaran 84 (dari total diameter 200, r=84
///   berarti stroke-width 16 pas di tepi: 100-84-8=8px margin per sisi)
/// - stroke-width: 16
/// - Track: text-surface-container-high (#f3e6d6)
/// - Progress: gradient linear 2-stop, #ffb800 (kiri) → #fc8a40 (kanan)
/// - Drop shadow: rgba(255,184,0,0.2) blur 12px
/// - Center text: font-stat-number (Montserrat 900, 28px) + label-bold kecil
///   uppercase tracking-widest warna outline (#837560)
/// - TIDAK ADA pill "Sisa X kcal" di dalam ring — itu tambahan yang salah
///   di implementasi sebelumnya, sudah dihapus.
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
    final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    // Format angka ribuan dengan titik, sesuai HTML: "1.450" / "2.000 kcal"
    String formatThousands(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return buf.toString();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          // drop-shadow(0 4px 12px rgba(255,184,0,0.2)) dari .calorie-ring-container
          BoxShadow(
            color: AppColors.stPrimaryContainer.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatThousands(current.toInt()),
                style: GoogleFonts.montserrat(
                  fontSize: size * 0.14, // 28px pada 200px container
                  fontWeight: FontWeight.w900,
                  letterSpacing: size * 0.0007, // 0.02em relatif
                  color: AppColors.stOnSurface,
                ),
              ),
              Text(
                '/ ${formatThousands(target.toInt())} kcal',
                style: GoogleFonts.nunitoSans(
                  fontSize: size * 0.06, // ~12px pada 200px
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.stOutline,
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
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // SVG asli: viewBox 200x200, r=84, stroke-width=16
    // Rasio: strokeWidth/diameter = 16/200 = 0.08
    final double strokeWidth = size.width * 0.08;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width / 2) - (strokeWidth / 2);

    // Track — surface-container-high (#f3e6d6)
    final trackPaint = Paint()
      ..color = AppColors.stSurfaceContainerHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Gradient linear 2-stop persis SVG: #ffb800 → #fc8a40, horizontal (x1=0% x2=100%)
      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.stPrimaryContainer, AppColors.stSecondaryContainer],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
