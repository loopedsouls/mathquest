import 'package:flutter/material.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';

/// Leaderboard list item
class LeaderboardItem extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardItem({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.isCurrentUser
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: entry.isCurrentUser
            ? BorderSide(color: Theme.of(context).primaryColor)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 30,
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: entry.isCurrentUser
                      ? Theme.of(context).primaryColor
                      : null,
                ),
              ),
            ),
            // Avatar
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(
                entry.username[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Text('Nível ${entry.level}'),
        trailing: Text(
          '${entry.xp} XP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
