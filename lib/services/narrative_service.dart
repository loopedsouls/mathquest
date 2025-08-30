import '../models/dialogue_node.dart';
import '../models/game_state.dart';

class NarrativeService {
  final GameState gameState;

  NarrativeService(this.gameState);

  /// Avança para o próximo nó de diálogo, considerando escolhas do jogador.
  void nextNode({String? choiceLabel}) {
    final current = gameState.currentNode;
    if (current == null) return;

    if (choiceLabel != null && current.choices.isNotEmpty) {
      final choice = current.choices.firstWhere(
        (c) => c.label == choiceLabel,
        orElse: () => current.choices.first,
      );
      gameState.setCurrentNode(choice.nextNode);
      gameState.makeChoice(current.text, choiceLabel);
      gameState.addToHistory(choice.nextNode);
    } else if (current.next != null) {
      gameState.setCurrentNode(current.next!);
      gameState.addToHistory(current.next!);
    }
  }

  /// Reinicia a narrativa para o início.
  void restart(DialogueNode startNode) {
    gameState.history = [];
    gameState.choices = {};
    gameState.setCurrentNode(startNode);
    gameState.addToHistory(startNode);
    gameState.progress = 0;
  }
}
