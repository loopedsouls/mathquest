import 'package:flutter/material.dart';

import '../screens/educational_content_concept_card_screen.dart';


class ConceptLibraryScreen extends StatelessWidget {
  const ConceptLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Conceitos'),
      ),
      body: ListView(
        children: const [
          ConceptCard(
            conceptName: "Função Quadrática",
            representations: [
              "Equação Algébrica",
              "Gráfico Cartesiano",
              "Descrição Verbal"
            ],
            title: '',
            description: '',
          ),
          ConceptCard(
            conceptName: "Derivada",
            representations: [
              "Fórmula",
              "Gráfico da Função",
              "Interpretação Geométrica"
            ],
            title: '',
            description: '',
          ),
        ],
      ),
    );
  }
}
