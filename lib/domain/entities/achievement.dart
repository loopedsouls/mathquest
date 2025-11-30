import 'package:flutter/material.dart';

/// Achievement category
enum AchievementCategory {
  progress,
  streak,
  time,
  modules,
  special,
}

/// Achievement entity for domain layer
@immutable
class Achievement {
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
  final bool isUnlocked;
  final int currentProgress;
  final DateTime? unlockedAt;

  const Achievement({
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
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.unlockedAt,
  });

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetValue == null || targetValue == 0) return isUnlocked ? 1.0 : 0.0;
    return (currentProgress / targetValue!).clamp(0.0, 1.0);
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

  /// Get display title (show ??? if secret and not unlocked)
  String get displayTitle => isSecret && !isUnlocked ? '???' : title;

  /// Get display description (show ??? if secret and not unlocked)
  String get displayDescription =>
      isSecret && !isUnlocked ? 'Complete para revelar esta conquista!' : description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Achievement && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
