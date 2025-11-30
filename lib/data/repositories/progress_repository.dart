import '../models/progress_model.dart';

/// Repository interface for progress operations
abstract class ProgressRepository {
  /// Get user progress for a lesson
  Future<ProgressModel?> getLessonProgress(String userId, String lessonId);

  /// Get all progress for user
  Future<List<ProgressModel>> getUserProgress(String userId);

  /// Get completed lessons for user
  Future<List<String>> getCompletedLessons(String userId);

  /// Save progress
  Future<void> saveProgress(ProgressModel progress);

  /// Update progress with answer
  Future<ProgressModel> recordAnswer({
    required String odId,
    required String lessonId,
    required String questionId,
    required bool isCorrect,
    required int timeSpentSeconds,
  });

  /// Complete lesson
  Future<ProgressModel> completeLesson({
    required String odId,
    required String lessonId,
    required int xpEarned,
  });

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String userId);

  /// Get streak data
  Future<Map<String, dynamic>> getStreakData(String userId);

  /// Update streak
  Future<int> updateStreak(String userId);

  /// Get progress by thematic unit
  Future<Map<String, double>> getProgressByThematicUnit(String userId);

  /// Get progress by school year
  Future<Map<String, double>> getProgressBySchoolYear(String userId);

  /// Delete all user progress (for testing)
  Future<void> deleteUserProgress(String userId);
}
