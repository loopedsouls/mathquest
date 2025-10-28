import 'package:flutter/material.dart';

import 'community_screen.dart';
import 'concept_library_screen.dart';
import 'exercise_bank_screen.dart';
import 'interactive_simulator_screen.dart';
import '../features/user/screens/profile_screen.dart';
import 'representation_editor_screen.dart';
import 'resources_screen.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorador Semiótico'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConceptLibraryScreen()),
                );
              },
              child: const Text('Biblioteca de Conceitos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InteractiveSimulatorScreen()),
                );
              },
              child: const Text('Simulador Interativo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RepresentationEditorScreen()),
                );
              },
              child: const Text('Editor de Representações'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ExerciseBankScreen()),
                );
              },
              child: const Text('Banco de Exercícios'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CommunityScreen()),
                );
              },
              child: const Text('Comunidade'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: const Text('Perfil de Aprendizagem'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ResourcesScreen()),
                );
              },
              child: const Text('Recursos Educacionais'),
            ),
          ],
        ),
      ),
    );
  }
}
