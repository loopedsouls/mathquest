import 'package:flutter/material.dart';

import '../learning/exercise_screen.dart';
import '../ai/image_classification_screen.dart';
import '../math_tools/matrix_conversion_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(
      child: Text('Trabalhar com Matrizes', style: TextStyle(fontSize: 18)),
    ),
    const ExerciseScreen(), // Tela de Exercícios
    const Center(
      child: Text('Histórico de Erros', style: TextStyle(fontSize: 18)),
    ),
    const Center(child: Text('Configurações', style: TextStyle(fontSize: 18))),
    const MatrixConversionScreen(), // Tela de Conversão de Matrizes
    const ImageClassificationScreen(), // Tela de Classificação de Imagem
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calculate),
                label: Text('Matrizes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school),
                label: Text('Exercícios'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('Histórico'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Configurações'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.transform),
                label: Text('Conversão'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.image),
                label: Text('Classificação'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
