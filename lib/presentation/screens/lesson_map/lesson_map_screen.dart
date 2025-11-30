import 'package:flutter/material.dart';
import '../../../app/routes.dart';
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

  final List<String> _units = [
    'Números',
    'Álgebra',
    'Geometria',
    'Grandezas e Medidas',
    'Probabilidade e Estatística',
  ];

  final List<String> _years = ['6º ano', '7º ano', '8º ano', '9º ano'];

  // Sample lesson data - TODO: Replace with data from repository
  final List<LessonNodeData> _lessons = [
    const LessonNodeData(
      id: '1',
      title: 'Números Naturais',
      status: LessonStatus.completed,
      stars: 3,
    ),
    const LessonNodeData(
      id: '2',
      title: 'Operações Básicas',
      status: LessonStatus.completed,
      stars: 2,
    ),
    const LessonNodeData(
      id: '3',
      title: 'Múltiplos e Divisores',
      status: LessonStatus.current,
      stars: 0,
    ),
    const LessonNodeData(
      id: '4',
      title: 'Números Primos',
      status: LessonStatus.locked,
      stars: 0,
    ),
    const LessonNodeData(
      id: '5',
      title: 'MMC e MDC',
      status: LessonStatus.locked,
      stars: 0,
    ),
    const LessonNodeData(
      id: '6',
      title: 'Frações',
      status: LessonStatus.locked,
      stars: 0,
    ),
  ];

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
            child: SingleChildScrollView(
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
