import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/app_constants.dart';

/// Use case for getting and managing streaks
class GetStreakUseCase {
  final ProgressRepository _progressRepository;
  final UserRepository _userRepository;

  GetStreakUseCase(this._progressRepository, this._userRepository);

  /// Get current streak data
  Future<StreakResult> call(String userId) async {
    try {
      final streakData = await _progressRepository.getStreakData(userId);
      return StreakResult.success(
        currentStreak: streakData['currentStreak'] as int? ?? 0,
        longestStreak: streakData['longestStreak'] as int? ?? 0,
        lastActivityDate: streakData['lastActivityDate'] != null
            ? DateTime.parse(streakData['lastActivityDate'] as String)
            : null,
        isActiveToday: streakData['isActiveToday'] as bool? ?? false,
      );
    } catch (e) {
      return StreakResult.failure(
        DatabaseFailure(message: 'Erro ao carregar sequência: $e'),
      );
    }
  }

  /// Update streak (call when user completes an activity)
  Future<StreakResult> updateStreak(String userId) async {
    try {
      final newStreak = await _progressRepository.updateStreak(userId);
      
      // Award coins for streak milestones
      if (newStreak > 0 && newStreak % 7 == 0) {
        // Weekly milestone - bonus coins
        await _userRepository.addCoins(userId, AppConstants.coinsPerDailyStreak * 2);
      } else if (newStreak > 0) {
        // Daily streak reward
        await _userRepository.addCoins(userId, AppConstants.coinsPerDailyStreak);
      }

      // Check for streak achievements
      await _checkStreakAchievements(userId, newStreak);

      return call(userId);
    } catch (e) {
      return StreakResult.failure(
        DatabaseFailure(message: 'Erro ao atualizar sequência: $e'),
      );
    }
  }

  Future<void> _checkStreakAchievements(String userId, int streak) async {
    final milestones = [3, 7, 14, 30, 60, 100, 365];
    for (final milestone in milestones) {
      if (streak >= milestone) {
        final achievementId = 'streak_$milestone';
        try {
          await _userRepository.unlockAchievement(userId, achievementId);
        } catch (_) {
          // Achievement might already be unlocked
        }
      }
    }
  }
}

/// Result class for streak operation
class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final bool isActiveToday;
  final Failure? failure;

  StreakResult._({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.isActiveToday = false,
    this.failure,
  });

  factory StreakResult.success({
    required int currentStreak,
    required int longestStreak,
    DateTime? lastActivityDate,
    required bool isActiveToday,
  }) =>
      StreakResult._(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastActivityDate: lastActivityDate,
        isActiveToday: isActiveToday,
      );

  factory StreakResult.failure(Failure failure) =>
      StreakResult._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  /// Check if streak is at risk (not active today, but was active yesterday)
  bool get isAtRisk {
    if (lastActivityDate == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return !isActiveToday &&
        lastActivityDate!.year == yesterday.year &&
        lastActivityDate!.month == yesterday.month &&
        lastActivityDate!.day == yesterday.day;
  }

  /// Get motivational message based on streak
  String get motivationalMessage {
    if (currentStreak == 0) return 'Comece sua sequência hoje!';
    if (currentStreak < 7) return 'Continue assim! $currentStreak dias seguidos!';
    if (currentStreak < 30) return 'Incrível! Você está em uma sequência de $currentStreak dias!';
    if (currentStreak < 100) return 'Fantástico! $currentStreak dias de dedicação!';
    return 'Você é uma lenda! $currentStreak dias de aprendizado contínuo!';
  }
}
