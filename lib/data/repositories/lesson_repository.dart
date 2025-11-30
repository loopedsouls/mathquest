import '../models/lesson_model.dart';
import '../models/question_model.dart';

/// Repository interface for lesson operations
abstract class LessonRepository {
  /// Get all lessons
  Future<List<LessonModel>> getAllLessons();

  /// Get lessons by school year
  Future<List<LessonModel>> getLessonsBySchoolYear(String schoolYear);

  /// Get lessons by thematic unit
  Future<List<LessonModel>> getLessonsByThematicUnit(String thematicUnit);

  /// Get lesson by ID
  Future<LessonModel?> getLessonById(String lessonId);

  /// Get next available lessons for user
  Future<List<LessonModel>> getNextLessonsForUser(String userId);

  /// Get lesson questions
  Future<List<QuestionModel>> getLessonQuestions(String lessonId);

  /// Generate AI question for lesson
  Future<QuestionModel?> generateAIQuestion({
    required String lessonId,
    required String thematicUnit,
    required String schoolYear,
    required String difficulty,
  });

  /// Get cached questions
  Future<List<QuestionModel>> getCachedQuestions({
    required String thematicUnit,
    required String schoolYear,
    int limit = 10,
  });

  /// Cache question
  Future<void> cacheQuestion(QuestionModel question);

  /// Check if lesson is unlocked for user
  Future<bool> isLessonUnlocked(String userId, String lessonId);

  /// Unlock lesson for user
  Future<void> unlockLesson(String userId, String lessonId);
}
