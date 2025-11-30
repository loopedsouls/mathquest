import 'package:flutter/foundation.dart';

/// Lesson entity for domain layer
@immutable
class Lesson {
  final String id;
  final String title;
  final String description;
  final String schoolYear;
  final String thematicUnit;
  final String bnccCode;
  final int order;
  final List<String> prerequisites;
  final List<String> objectives;
  final int estimatedMinutes;
  final String difficulty;
  final bool isLocked;

  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.schoolYear,
    required this.thematicUnit,
    required this.bnccCode,
    required this.order,
    this.prerequisites = const [],
    this.objectives = const [],
    this.estimatedMinutes = 15,
    this.difficulty = 'médio',
    this.isLocked = true,
  });

  /// Get difficulty level (1-3)
  int get difficultyLevel {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return 1;
      case 'médio':
        return 2;
      case 'difícil':
        return 3;
      default:
        return 2;
    }
  }

  /// Get difficulty display name with emoji
  String get difficultyDisplay {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return '⭐ Fácil';
      case 'médio':
        return '⭐⭐ Médio';
      case 'difícil':
        return '⭐⭐⭐ Difícil';
      default:
        return difficulty;
    }
  }

  /// Get formatted estimated time
  String get estimatedTimeDisplay {
    if (estimatedMinutes < 60) {
      return '$estimatedMinutes min';
    }
    final hours = estimatedMinutes ~/ 60;
    final minutes = estimatedMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}min';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
