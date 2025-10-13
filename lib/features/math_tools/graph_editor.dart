import 'package:flutter/material.dart';

class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key});

  @override
  GraphEditorState createState() => GraphEditorState();
}

class GraphEditorState extends State<GraphEditor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Editor'),
      ),
      body: Container(
          // Add your graph editor UI components here
          ),
    );
  }
}

void main() {
  runApp(const GraphEditor());
}
