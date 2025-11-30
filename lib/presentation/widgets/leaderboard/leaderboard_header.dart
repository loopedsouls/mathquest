import 'package:flutter/material.dart';
import '../../screens/leaderboard/leaderboard_screen.dart';

/// Leaderboard header showing top 3 users
class LeaderboardHeader extends StatelessWidget {
  final LeaderboardEntry? first;
  final LeaderboardEntry? second;
  final LeaderboardEntry? third;

  const LeaderboardHeader({
    super.key,
    this.first,
    this.second,
    this.third,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second place
          if (second != null)
            _PodiumEntry(
              entry: second!,
              rank: 2,
              height: 80,
            ),
          const SizedBox(width: 16),
          // First place
          if (first != null)
            _PodiumEntry(
              entry: first!,
              rank: 1,
              height: 100,
            ),
          const SizedBox(width: 16),
          // Third place
          if (third != null)
            _PodiumEntry(
              entry: third!,
              rank: 3,
              height: 60,
            ),
        ],
      ),
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;

  const _PodiumEntry({
    required this.entry,
    required this.rank,
    required this.height,
  });

  Color get _medalColor {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[300]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _medalColor, width: 3),
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              entry.username[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Username
        Text(
          entry.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        // XP
        Text(
          '${entry.xp} XP',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: _medalColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
