import '../../../data/repositories/progress_repository.dart';
import '../../../data/models/progress_model.dart';
import '../../../core/errors/failures.dart';

/// Use case for updating user progress
class UpdateProgressUseCase {
  final ProgressRepository _progressRepository;

  UpdateProgressUseCase(this._progressRepository);

  /// Record an answer
  Future<UpdateProgressResult> recordAnswer({
    required String userId,
    required String lessonId,
    required String questionId,
    required bool isCorrect,
    required int timeSpentSeconds,
  }) async {
    try {
      final progress = await _progressRepository.recordAnswer(
        odId: userId,
        lessonId: lessonId,
        questionId: questionId,
        isCorrect: isCorrect,
        timeSpentSeconds: timeSpentSeconds,
      );
      return UpdateProgressResult.success(progress);
    } catch (e) {
      return UpdateProgressResult.failure(
        DatabaseFailure(message: 'Erro ao salvar progresso: $e'),
      );
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      return await _progressRepository.getUserStatistics(userId);
    } catch (e) {
      return {};
    }
  }

  /// Get progress by thematic unit
  Future<Map<String, double>> getProgressByUnit(String userId) async {
    try {
      return await _progressRepository.getProgressByThematicUnit(userId);
    } catch (e) {
      return {};
    }
  }

  /// Get progress by school year
  Future<Map<String, double>> getProgressByYear(String userId) async {
    try {
      return await _progressRepository.getProgressBySchoolYear(userId);
    } catch (e) {
      return {};
    }
  }
}

/// Result class for update progress operation
class UpdateProgressResult {
  final ProgressModel? progress;
  final Failure? failure;

  UpdateProgressResult._({this.progress, this.failure});

  factory UpdateProgressResult.success(ProgressModel progress) =>
      UpdateProgressResult._(progress: progress);
  factory UpdateProgressResult.failure(Failure failure) =>
      UpdateProgressResult._(failure: failure);

  bool get isSuccess => progress != null;
  bool get isFailure => failure != null;
}
