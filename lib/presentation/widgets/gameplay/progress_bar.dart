import 'package:flutter/material.dart';

/// Progress bar for gameplay
class GameProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const GameProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (index) {
        final isCompleted = index < current - 1;
        final isCurrent = index == current - 1;

        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < total - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF4CAF50)
                  : isCurrent
                      ? const Color(0xFF6C63FF)
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
