import 'package:flutter/material.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/user_repository.dart';

/// Game state provider for gameplay
class GameProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;
  final UserRepository _userRepository;

  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  int _xpEarned = 0;
  int _coinsEarned = 0;
  bool _isLoading = false;
  String? _currentLessonId;

  GameProvider(this._progressRepository, this._userRepository);

  int get currentQuestionIndex => _currentQuestionIndex;
  int get correctAnswers => _correctAnswers;
  int get totalQuestions => _totalQuestions;
  int get xpEarned => _xpEarned;
  int get coinsEarned => _coinsEarned;
  bool get isLoading => _isLoading;
  double get progress => _totalQuestions > 0
      ? _currentQuestionIndex / _totalQuestions
      : 0.0;

  void startLesson(String lessonId, int questionCount) {
    _currentLessonId = lessonId;
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _totalQuestions = questionCount;
    _xpEarned = 0;
    _coinsEarned = 0;
    notifyListeners();
  }

  void answerQuestion(bool isCorrect) {
    if (isCorrect) {
      _correctAnswers++;
      _xpEarned += 10;
      _coinsEarned += 2;
    }
    _currentQuestionIndex++;
    notifyListeners();
  }

  Future<void> completeLesson(String odId) async {
    if (_currentLessonId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Save progress
      await _progressRepository.completeLesson(
        odId: odId,
        lessonId: _currentLessonId!,
        xpEarned: _xpEarned,
      );

      // Update user XP and coins
      await _userRepository.addXP(odId, _xpEarned);
      await _userRepository.addCoins(odId, _coinsEarned);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _totalQuestions = 0;
    _xpEarned = 0;
    _coinsEarned = 0;
    _currentLessonId = null;
    notifyListeners();
  }
}
