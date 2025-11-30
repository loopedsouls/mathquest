import 'package:flutter/material.dart';

/// Progress overview card showing progress by unit
class ProgressOverviewCard extends StatelessWidget {
  final Map<String, double> progressByUnit;

  const ProgressOverviewCard({
    super.key,
    required this.progressByUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso por Unidade',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to detailed progress
                  },
                  child: const Text('Ver mais'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...progressByUnit.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProgressItem(
                  title: entry.key,
                  progress: entry.value,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String title;
  final double progress;

  const _ProgressItem({
    required this.title,
    required this.progress,
  });

  Color get _progressColor {
    if (progress >= 0.7) return Colors.green;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
