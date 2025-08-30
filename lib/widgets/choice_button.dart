// ChoiceButton widget stub
import 'package:flutter/material.dart';

class ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const ChoiceButton({
    required this.label,
    this.onPressed,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
