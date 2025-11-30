import 'package:flutter/foundation.dart';

/// Progress model for tracking user progress
@immutable
class ProgressModel {
  final String id;
  final String odId;
  final String lessonId;
  final int correctAnswers;
  final int totalAnswers;
  final int xpEarned;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int timeSpentSeconds;
  final bool isCompleted;
  final Map<String, bool> questionResults;

  const ProgressModel({
    required this.id,
    required this.odId,
    required this.lessonId,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.xpEarned = 0,
    required this.startedAt,
    this.completedAt,
    this.timeSpentSeconds = 0,
    this.isCompleted = false,
    this.questionResults = const {},
  });

  String get userId => odId;

  /// Create from JSON map
  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'] as String,
      odId: json['userId'] as String,
      lessonId: json['lessonId'] as String,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      questionResults: Map<String, bool>.from(json['questionResults'] ?? {}),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': odId,
      'lessonId': lessonId,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
      'xpEarned': xpEarned,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpentSeconds': timeSpentSeconds,
      'isCompleted': isCompleted,
      'questionResults': questionResults,
    };
  }

  /// Create a copy with updated fields
  ProgressModel copyWith({
    String? id,
    String? odId,
    String? lessonId,
    int? correctAnswers,
    int? totalAnswers,
    int? xpEarned,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeSpentSeconds,
    bool? isCompleted,
    Map<String, bool>? questionResults,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      lessonId: lessonId ?? this.lessonId,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      xpEarned: xpEarned ?? this.xpEarned,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      questionResults: questionResults ?? this.questionResults,
    );
  }

  /// Calculate score percentage
  double get scorePercentage {
    if (totalAnswers == 0) return 0.0;
    return (correctAnswers / totalAnswers) * 100;
  }

  /// Get grade based on score
  String get grade {
    final score = scorePercentage;
    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  /// Check if passed (>= 60%)
  bool get isPassed => scorePercentage >= 60;

  /// Get formatted time spent
  String get formattedTimeSpent {
    final minutes = timeSpentSeconds ~/ 60;
    final seconds = timeSpentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProgressModel(id: $id, lessonId: $lessonId, score: $scorePercentage%)';
  }
}
