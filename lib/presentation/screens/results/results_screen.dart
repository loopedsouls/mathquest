import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../widgets/results/result_stats.dart';
import '../../widgets/results/star_rating.dart';
import '../../widgets/results/xp_animation.dart';

/// Results screen - Shows quiz/lesson completion results
class ResultsScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int xpGained;

  const ResultsScreen({
    super.key,
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
      body: SafeArea(
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                            AppRoutes.lessonMap,
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
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Tentar Novamente',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
