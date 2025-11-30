import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Achievement grid for profile
class AchievementGrid extends StatefulWidget {
  const AchievementGrid({super.key});

  @override
  State<AchievementGrid> createState() => _AchievementGridState();
}

class _AchievementGridState extends State<AchievementGrid> {
  static const String _unlockedAchievementsKey = 'unlocked_achievements';

  // All available achievements
  static const List<_AchievementData> _allAchievements = [
    _AchievementData(
      id: 'primeiro_passo',
      title: 'Primeiro Passo',
      description: 'Complete sua primeira lição',
      icon: Icons.play_arrow,
    ),
    _AchievementData(
      id: 'sequencia_7',
      title: 'Sequência de 7 Dias',
      description: 'Estude por 7 dias seguidos',
      icon: Icons.local_fire_department,
    ),
    _AchievementData(
      id: 'nota_maxima',
      title: 'Nota Máxima',
      description: 'Obtenha 100% em uma lição',
      icon: Icons.star,
    ),
    _AchievementData(
      id: 'explorador',
      title: 'Explorador',
      description: 'Complete lições em todas as unidades',
      icon: Icons.explore,
    ),
    _AchievementData(
      id: 'mestre_tempo',
      title: 'Mestre do Tempo',
      description: 'Complete uma lição em menos de 2 minutos',
      icon: Icons.timer,
    ),
    _AchievementData(
      id: 'colecionador',
      title: 'Colecionador',
      description: 'Desbloqueie 10 conquistas',
      icon: Icons.emoji_events,
    ),
    _AchievementData(
      id: 'dedicado',
      title: 'Dedicado',
      description: 'Estude por 30 dias seguidos',
      icon: Icons.calendar_month,
    ),
    _AchievementData(
      id: 'mestre_numeros',
      title: 'Mestre dos Números',
      description: 'Complete todas as lições de Números',
      icon: Icons.numbers,
    ),
  ];

  Set<String> _unlockedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList(_unlockedAchievementsKey) ?? [];
    
    setState(() {
      _unlockedIds = unlockedList.toSet();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _allAchievements.length,
      itemBuilder: (context, index) {
        final achievement = _allAchievements[index];
        final isUnlocked = _unlockedIds.contains(achievement.id);
        return _AchievementCard(
          data: achievement,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _AchievementData {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _AchievementData({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _AchievementCard extends StatelessWidget {
  final _AchievementData data;
  final bool isUnlocked;

  const _AchievementCard({
    required this.data,
    required this.isUnlocked,
  });

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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    data.icon,
                    size: 48,
                    color: isUnlocked ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(data.description),
                  const SizedBox(height: 8),
                  Text(
                    isUnlocked ? '✅ Desbloqueada!' : '🔒 Bloqueada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
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
            color: isUnlocked
                ? null
                : Colors.grey[100],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: isUnlocked ? Colors.amber : Colors.grey,
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
                  color: isUnlocked ? null : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isUnlocked)
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
