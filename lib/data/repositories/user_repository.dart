import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../models/leaderboard_model.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Get user by ID
  Future<UserModel?> getUserById(String userId);

  /// Update user
  Future<UserModel> updateUser(UserModel user);

  /// Add XP to user
  Future<UserModel> addXP(String userId, int xp);

  /// Add coins to user
  Future<UserModel> addCoins(String userId, int coins);

  /// Spend coins
  Future<UserModel> spendCoins(String userId, int coins);

  /// Level up user
  Future<UserModel> levelUp(String userId);

  /// Get user achievements
  Future<List<UserAchievement>> getUserAchievements(String userId);

  /// Unlock achievement
  Future<UserAchievement> unlockAchievement(String userId, String achievementId);

  /// Update achievement progress
  Future<UserAchievement> updateAchievementProgress(
    String userId,
    String achievementId,
    int progress,
  );

  /// Get all achievements
  Future<List<AchievementModel>> getAllAchievements();

  /// Get leaderboard
  Future<List<LeaderboardModel>> getLeaderboard({
    LeaderboardType type = LeaderboardType.weekly,
    int limit = 100,
  });

  /// Get user rank
  Future<int> getUserRank(String userId, LeaderboardType type);

  /// Update leaderboard entry
  Future<void> updateLeaderboardEntry(String userId);

  /// Get user settings
  Future<Map<String, dynamic>> getUserSettings(String userId);

  /// Update user settings
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings);
}
