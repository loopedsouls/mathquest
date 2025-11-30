import 'package:flutter/material.dart';

/// Star rating widget for results
class StarRating extends StatelessWidget {
  final int stars;
  final double size;

  const StarRating({
    super.key,
    required this.stars,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < stars;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 200)),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: size,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
