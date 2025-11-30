import 'package:flutter/foundation.dart';

/// Question types enum
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  matching,
}

/// Question model for quiz questions
@immutable
class QuestionModel {
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
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const QuestionModel({
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
    this.imageUrl,
    this.metadata,
  });

  /// Create from JSON map
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      question: json['question'] as String,
      type: _parseQuestionType(json['type'] as String),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String? ?? 'médio',
      thematicUnit: json['thematicUnit'] as String,
      schoolYear: json['schoolYear'] as String,
      imageUrl: json['imageUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'question': question,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'thematicUnit': thematicUnit,
      'schoolYear': schoolYear,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  QuestionModel copyWith({
    String? id,
    String? lessonId,
    String? question,
    QuestionType? type,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    String? thematicUnit,
    String? schoolYear,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      schoolYear: schoolYear ?? this.schoolYear,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

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

  static QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'multiplechoice':
      case 'multipla_escolha':
        return QuestionType.multipleChoice;
      case 'truefalse':
      case 'verdadeiro_falso':
        return QuestionType.trueFalse;
      case 'fillblank':
      case 'completar':
      case 'completar_frase':
        return QuestionType.fillBlank;
      case 'matching':
      case 'associacao':
        return QuestionType.matching;
      default:
        return QuestionType.multipleChoice;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuestionModel(id: $id, type: $type, difficulty: $difficulty)';
  }
}
