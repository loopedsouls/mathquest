import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/lesson_repository_impl.dart';
import 'journey_map_game.dart';

/// Journey Map Widget using Flame engine
class JourneyMapWidget extends StatefulWidget {
  const JourneyMapWidget({super.key});

  @override
  State<JourneyMapWidget> createState() => _JourneyMapWidgetState();
}

class _JourneyMapWidgetState extends State<JourneyMapWidget> {
  final LessonRepositoryImpl _lessonRepository = LessonRepositoryImpl();
  List<JourneyNodeData> _nodes = [];
  bool _isLoading = true;
  JourneyMapGame? _game;

  @override
  void initState() {
    super.initState();
    _loadAllLessons();
  }

  Future<void> _loadAllLessons() async {
    try {
      final allLessonsRaw = await _lessonRepository.getAllLessons();
      
      // Create a mutable copy before sorting
      final allLessons = List.of(allLessonsRaw);
      
      // Sort by year and then by order within each category
      allLessons.sort((a, b) {
        final yearCompare = _yearToInt(a.schoolYear).compareTo(_yearToInt(b.schoolYear));
        if (yearCompare != 0) return yearCompare;
        final unitCompare = a.thematicUnit.compareTo(b.thematicUnit);
        if (unitCompare != 0) return unitCompare;
        return a.order.compareTo(b.order);
      });

      final prefs = await SharedPreferences.getInstance();
      final completedLessons = prefs.getStringList('completed_lessons') ?? [];
      final unlockedIds = prefs.getStringList('unlocked_lessons') ?? 
          ['numeros_6_1', 'algebra_6_1', 'geometria_6_1', 'grandezas_6_1', 'estatistica_6_1',
           'numeros_7_1', 'algebra_7_1', 'geometria_7_1', 'grandezas_7_1', 'estatistica_7_1',
           'numeros_8_1', 'algebra_8_1', 'geometria_8_1', 'grandezas_8_1', 'estatistica_8_1',
           'numeros_9_1', 'algebra_9_1', 'geometria_9_1', 'grandezas_9_1', 'estatistica_9_1'];
      final lessonStars = prefs.getString('lesson_stars');
      final starsMap = lessonStars != null 
          ? _parseStarsMap(lessonStars)
          : <String, int>{};

      final nodes = <JourneyNodeData>[];
      for (int i = 0; i < allLessons.length; i++) {
        final lesson = allLessons[i];
        final isCompleted = completedLessons.contains(lesson.id);
        final isUnlocked = unlockedIds.contains(lesson.id) || !lesson.isLocked;
        
        JourneyNodeStatus status;
        if (isCompleted) {
          status = JourneyNodeStatus.completed;
        } else if (isUnlocked) {
          status = JourneyNodeStatus.current;
        } else {
          status = JourneyNodeStatus.locked;
        }

        nodes.add(JourneyNodeData(
          id: lesson.id,
          title: lesson.title,
          subtitle: '${lesson.schoolYear} • ${lesson.thematicUnit}',
          status: status,
          stars: starsMap[lesson.id] ?? 0,
          order: i + 1,
        ));
      }

      if (mounted) {
        setState(() {
          _nodes = nodes;
          _game = null; // Reset game to be recreated with new nodes
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading lessons for journey map: $e');
      if (mounted) {
        setState(() {
          _nodes = [];
          _game = null;
          _isLoading = false;
        });
      }
    }
  }

  int _yearToInt(String year) {
    switch (year) {
      case '6º ano': return 6;
      case '7º ano': return 7;
      case '8º ano': return 8;
      case '9º ano': return 9;
      default: return 0;
    }
  }

  Map<String, int> _parseStarsMap(String json) {
    try {
      final trimmed = json.trim();
      if (trimmed.isEmpty || trimmed == '{}') return {};
      final content = trimmed.substring(1, trimmed.length - 1);
      if (content.isEmpty) return {};
      final result = <String, int>{};
      final pairs = content.split(',');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '');
          final value = int.tryParse(parts[1].trim()) ?? 0;
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _onNodeTap(JourneyNodeData node) {
    if (node.status == JourneyNodeStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔒 Complete as lições anteriores para desbloquear "${node.title}"'),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show lesson details bottom sheet
    _showLessonDetails(node);
  }

  void _showLessonDetails(JourneyNodeData node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: node.status == JourneyNodeStatus.completed 
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                node.status == JourneyNodeStatus.completed ? '✓ Concluída' : '▶ Disponível',
                style: TextStyle(
                  color: node.status == JourneyNodeStatus.completed 
                      ? Colors.green 
                      : Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              node.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              node.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            // Stars
            if (node.status == JourneyNodeStatus.completed)
              Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      i < node.stars ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${node.stars}/3 estrelas',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed(
                    AppRoutes.gameplay,
                    arguments: {'lessonId': node.id},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: node.status == JourneyNodeStatus.completed 
                      ? Colors.green 
                      : Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  node.status == JourneyNodeStatus.completed 
                      ? 'Jogar Novamente' 
                      : 'Começar Lição',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF1a1a2e),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Carregando sua jornada...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    if (_nodes.isEmpty) {
      return Container(
        color: const Color(0xFF1a1a2e),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_off, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma lição disponível',
                style: TextStyle(color: Colors.grey[400], fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadAllLessons();
                },
                child: const Text('Recarregar'),
              ),
            ],
          ),
        ),
      );
    }

    // Create game only once per node list
    _game ??= JourneyMapGame(
      nodes: _nodes,
      onNodeTap: _onNodeTap,
    );

    return Stack(
      children: [
        // Flame game
        GameWidget(game: _game!),
        // Header overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF1a1a2e).withValues(alpha: 0),
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sua Jornada Matemática',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_nodes.where((n) => n.status == JourneyNodeStatus.completed).length}/${_nodes.length} lições concluídas',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Legend overlay
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendItem(color: Colors.green, label: 'Concluída'),
                SizedBox(height: 8),
                _LegendItem(color: Colors.amber, label: 'Disponível'),
                SizedBox(height: 8),
                _LegendItem(color: Colors.grey, label: 'Bloqueada'),
              ],
            ),
          ),
        ),
        // Zoom hint
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Arraste para navegar',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
