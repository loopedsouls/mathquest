import 'package:flutter/material.dart';

/// XP gained animation widget
class XpAnimation extends StatelessWidget {
  final int xpGained;
  final Color primaryColor;

  const XpAnimation({
    super.key,
    required this.xpGained,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: primaryColor,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            '+$xpGained XP',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
