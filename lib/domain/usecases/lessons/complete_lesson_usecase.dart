import '../../../data/repositories/progress_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/models/progress_model.dart';
import '../../../core/errors/failures.dart';
import '../../../core/constants/app_constants.dart';

/// Use case for completing a lesson
class CompleteLessonUseCase {
  final ProgressRepository _progressRepository;
  final UserRepository _userRepository;
  final LessonRepository _lessonRepository;

  CompleteLessonUseCase(
    this._progressRepository,
    this._userRepository,
    this._lessonRepository,
  );

  /// Complete a lesson and award XP/achievements
  Future<CompleteLessonResult> call({
    required String userId,
    required String lessonId,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpentSeconds,
  }) async {
    try {
      // Calculate score and XP
      final scorePercentage = totalQuestions > 0
          ? (correctAnswers / totalQuestions * 100).round()
          : 0;
      
      // Calculate XP based on performance
      int xpEarned = correctAnswers * AppConstants.xpPerCorrectAnswer;
      
      // Bonus for completion
      if (scorePercentage >= 60) {
        xpEarned += AppConstants.xpPerQuizCompletion;
      }
      
      // Bonus for perfect score
      if (scorePercentage == 100) {
        xpEarned += 50; // Perfect bonus
      }

      // Save progress
      final progress = await _progressRepository.completeLesson(
        odId: userId,
        lessonId: lessonId,
        xpEarned: xpEarned,
      );

      // Add XP to user
      final updatedUser = await _userRepository.addXP(userId, xpEarned);

      // Check for level up
      final didLevelUp = updatedUser.level > (updatedUser.xp - xpEarned) ~/ 100;

      // Add coins
      final coinsEarned = correctAnswers * AppConstants.coinsPerCorrectAnswer;
      await _userRepository.addCoins(userId, coinsEarned);

      // Unlock next lesson(s) if passed
      if (scorePercentage >= 60) {
        final lesson = await _lessonRepository.getLessonById(lessonId);
        if (lesson != null) {
          // Find and unlock next lessons that depend on this one
          final allLessons = await _lessonRepository.getAllLessons();
          for (final nextLesson in allLessons) {
            if (nextLesson.prerequisites.contains(lessonId)) {
              // Check if all prerequisites are completed
              final completedLessons = await _progressRepository.getCompletedLessons(userId);
              final allPrerequisitesMet = nextLesson.prerequisites
                  .every((prereq) => completedLessons.contains(prereq));
              
              if (allPrerequisitesMet) {
                await _lessonRepository.unlockLesson(userId, nextLesson.id);
              }
            }
          }
        }
      }

      return CompleteLessonResult.success(
        progress: progress,
        xpEarned: xpEarned,
        coinsEarned: coinsEarned,
        didLevelUp: didLevelUp,
        isPassed: scorePercentage >= 60,
        scorePercentage: scorePercentage,
      );
    } catch (e) {
      return CompleteLessonResult.failure(
        DatabaseFailure(message: 'Erro ao completar lição: $e'),
      );
    }
  }
}

/// Result class for complete lesson operation
class CompleteLessonResult {
  final ProgressModel? progress;
  final int xpEarned;
  final int coinsEarned;
  final bool didLevelUp;
  final bool isPassed;
  final int scorePercentage;
  final Failure? failure;

  CompleteLessonResult._({
    this.progress,
    this.xpEarned = 0,
    this.coinsEarned = 0,
    this.didLevelUp = false,
    this.isPassed = false,
    this.scorePercentage = 0,
    this.failure,
  });

  factory CompleteLessonResult.success({
    required ProgressModel progress,
    required int xpEarned,
    required int coinsEarned,
    required bool didLevelUp,
    required bool isPassed,
    required int scorePercentage,
  }) =>
      CompleteLessonResult._(
        progress: progress,
        xpEarned: xpEarned,
        coinsEarned: coinsEarned,
        didLevelUp: didLevelUp,
        isPassed: isPassed,
        scorePercentage: scorePercentage,
      );

  factory CompleteLessonResult.failure(Failure failure) =>
      CompleteLessonResult._(failure: failure);

  bool get isSuccess => progress != null;
  bool get isFailure => failure != null;

  /// Get grade based on score
  String get grade {
    if (scorePercentage >= 90) return 'A';
    if (scorePercentage >= 80) return 'B';
    if (scorePercentage >= 70) return 'C';
    if (scorePercentage >= 60) return 'D';
    return 'F';
  }
}
