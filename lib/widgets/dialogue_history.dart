import 'package:flutter/material.dart';

class DialogueHistory extends StatelessWidget {
  final List<String> history;
  const DialogueHistory({required this.history, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(history[index]),
      ),
    );
  }
}
