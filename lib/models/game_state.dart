import 'character.dart';
import 'dialogue_node.dart';

class GameState {
  List<DialogueNode> history;
  Map<String, dynamic> choices;
  DialogueNode? currentNode;
  List<Character> characters;
  int progress;

  GameState({
    this.history = const [],
    this.choices = const {},
    this.currentNode,
    this.characters = const [],
    this.progress = 0,
  });

  void addToHistory(DialogueNode node) {
    history = List.from(history)..add(node);
  }

  void makeChoice(String key, dynamic value) {
    choices = Map.from(choices)..[key] = value;
  }

  void setCurrentNode(DialogueNode node) {
    currentNode = node;
  }

  void updateProgress(int value) {
    progress = value;
  }
}
