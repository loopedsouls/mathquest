import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../data/repositories/lesson_repository_impl.dart';
import '../../widgets/flame/results_game.dart';
import '../../widgets/results/result_stats.dart';
import '../../widgets/results/star_rating.dart';
import '../../widgets/results/xp_animation.dart';

/// Results screen - Shows quiz/lesson completion results
class ResultsScreen extends StatefulWidget {
  final String lessonId;
  final int score;
  final int totalQuestions;
  final int xpGained;

  const ResultsScreen({
    super.key,
    required this.lessonId,
    required this.score,
    required this.totalQuestions,
    required this.xpGained,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final LessonRepositoryImpl _lessonRepository = LessonRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _saveProgress();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Save completed lesson
    final completedLessons = prefs.getStringList('completed_lessons') ?? [];
    if (!completedLessons.contains(widget.lessonId)) {
      completedLessons.add(widget.lessonId);
      await prefs.setStringList('completed_lessons', completedLessons);
    }

    // Save stars
    final starsJson = prefs.getString('lesson_stars') ?? '{}';
    final starsMap = _parseStarsMap(starsJson);
    final currentStars = starsMap[widget.lessonId] ?? 0;
    if (_stars > currentStars) {
      starsMap[widget.lessonId] = _stars;
      await prefs.setString('lesson_stars', _encodeStarsMap(starsMap));
    }

    // Unlock next lessons
    await _unlockNextLessons();

    // Update XP
    final currentXp = prefs.getInt('user_xp') ?? 0;
    await prefs.setInt('user_xp', currentXp + widget.xpGained);
  }

  Future<void> _unlockNextLessons() async {
    final allLessons = await _lessonRepository.getAllLessons();
    final currentLesson = allLessons.firstWhere(
      (l) => l.id == widget.lessonId,
      orElse: () => allLessons.first,
    );

    // Find lessons that have this lesson as prerequisite
    final lessonsToUnlock = allLessons.where((lesson) {
      if (lesson.prerequisites == null) return false;
      return lesson.prerequisites!.contains(widget.lessonId);
    }).toList();

    // Also unlock next lesson in the same unit by order
    final sameCategoryLessons = allLessons
        .where((l) =>
            l.thematicUnit == currentLesson.thematicUnit &&
            l.schoolYear == currentLesson.schoolYear)
        .toList();
    sameCategoryLessons.sort((a, b) => a.order.compareTo(b.order));

    final currentIndex =
        sameCategoryLessons.indexWhere((l) => l.id == widget.lessonId);
    if (currentIndex >= 0 && currentIndex < sameCategoryLessons.length - 1) {
      lessonsToUnlock.add(sameCategoryLessons[currentIndex + 1]);
    }

    // Unlock all found lessons
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('unlocked_lessons') ??
        ['numeros_6_1', 'algebra_6_1', 'numeros_7_1'];

    for (final lesson in lessonsToUnlock) {
      if (!unlockedIds.contains(lesson.id)) {
        unlockedIds.add(lesson.id);
      }
    }

    await prefs.setStringList('unlocked_lessons', unlockedIds);
  }

  Map<String, int> _parseStarsMap(String json) {
    try {
      final trimmed = json.trim();
      if (trimmed.isEmpty || trimmed == '{}') return {};
      final content = trimmed.substring(1, trimmed.length - 1);
      if (content.isEmpty) return {};
      final result = <String, int>{};
      final pairs = content.split(',');
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final key = parts[0].trim().replaceAll('"', '');
          final value = int.tryParse(parts[1].trim()) ?? 0;
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  String _encodeStarsMap(Map<String, int> map) {
    final entries = map.entries.map((e) => '"${e.key}":${e.value}').join(',');
    return '{$entries}';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _stars {
    final percentage = widget.score / widget.totalQuestions * 100;
    if (percentage >= 90) return 3;
    if (percentage >= 70) return 2;
    if (percentage >= 50) return 1;
    return 0;
  }

  String get _message {
    if (_stars == 3) return 'Perfeito! 🎉';
    if (_stars == 2) return 'Muito bem! 👏';
    if (_stars == 1) return 'Bom trabalho! 💪';
    return 'Continue tentando! 📚';
  }

  Color get _primaryColor {
    if (_stars >= 2) return const Color(0xFF4CAF50);
    if (_stars == 1) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame celebration background
          Positioned.fill(
            child: GameWidget(
              game: ResultsGame(
                stars: _stars,
                primaryColor: _primaryColor,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  // Star rating animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: StarRating(
                      stars: _stars,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Result message
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      _message,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // XP Animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: XpAnimation(
                      xpGained: widget.xpGained,
                      primaryColor: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Result stats
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ResultStats(
                      correct: widget.score,
                      total: widget.totalQuestions,
                      primaryColor: _primaryColor,
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                AppRoutes.home,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Retry button (if not perfect)
                        if (_stars < 3)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.gameplay,
                                  arguments: {'lessonId': widget.lessonId},
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Tentar Novamente',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
