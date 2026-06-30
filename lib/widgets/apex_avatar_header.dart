import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Header AI Coach Apex — avatar besar dengan border gold + badge Level
/// + speech bubble dengan teks ter-highlight. Sesuai desain Stitch.
class ApexAvatarHeader extends StatelessWidget {
  final String greeting;
  final List<_HighlightSpan> highlights;
  final int apexLevel;

  const ApexAvatarHeader({
    super.key,
    required this.greeting,
    this.highlights = const [],
    this.apexLevel = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Avatar besar dengan border gold ───────────────────────────────
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kPrimaryGold, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.kPrimaryGold.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/apex_avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.kPrimaryGold.withOpacity(0.15),
                    child: const Center(
                      child: Text('🧙‍♂️', style: TextStyle(fontSize: 64)),
                    ),
                  ),
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -4, end: 4, duration: 2.5.seconds, curve: Curves.easeInOut),

            // Badge "Level 50" — overlap di bawah avatar
            Positioned(
              bottom: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0A300),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  'Level $apexLevel',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Speech bubble dengan highlight ────────────────────────────────
        _SpeechBubble(text: greeting, highlights: highlights),
      ],
    );
  }
}

/// Bagian teks yang perlu di-highlight warna oranye (misal nama user, angka)
class _HighlightSpan {
  final String text;
  const _HighlightSpan(this.text);
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  final List<_HighlightSpan> highlights;

  const _SpeechBubble({required this.text, required this.highlights});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.kDarkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.kPrimaryGold.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: isDark
                ? AppColors.kDarkSoftShadow
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: _buildHighlightedText(context, isDark),
        ),
        // Ekor speech bubble (segitiga di atas)
        Positioned(
          top: 0,
          left: 32,
          child: CustomPaint(
            size: const Size(16, 10),
            painter: _TrianglePainter(
              color: isDark ? AppColors.kDarkSurface : Colors.white,
              borderColor: AppColors.kPrimaryGold.withOpacity(0.5),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHighlightedText(BuildContext context, bool isDark) {
    final baseColor = isDark ? AppColors.kDarkText : const Color(0xFF211B11);
    final spans = <TextSpan>[];
    String remaining = text;

    for (final h in highlights) {
      final idx = remaining.indexOf(h.text);
      if (idx == -1) continue;
      if (idx > 0) {
        spans.add(TextSpan(text: remaining.substring(0, idx)));
      }
      spans.add(TextSpan(
        text: h.text,
        style: const TextStyle(
          color: AppColors.kPrimaryOrange,
          fontWeight: FontWeight.w800,
        ),
      ));
      remaining = remaining.substring(idx + h.text.length);
    }
    if (remaining.isNotEmpty) {
      spans.add(TextSpan(text: remaining));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text));

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: baseColor,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper untuk membangun greeting dengan highlight otomatis
class ApexGreetingBuilder {
  static ({String text, List<_HighlightSpan> highlights}) build({
    required String name,
    required int proteinGap,
  }) {
    final text = 'Halo $name! Hari ini kamu masih butuh ${proteinGap}g '
        'protein untuk mencapai target. Mau saya rekomendasikan makanan?';
    return (
      text: text,
      highlights: [_HighlightSpan(name), _HighlightSpan('${proteinGap}g protein')],
    );
  }
}
