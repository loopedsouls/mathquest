import 'package:flutter/material.dart';

/// Result statistics widget
class ResultStats extends StatelessWidget {
  final int correct;
  final int total;
  final Color primaryColor;

  const ResultStats({
    super.key,
    required this.correct,
    required this.total,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (correct / total * 100).toInt() : 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Corretas',
              value: '$correct',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            _StatItem(
              label: 'Total',
              value: '$total',
              icon: Icons.help_outline,
              color: Colors.blue,
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey[300],
            ),
            _StatItem(
              label: 'Aproveitamento',
              value: '$percentage%',
              icon: Icons.percent,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
