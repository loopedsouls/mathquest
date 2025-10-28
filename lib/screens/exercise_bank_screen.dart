import 'package:flutter/material.dart';

import '../widgets/exercise_tile.dart';

class ExerciseBankScreen extends StatelessWidget {
  const ExerciseBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de Exercícios'),
      ),
      body: ListView(
        children: const [
          ExerciseTile(
            title: "Converter Equação para Gráfico",
            description: '',
          ),
          ExerciseTile(
            title: "Simplificar Expressão Algébrica",
            description: '',
          ),
        ],
      ),
    );
  }
}
