import 'package:flutter/material.dart';

class ExerciseTile extends StatelessWidget {
  final String title;
  final String description;

  const ExerciseTile({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      leading: const Icon(Icons.fitness_center),
      trailing: const Icon(Icons.arrow_forward),
      onTap: () {
        // Add your logic here
      },
    );
  }
}
