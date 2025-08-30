// DialogueBox widget stub
import 'package:flutter/material.dart';
import 'typewriter_text.dart';
import 'choice_button.dart';

class DialogueBox extends StatelessWidget {
  final String text;
  final List<String> choices;
  final void Function(String)? onChoice;
  final TextStyle? style;

  const DialogueBox({
    required this.text,
    this.choices = const [],
    this.onChoice,
    this.style,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TypewriterText(text: text, style: style),
        if (choices.isNotEmpty)
          Wrap(
            children: choices
                .map((c) => ChoiceButton(
                      label: c,
                      onPressed: () => onChoice?.call(c),
                    ))
                .toList(),
          ),
      ],
    );
  }
}
