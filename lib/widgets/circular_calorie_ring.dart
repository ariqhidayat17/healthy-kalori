import 'package:flutter/material.dart';
import 'dart:math';

class CircularCalorieRing extends StatefulWidget {
  final int consumed;
  final int target;
  final double size;

  const CircularCalorieRing({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 180.0,
  });

  @override
  State<CircularCalorieRing> createState() => _CircularCalorieRingState();
}

class _CircularCalorieRingState extends State<CircularCalorieRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: _calculateProgress()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CircularCalorieRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.consumed != widget.consumed || oldWidget.target != widget.target) {
      _animation = Tween<double>(
        begin: _animation.value, 
        end: _calculateProgress()
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  double _calculateProgress() {
    if (widget.target <= 0) return 0.0;
    double progress = widget.consumed / widget.target;
    return progress > 1.0 ? 1.0 : progress; // Clamp at 1.0
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isOverLimit = widget.consumed > widget.target;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: RingPainter(
              progress: _animation.value,
              ringColor: isOverLimit ? const Color(0xFFFF5252) : const Color(0xFF4CAF50), // Duolingo green, red if over
              backgroundColor: Colors.grey[200]!,
              strokeWidth: widget.size * 0.12,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.consumed}',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w900, // Extra bold
                      color: const Color(0xFF333333),
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    ' / ${widget.target} kcal',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color backgroundColor;
  final double strokeWidth;

  RingPainter({
    required this.progress,
    required this.ringColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = (size.width - strokeWidth) / 2;

    // Draw background ring
    Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress ring
    Paint progressPaint = Paint()
      ..color = ringColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2; // Start from top
    double sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
  }
}
