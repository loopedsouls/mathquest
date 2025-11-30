import 'package:flutter/foundation.dart';

/// Lesson model for learning content
@immutable
class LessonModel {
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
  final int totalQuestions;

  const LessonModel({
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
    this.totalQuestions = 10,
  });

  /// Create from JSON map
  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      schoolYear: json['schoolYear'] as String,
      thematicUnit: json['thematicUnit'] as String,
      bnccCode: json['bnccCode'] as String,
      order: json['order'] as int,
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      objectives: List<String>.from(json['objectives'] ?? []),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 15,
      difficulty: json['difficulty'] as String? ?? 'médio',
      isLocked: json['isLocked'] as bool? ?? true,
      totalQuestions: json['totalQuestions'] as int? ?? 10,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'schoolYear': schoolYear,
      'thematicUnit': thematicUnit,
      'bnccCode': bnccCode,
      'order': order,
      'prerequisites': prerequisites,
      'objectives': objectives,
      'estimatedMinutes': estimatedMinutes,
      'difficulty': difficulty,
      'isLocked': isLocked,
      'totalQuestions': totalQuestions,
    };
  }

  /// Create a copy with updated fields
  LessonModel copyWith({
    String? id,
    String? title,
    String? description,
    String? schoolYear,
    String? thematicUnit,
    String? bnccCode,
    int? order,
    List<String>? prerequisites,
    List<String>? objectives,
    int? estimatedMinutes,
    String? difficulty,
    bool? isLocked,
    int? totalQuestions,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      schoolYear: schoolYear ?? this.schoolYear,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      bnccCode: bnccCode ?? this.bnccCode,
      order: order ?? this.order,
      prerequisites: prerequisites ?? this.prerequisites,
      objectives: objectives ?? this.objectives,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      isLocked: isLocked ?? this.isLocked,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LessonModel(id: $id, title: $title, schoolYear: $schoolYear)';
  }
}
