import 'dart:ui';
import 'package:flutter/material.dart';

class StyledBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double blur;

  const StyledBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
    this.blur = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with blur and opacity
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(1 - opacity),
                BlendMode.dstIn,
              ),
              child: Image.asset(
                'assets/images/heineken_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade900,
                          Colors.green.shade700,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Dark overlay for better content readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
