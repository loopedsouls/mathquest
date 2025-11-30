import 'package:flutter/material.dart';

/// Achievement grid for profile
class AchievementGrid extends StatelessWidget {
  const AchievementGrid({super.key});

  // Sample achievements - TODO: Load from repository
  static const List<_AchievementData> _achievements = [
    _AchievementData(
      id: '1',
      title: 'Primeiro Passo',
      description: 'Complete sua primeira lição',
      icon: Icons.play_arrow,
      isUnlocked: true,
    ),
    _AchievementData(
      id: '2',
      title: 'Sequência de 7 Dias',
      description: 'Estude por 7 dias seguidos',
      icon: Icons.local_fire_department,
      isUnlocked: true,
    ),
    _AchievementData(
      id: '3',
      title: 'Nota Máxima',
      description: 'Obtenha 100% em uma lição',
      icon: Icons.star,
      isUnlocked: true,
    ),
    _AchievementData(
      id: '4',
      title: 'Explorador',
      description: 'Complete lições em todas as unidades',
      icon: Icons.explore,
      isUnlocked: false,
    ),
    _AchievementData(
      id: '5',
      title: 'Mestre do Tempo',
      description: 'Complete uma lição em menos de 2 minutos',
      icon: Icons.timer,
      isUnlocked: false,
    ),
    _AchievementData(
      id: '6',
      title: 'Colecionador',
      description: 'Desbloqueie 10 conquistas',
      icon: Icons.emoji_events,
      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return _AchievementCard(data: achievement);
      },
    );
  }
}

class _AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  const _AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

class _AchievementCard extends StatelessWidget {
  final _AchievementData data;

  const _AchievementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Show achievement details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(data.title),
              content: Text(data.description),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: data.isUnlocked
                ? null
                : Colors.grey[100],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.isUnlocked
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: data.isUnlocked ? Colors.amber : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: data.isUnlocked ? null : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!data.isUnlocked)
                const Icon(
                  Icons.lock,
                  size: 14,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
