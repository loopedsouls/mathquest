import 'package:flutter/material.dart';

/// Achievement category
enum AchievementCategory {
  progress,
  streak,
  time,
  modules,
  special,
}

/// Achievement model for gamification
@immutable
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final String condition;
  final int? targetValue;
  final int xpReward;
  final int coinsReward;
  final bool isSecret;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.condition,
    this.targetValue,
    this.xpReward = 50,
    this.coinsReward = 25,
    this.isSecret = false,
  });

  /// Create from JSON map
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: IconData(json['iconCode'] as int, fontFamily: 'MaterialIcons'),
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.progress,
      ),
      condition: json['condition'] as String,
      targetValue: json['targetValue'] as int?,
      xpReward: json['xpReward'] as int? ?? 50,
      coinsReward: json['coinsReward'] as int? ?? 25,
      isSecret: json['isSecret'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconCode': icon.codePoint,
      'category': category.name,
      'condition': condition,
      'targetValue': targetValue,
      'xpReward': xpReward,
      'coinsReward': coinsReward,
      'isSecret': isSecret,
    };
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case AchievementCategory.progress:
        return 'Progresso';
      case AchievementCategory.streak:
        return 'Sequência';
      case AchievementCategory.time:
        return 'Tempo';
      case AchievementCategory.modules:
        return 'Módulos';
      case AchievementCategory.special:
        return 'Especial';
    }
  }

  /// Get category color
  Color get categoryColor {
    switch (category) {
      case AchievementCategory.progress:
        return Colors.blue;
      case AchievementCategory.streak:
        return Colors.orange;
      case AchievementCategory.time:
        return Colors.purple;
      case AchievementCategory.modules:
        return Colors.green;
      case AchievementCategory.special:
        return Colors.amber;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AchievementModel(id: $id, title: $title, category: $category)';
  }
}

/// User achievement progress
@immutable
class UserAchievement {
  final String odId;
  final String odAchievementId;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const UserAchievement({
    required this.odId,
    required this.odAchievementId,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  String get userId => odId;
  String get achievementId => odAchievementId;

  /// Create from JSON map
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      odId: json['userId'] as String,
      odAchievementId: json['achievementId'] as String,
      currentValue: json['currentValue'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': odId,
      'achievementId': odAchievementId,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  UserAchievement copyWith({
    String? odId,
    String? odAchievementId,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return UserAchievement(
      odId: odId ?? this.odId,
      odAchievementId: odAchievementId ?? this.odAchievementId,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
