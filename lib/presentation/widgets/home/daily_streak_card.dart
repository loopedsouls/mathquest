import 'package:flutter/material.dart';

/// Daily streak card widget
class DailyStreakCard extends StatelessWidget {
  final int currentStreak;
  final VoidCallback? onClaimReward;

  const DailyStreakCard({
    super.key,
    required this.currentStreak,
    this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    final canClaim = onClaimReward != null;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade400,
            ],
          ),
        ),
        child: Row(
          children: [
            // Fire icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sequência de Estudos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$currentStreak dias',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Claim button
            ElevatedButton(
              onPressed: canClaim ? onClaimReward : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepOrange,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(canClaim ? 'Resgatar' : 'Resgatado ✓'),
            ),
          ],
        ),
      ),
    );
  }
}
