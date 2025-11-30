import 'package:flutter/foundation.dart';

/// User model for authentication and profile
@immutable
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int level;
  final int xp;
  final int coins;
  final int streakDays;
  final String? currentSchoolYear;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.streakDays = 0,
    this.currentSchoolYear,
  });

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      coins: json['coins'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      currentSchoolYear: json['currentSchoolYear'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'level': level,
      'xp': xp,
      'coins': coins,
      'streakDays': streakDays,
      'currentSchoolYear': currentSchoolYear,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? level,
    int? xp,
    int? coins,
    int? streakDays,
    String? currentSchoolYear,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      currentSchoolYear: currentSchoolYear ?? this.currentSchoolYear,
    );
  }

  /// Calculate progress to next level
  double get progressToNextLevel {
    final xpForCurrentLevel = level * 100;
    final xpForNextLevel = (level + 1) * 100;
    final xpInCurrentLevel = xp - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    return (xpInCurrentLevel / xpNeeded).clamp(0.0, 1.0);
  }

  /// Get XP needed for next level
  int get xpForNextLevel => (level + 1) * 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, level: $level, xp: $xp)';
  }
}
