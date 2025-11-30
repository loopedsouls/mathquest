import 'package:flutter/foundation.dart';

/// Question type
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  matching,
}

/// Question entity for domain layer
@immutable
class Question {
  final String id;
  final String lessonId;
  final String question;
  final QuestionType type;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String difficulty;
  final String thematicUnit;
  final String schoolYear;

  const Question({
    required this.id,
    required this.lessonId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty = 'médio',
    required this.thematicUnit,
    required this.schoolYear,
  });

  /// Check if answer is correct
  bool isCorrect(String answer) {
    return answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
  }

  /// Get question type display name
  String get typeDisplayName {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Múltipla Escolha';
      case QuestionType.trueFalse:
        return 'Verdadeiro ou Falso';
      case QuestionType.fillBlank:
        return 'Completar';
      case QuestionType.matching:
        return 'Associação';
    }
  }

  /// Get type icon name
  String get typeIcon {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'check_box';
      case QuestionType.trueFalse:
        return 'toggle_on';
      case QuestionType.fillBlank:
        return 'edit';
      case QuestionType.matching:
        return 'compare_arrows';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
