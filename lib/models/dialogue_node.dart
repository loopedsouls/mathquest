import 'character.dart';

class DialogueNode {
  final String text;
  final Character? character;
  final List<DialogueChoice> choices;
  final DialogueNode? next;

  DialogueNode({
    required this.text,
    this.character,
    this.choices = const [],
    this.next,
  });
}

class DialogueChoice {
  final String label;
  final DialogueNode nextNode;

  DialogueChoice({
    required this.label,
    required this.nextNode,
  });
}
