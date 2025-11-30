import 'package:flutter/material.dart';
import '../../screens/lesson_map/lesson_map_screen.dart';

/// Lesson node widget for lesson map
class LessonNode extends StatelessWidget {
  final LessonNodeData data;
  final VoidCallback onTap;

  const LessonNode({
    super.key,
    required this.data,
    required this.onTap,
  });

  Color get _backgroundColor {
    switch (data.status) {
      case LessonStatus.completed:
        return const Color(0xFF4CAF50);
      case LessonStatus.current:
        return const Color(0xFF6C63FF);
      case LessonStatus.locked:
        return Colors.grey[400]!;
    }
  }

  IconData get _icon {
    switch (data.status) {
      case LessonStatus.completed:
        return Icons.check;
      case LessonStatus.current:
        return Icons.play_arrow;
      case LessonStatus.locked:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Stars (for completed lessons)
          if (data.status == LessonStatus.completed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Icon(
                  index < data.stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          const SizedBox(height: 4),
          // Node
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          // Title
          SizedBox(
            width: 100,
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: data.status == LessonStatus.locked
                    ? Colors.grey[500]
                    : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
