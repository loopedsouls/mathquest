import 'package:flutter/material.dart';

class ConceptCard extends StatelessWidget {
  final String title;
  final String description;

  const ConceptCard({
    super.key,
    required this.title,
    required this.description,
    required String conceptName,
    required List<String> representations,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
