import 'package:flutter/material.dart';
import 'graph_editor.dart';
import 'algebra_editor.dart';

class RepresentationEditorScreen extends StatefulWidget {
  const RepresentationEditorScreen({super.key});

  @override
  RepresentationEditorScreenState createState() =>
      RepresentationEditorScreenState();
}

class RepresentationEditorScreenState
    extends State<RepresentationEditorScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const GraphEditor(),
    const AlgebraEditor(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomSheet: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.show_chart), label: 'Gráfico'),
          BottomNavigationBarItem(
              icon: Icon(Icons.functions), label: 'Algébrico'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
