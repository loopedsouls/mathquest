import 'package:flutter/foundation.dart';
import '../../main.dart';

/// Helper for tracking analytics events
class AnalyticsHelper {
  AnalyticsHelper._();

  static final AnalyticsHelper _instance = AnalyticsHelper._();
  static AnalyticsHelper get instance => _instance;

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    if (!firebaseAvailable) return;

    try {
      // FirebaseAnalytics.instance.logScreenView(screenName: screenName);
      if (kDebugMode) {
        print('📊 Screen view: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging screen view: $e');
      }
    }
  }

  /// Log quiz started
  Future<void> logQuizStarted({
    required String quizType,
    required String topic,
    required String difficulty,
    required String schoolYear,
  }) async {
    await _logEvent('quiz_started', {
      'quiz_type': quizType,
      'topic': topic,
      'difficulty': difficulty,
      'school_year': schoolYear,
    });
  }

  /// Log quiz completed
  Future<void> logQuizCompleted({
    required String quizType,
    required String topic,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpentSeconds,
  }) async {
    await _logEvent('quiz_completed', {
      'quiz_type': quizType,
      'topic': topic,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'score_percentage': (correctAnswers / totalQuestions * 100).round(),
      'time_spent_seconds': timeSpentSeconds,
    });
  }

  /// Log question answered
  Future<void> logQuestionAnswered({
    required bool isCorrect,
    required String questionType,
    required String topic,
    required int timeSpentSeconds,
  }) async {
    await _logEvent('question_answered', {
      'is_correct': isCorrect,
      'question_type': questionType,
      'topic': topic,
      'time_spent_seconds': timeSpentSeconds,
    });
  }

  /// Log module started
  Future<void> logModuleStarted({
    required String moduleId,
    required String moduleName,
    required String schoolYear,
  }) async {
    await _logEvent('module_started', {
      'module_id': moduleId,
      'module_name': moduleName,
      'school_year': schoolYear,
    });
  }

  /// Log module completed
  Future<void> logModuleCompleted({
    required String moduleId,
    required String moduleName,
    required int xpEarned,
  }) async {
    await _logEvent('module_completed', {
      'module_id': moduleId,
      'module_name': moduleName,
      'xp_earned': xpEarned,
    });
  }

  /// Log achievement unlocked
  Future<void> logAchievementUnlocked({
    required String achievementId,
    required String achievementName,
  }) async {
    await _logEvent('achievement_unlocked', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
    });
  }

  /// Log level up
  Future<void> logLevelUp({
    required int newLevel,
    required int totalXp,
  }) async {
    await _logEvent('level_up', {
      'new_level': newLevel,
      'total_xp': totalXp,
    });
  }

  /// Log streak milestone
  Future<void> logStreakMilestone({
    required int streakDays,
  }) async {
    await _logEvent('streak_milestone', {
      'streak_days': streakDays,
    });
  }

  /// Log AI service used
  Future<void> logAIServiceUsed({
    required String serviceType,
    required String action,
    required bool success,
  }) async {
    await _logEvent('ai_service_used', {
      'service_type': serviceType,
      'action': action,
      'success': success,
    });
  }

  /// Log purchase
  Future<void> logPurchase({
    required String itemId,
    required String itemName,
    required int price,
  }) async {
    await _logEvent('purchase', {
      'item_id': itemId,
      'item_name': itemName,
      'price': price,
    });
  }

  /// Log error
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _logEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      if (stackTrace != null) 'stack_trace': stackTrace.substring(0, 500.clamp(0, stackTrace.length)),
    });
  }

  /// Log user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!firebaseAvailable) return;

    try {
      // FirebaseAnalytics.instance.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('📊 User property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user property: $e');
      }
    }
  }

  /// Log user ID
  Future<void> setUserId(String? userId) async {
    if (!firebaseAvailable) return;

    try {
      // FirebaseAnalytics.instance.setUserId(id: userId);
      if (kDebugMode) {
        print('📊 User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  Future<void> _logEvent(String name, Map<String, dynamic> parameters) async {
    if (!firebaseAvailable) return;

    try {
      // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
      if (kDebugMode) {
        print('📊 Event: $name - $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging event: $e');
      }
    }
  }
}
