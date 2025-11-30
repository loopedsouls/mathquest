import '../../../data/repositories/lesson_repository.dart';
import '../../../data/models/lesson_model.dart';
import '../../../core/errors/failures.dart';

/// Use case for getting lessons
class GetLessonsUseCase {
  final LessonRepository _lessonRepository;

  GetLessonsUseCase(this._lessonRepository);

  /// Get all lessons
  Future<GetLessonsResult> call() async {
    try {
      final lessons = await _lessonRepository.getAllLessons();
      return GetLessonsResult.success(lessons);
    } catch (e) {
      return GetLessonsResult.failure(
        const DatabaseFailure(message: 'Erro ao carregar lições'),
      );
    }
  }

  /// Get lessons by school year
  Future<GetLessonsResult> bySchoolYear(String schoolYear) async {
    try {
      final lessons = await _lessonRepository.getLessonsBySchoolYear(schoolYear);
      return GetLessonsResult.success(lessons);
    } catch (e) {
      return GetLessonsResult.failure(
        const DatabaseFailure(message: 'Erro ao carregar lições'),
      );
    }
  }

  /// Get lessons by thematic unit
  Future<GetLessonsResult> byThematicUnit(String thematicUnit) async {
    try {
      final lessons = await _lessonRepository.getLessonsByThematicUnit(thematicUnit);
      return GetLessonsResult.success(lessons);
    } catch (e) {
      return GetLessonsResult.failure(
        const DatabaseFailure(message: 'Erro ao carregar lições'),
      );
    }
  }

  /// Get next available lessons for user
  Future<GetLessonsResult> nextForUser(String userId) async {
    try {
      final lessons = await _lessonRepository.getNextLessonsForUser(userId);
      return GetLessonsResult.success(lessons);
    } catch (e) {
      return GetLessonsResult.failure(
        const DatabaseFailure(message: 'Erro ao carregar próximas lições'),
      );
    }
  }
}

/// Result class for get lessons operation
class GetLessonsResult {
  final List<LessonModel>? lessons;
  final Failure? failure;

  GetLessonsResult._({this.lessons, this.failure});

  factory GetLessonsResult.success(List<LessonModel> lessons) =>
      GetLessonsResult._(lessons: lessons);
  factory GetLessonsResult.failure(Failure failure) =>
      GetLessonsResult._(failure: failure);

  bool get isSuccess => lessons != null;
  bool get isFailure => failure != null;
}
