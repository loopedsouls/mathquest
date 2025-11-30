import 'package:flutter/material.dart';

/// Animated logo widget for splash screen
class AnimatedLogo extends StatelessWidget {
  final double size;

  const AnimatedLogo({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.calculate_rounded,
          size: size * 0.6,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
