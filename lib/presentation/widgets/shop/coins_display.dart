import 'package:flutter/material.dart';

/// Coins display widget for shop
class CoinsDisplay extends StatelessWidget {
  final int coins;

  const CoinsDisplay({
    super.key,
    required this.coins,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}
