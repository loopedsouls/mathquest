import 'package:flutter/material.dart';

import 'package:mathquest/features/community/community_screen.dart';
import 'package:mathquest/features/educational_content/concept_library_screen.dart';
import 'package:mathquest/features/learning/exercise_bank_screen.dart';
import 'package:mathquest/features/math_tools/interactive_simulator_screen.dart';
import 'package:mathquest/features/math_tools/representation_editor_screen.dart';

class MapeamentoSistematico extends StatefulWidget {
  const MapeamentoSistematico({super.key});
  @override
  State<MapeamentoSistematico> createState() => MapeamentoSistematicoState();
}

class MapeamentoSistematicoState extends State<MapeamentoSistematico> {
  var selectedIndex = 0;
  var isRailExtended = true; // Controle de extensão do NavigationRail

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = const ConceptLibraryScreen();
        break;
      case 1:
        page = const InteractiveSimulatorScreen();
        break;
      case 2:
        page = const RepresentationEditorScreen();
        break;
      case 3:
        page = const ExerciseBankScreen();
        break;
      case 4:
        page = const CommunityScreen();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: page,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: NavigationBar(
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.search_outlined),
                        label: ('Conceitos'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insert_chart_outlined),
                        label: ('Representações'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.play_circle_outline),
                        label: ('Simulador'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.fitness_center_outlined),
                        label: ('Exercícios'),
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.people_outline),
                        label: ('Comunidade'),
                      ),
                    ],
                    onDestinationSelected: (int index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    selectedIndex: selectedIndex,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    trailing: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          isRailExtended =
                              !isRailExtended; // Alterna o estado de expansão
                        });
                      },
                      child: Icon(
                        isRailExtended ? Icons.arrow_back : Icons.arrow_forward,
                      ),
                    ),
                    extended: isRailExtended, // Controla a extensão do rail
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.search),
                        label: Text('Conceitos'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.insert_chart_outlined),
                        label: Text('Representações:'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.play_circle_outline),
                        label: Text('Simulador'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.fitness_center_outlined),
                        label: Text('Exercícios'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        label: Text('Comunidade'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}
