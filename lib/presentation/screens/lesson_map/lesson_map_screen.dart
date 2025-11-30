import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/lesson_repository_impl.dart';
import '../../widgets/lesson_map/lesson_node.dart';
import '../../widgets/lesson_map/map_path.dart';

/// Lesson map screen - Visual representation of learning path
class LessonMapScreen extends StatefulWidget {
  const LessonMapScreen({super.key});

  @override
  State<LessonMapScreen> createState() => _LessonMapScreenState();
}

class _LessonMapScreenState extends State<LessonMapScreen> {
  String _selectedUnit = 'Números';
  String _selectedYear = '6º ano';
  bool _isLoading = true;
  List<LessonNodeData> _lessons = [];
  
  final LessonRepositoryImpl _lessonRepository = LessonRepositoryImpl();

  final List<String> _units = [
    'Números',
    'Álgebra',
    'Geometria',
    'Grandezas e Medidas',
    'Probabilidade e Estatística',
  ];

  final List<String> _years = ['6º ano', '7º ano', '8º ano', '9º ano'];

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    
    try {
      // Get lessons from repository filtered by unit and year
      final allLessons = await _lessonRepository.getAllLessons();
      final filteredLessons = allLessons
          .where((l) => l.thematicUnit == _selectedUnit && l.schoolYear == _selectedYear)
          .toList();
      
      // Sort by order
      filteredLessons.sort((a, b) => a.order.compareTo(b.order));
      
      // Get completed lessons from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final completedLessons = prefs.getStringList('completed_lessons') ?? [];
      final lessonStars = prefs.getString('lesson_stars');
      final starsMap = lessonStars != null 
          ? Map<String, int>.from(
              (lessonStars.isNotEmpty ? _parseStarsMap(lessonStars) : {})
            )
          : <String, int>{};
      
      // Check which lessons are unlocked
      final unlockedIds = prefs.getStringList('unlocked_lessons') ?? 
          ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];
      
      // Convert to LessonNodeData
      final lessonNodes = <LessonNodeData>[];
      for (int i = 0; i < filteredLessons.length; i++) {
        final lesson = filteredLessons[i];
        final isCompleted = completedLessons.contains(lesson.id);
        final isUnlocked = unlockedIds.contains(lesson.id) || !lesson.isLocked;
        
        // Determine status
        LessonStatus status;
        if (isCompleted) {
          status = LessonStatus.completed;
        } else if (isUnlocked) {
          status = LessonStatus.current;
        } else {
          status = LessonStatus.locked;
        }
        
        lessonNodes.add(LessonNodeData(
          id: lesson.id,
          title: lesson.title,
          status: status,
          stars: starsMap[lesson.id] ?? 0,
        ));
      }
      
      if (mounted) {
        setState(() {
          _lessons = lessonNodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lessons = [];
          _isLoading = false;
        });
      }
    }
  }

  Map<String, int> _parseStarsMap(String json) {
    try {
      final Map<String, dynamic> decoded = Map<String, dynamic>.from(
        json.isNotEmpty ? _simpleJsonParse(json) : {}
      );
      return decoded.map((key, value) => MapEntry(key, value as int));
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _simpleJsonParse(String json) {
    // Simple JSON parsing for stars map
    try {
      final trimmed = json.trim();
      if (trimmed.isEmpty || trimmed == '{}') return {};
      
      final content = trimmed.substring(1, trimmed.length - 1);
      if (content.isEmpty) return {};
      
      final result = <String, dynamic>{};
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Lições'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_selectedUnit),
                  selected: true,
                  onSelected: (_) => _showUnitPicker(),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(_selectedYear),
                  selected: true,
                  onSelected: (_) => _showYearPicker(),
                ),
              ],
            ),
          ),
          // Lesson map
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lessons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma lição disponível\npara $_selectedUnit - $_selectedYear',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              for (int i = 0; i < _lessons.length; i++) ...[
                                if (i > 0)
                                  const MapPath(height: 40),
                                LessonNode(
                                  data: _lessons[i],
                                  onTap: () => _onLessonTap(_lessons[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _onLessonTap(LessonNodeData lesson) {
    if (lesson.status == LessonStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete as lições anteriores para desbloquear'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.gameplay,
      arguments: {'lessonId': lesson.id},
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar Lições',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Unidade Temática',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _units.map((unit) {
                  return ChoiceChip(
                    label: Text(unit),
                    selected: _selectedUnit == unit,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedUnit = unit);
                        Navigator.pop(context);
                        _loadLessons();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Ano Escolar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _years.map((year) {
                  return ChoiceChip(
                    label: Text(year),
                    selected: _selectedYear == year,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedYear = year);
                        Navigator.pop(context);
                        _loadLessons();
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _units.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_units[index]),
              trailing: _selectedUnit == _units[index]
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _selectedUnit = _units[index]);
                Navigator.pop(context);
                _loadLessons();
              },
            );
          },
        );
      },
    );
  }

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: _years.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_years[index]),
              trailing: _selectedYear == _years[index]
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                setState(() => _selectedYear = _years[index]);
                Navigator.pop(context);
                _loadLessons();
              },
            );
          },
        );
      },
    );
  }
}

/// Data class for lesson node
class LessonNodeData {
  final String id;
  final String title;
  final LessonStatus status;
  final int stars;

  const LessonNodeData({
    required this.id,
    required this.title,
    required this.status,
    required this.stars,
  });
}

enum LessonStatus { locked, current, completed }
