import 'package:flutter/material.dart';
import '../../data/repositories/progress_repository.dart';

/// Progress state provider
class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;

  Map<String, double> _progressByUnit = {};
  Map<String, double> _progressByYear = {};
  int _currentStreak = 0;
  int _longestStreak = 0;
  bool _isActiveToday = false;
  bool _isLoading = false;

  ProgressProvider(this._progressRepository);

  Map<String, double> get progressByUnit => _progressByUnit;
  Map<String, double> get progressByYear => _progressByYear;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  bool get isActiveToday => _isActiveToday;
  bool get isLoading => _isLoading;

  Future<void> loadProgress(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load progress by unit
      _progressByUnit = await _progressRepository.getProgressByThematicUnit(userId);

      // Load progress by year
      _progressByYear = await _progressRepository.getProgressBySchoolYear(userId);

      // Load streak data
      final streakData = await _progressRepository.getStreakData(userId);
      _currentStreak = streakData['currentStreak'] as int? ?? 0;
      _longestStreak = streakData['longestStreak'] as int? ?? 0;
      _isActiveToday = streakData['isActiveToday'] as bool? ?? false;
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStreak(String userId) async {
    try {
      final newStreak = await _progressRepository.updateStreak(userId);
      _currentStreak = newStreak;
      _isActiveToday = true;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  double getOverallProgress() {
    if (_progressByUnit.isEmpty) return 0.0;
    final total = _progressByUnit.values.reduce((a, b) => a + b);
    return total / _progressByUnit.length;
  }
}
