import 'package:flutter/foundation.dart';

/// User entity for domain layer
@immutable
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final int level;
  final int xp;
  final int coins;
  final int streakDays;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
  });

  /// Get user initials
  String get initials {
    if (displayName == null || displayName!.isEmpty) {
      return email.substring(0, 2).toUpperCase();
    }
    final parts = displayName!.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Get level name
  String get levelName {
    if (level <= 5) return 'Iniciante';
    if (level <= 15) return 'Aprendiz';
    if (level <= 30) return 'Intermediário';
    if (level <= 50) return 'Avançado';
    if (level <= 75) return 'Mestre';
    return 'Especialista';
  }

  /// Calculate XP for next level
  int get xpForNextLevel => (level + 1) * 100;

  /// Calculate progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    final xpForCurrentLevel = level * 100;
    final xpInCurrentLevel = xp - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    return (xpInCurrentLevel / xpNeeded).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
