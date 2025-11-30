import 'package:flutter/material.dart';

/// Quick actions widget for home screen
class QuickActions extends StatelessWidget {
  final VoidCallback onStartLesson;
  final VoidCallback onViewLeaderboard;
  final VoidCallback onOpenSettings;

  const QuickActions({
    super.key,
    required this.onStartLesson,
    required this.onViewLeaderboard,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.play_arrow,
            label: 'Jogar',
            color: const Color(0xFF6C63FF),
            onTap: onStartLesson,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.leaderboard,
            label: 'Ranking',
            color: const Color(0xFFFF6B6B),
            onTap: onViewLeaderboard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.settings,
            label: 'Config',
            color: const Color(0xFF00BFA5),
            onTap: onOpenSettings,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
