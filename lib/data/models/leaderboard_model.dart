import 'package:flutter/foundation.dart';

/// Leaderboard entry model
@immutable
class LeaderboardModel {
  final String id;
  final String odId;
  final String displayName;
  final String? photoUrl;
  final int xp;
  final int level;
  final int rank;
  final int streakDays;
  final DateTime updatedAt;

  const LeaderboardModel({
    required this.id,
    required this.odId,
    required this.displayName,
    this.photoUrl,
    required this.xp,
    required this.level,
    required this.rank,
    this.streakDays = 0,
    required this.updatedAt,
  });

  String get userId => odId;

  /// Create from JSON map
  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      id: json['id'] as String,
      odId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      xp: json['xp'] as int,
      level: json['level'] as int,
      rank: json['rank'] as int,
      streakDays: json['streakDays'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': odId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'xp': xp,
      'level': level,
      'rank': rank,
      'streakDays': streakDays,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  LeaderboardModel copyWith({
    String? id,
    String? odId,
    String? displayName,
    String? photoUrl,
    int? xp,
    int? level,
    int? rank,
    int? streakDays,
    DateTime? updatedAt,
  }) {
    return LeaderboardModel(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      streakDays: streakDays ?? this.streakDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get initials from display name
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Get rank medal (1st, 2nd, 3rd)
  String? get medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LeaderboardModel(rank: $rank, displayName: $displayName, xp: $xp)';
  }
}

/// Leaderboard type
enum LeaderboardType {
  daily,
  weekly,
  monthly,
  allTime,
}
