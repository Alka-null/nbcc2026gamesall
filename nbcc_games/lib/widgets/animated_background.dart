import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Dark gradient background
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF0F172A),
        const Color(0xFF1E293B),
        const Color(0xFF0F172A),
      ],
    );

    paint.shader = backgroundGradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Animated circles
    _drawAnimatedCircles(canvas, size);
  }

  void _drawAnimatedCircles(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Circle 1 - Gold
    final circle1X = size.width * 0.2 +
        math.sin(animationValue * 2 * math.pi) * 100;
    final circle1Y = size.height * 0.3 +
        math.cos(animationValue * 2 * math.pi) * 100;
    
    paint.color = const Color(0xFFFFD700).withOpacity(0.1);
    canvas.drawCircle(
      Offset(circle1X, circle1Y),
      150,
      paint,
    );

    // Circle 2 - Purple
    final circle2X = size.width * 0.8 +
        math.cos(animationValue * 2 * math.pi) * 120;
    final circle2Y = size.height * 0.7 +
        math.sin(animationValue * 2 * math.pi) * 80;
    
    paint.color = const Color(0xFF8B5CF6).withOpacity(0.15);
    canvas.drawCircle(
      Offset(circle2X, circle2Y),
      200,
      paint,
    );

    // Circle 3 - Blue
    final circle3X = size.width * 0.5 +
        math.sin(animationValue * 2 * math.pi + 1) * 150;
    final circle3Y = size.height * 0.5 +
        math.cos(animationValue * 2 * math.pi + 1) * 150;
    
    paint.color = const Color(0xFF6366F1).withOpacity(0.12);
    canvas.drawCircle(
      Offset(circle3X, circle3Y),
      180,
      paint,
    );

    // Grid pattern overlay
    _drawGrid(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSpacing = 100.0;

    // Vertical lines
    for (double i = 0; i < size.width; i += gridSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double i = 0; i < size.height; i += gridSpacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
