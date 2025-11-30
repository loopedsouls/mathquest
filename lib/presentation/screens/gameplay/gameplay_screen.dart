import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../data/models/question_model.dart';
import '../../../data/repositories/lesson_repository_impl.dart';
import '../../widgets/flame/gameplay_background_game.dart';
import '../../widgets/gameplay/answer_option.dart';
import '../../widgets/gameplay/question_card.dart';
import '../../widgets/gameplay/progress_bar.dart';
import '../../widgets/gameplay/timer_widget.dart';

/// Gameplay screen - Where questions are answered
class GameplayScreen extends StatefulWidget {
  final String lessonId;

  const GameplayScreen({
    super.key,
    required this.lessonId,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _selectedAnswerIndex = -1;
  bool _hasAnswered = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _lessonTitle = '';
  String _lessonSubtitle = '';

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  final LessonRepositoryImpl _lessonRepository = LessonRepositoryImpl();
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_animationController);

    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      // Load lesson details first
      final lesson = await _lessonRepository.getLessonById(widget.lessonId);
      if (lesson != null) {
        _lessonTitle = lesson.title;
        _lessonSubtitle = '${lesson.schoolYear} • ${lesson.thematicUnit}';
      }

      final questions =
          await _lessonRepository.getLessonQuestions(widget.lessonId);
      if (mounted) {
        if (questions.isEmpty) {
          setState(() {
            _errorMessage = 'Nenhuma questão encontrada para esta lição.';
            _isLoading = false;
          });
        } else {
          setState(() {
            _questions = questions;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar questões. Tente novamente.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onAnswerSelected(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
    });

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = index >= 0 && index < currentQuestion.options.length
        ? currentQuestion.options[index]
        : '';
    final isCorrect = currentQuestion.isCorrect(selectedAnswer);

    if (isCorrect) {
      _correctAnswers++;
    } else {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    // Show next question after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = -1;
          _hasAnswered = false;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.results,
      arguments: {
        'lessonId': widget.lessonId,
        'score': _correctAnswers,
        'totalQuestions': _questions.length,
        'xpGained': _correctAnswers * 10,
      },
    );
  }

  void _onTimeUp() {
    if (!_hasAnswered) {
      _onAnswerSelected(-1); // No answer selected
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Carregando questões...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erro'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Nenhuma questão disponível.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadQuestions();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final correctAnswerIndex =
        currentQuestion.options.indexOf(currentQuestion.correctAnswer);

    return Scaffold(
      body: Stack(
        children: [
          // Flame animated background
          Positioned.fill(
            child: GameWidget(
              game: GameplayBackgroundGame(
                primaryColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar with lesson title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    children: [
                      // Lesson title row
                      if (_lessonTitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _lessonTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => _showExitDialog(),
                          ),
                          Expanded(
                            child: Text(
                              'Questão ${_currentQuestionIndex + 1}/${_questions.length}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TimerWidget(
                            duration: 30,
                            onTimeUp: _onTimeUp,
                            key: ValueKey(_currentQuestionIndex),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GameProgressBar(
                    current: _currentQuestionIndex + 1,
                    total: _questions.length,
                  ),
                ),
                const SizedBox(height: 24),
                // Question
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: QuestionCard(
                        question: currentQuestion.question,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Answer options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children:
                        List.generate(currentQuestion.options.length, (index) {
                      final isSelected = _selectedAnswerIndex == index;
                      final isCorrect = index == correctAnswerIndex;
                      final showResult = _hasAnswered;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AnswerOption(
                          text: currentQuestion.options[index],
                          index: index,
                          isSelected: isSelected,
                          isCorrect: showResult ? isCorrect : null,
                          showResult: showResult,
                          onTap: () => _onAnswerSelected(index),
                        ),
                      );
                    }),
                  ),
                ),
                // Explanation (shown after answering)
                if (_hasAnswered && currentQuestion.explanation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedOpacity(
                      opacity: _hasAnswered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currentQuestion.explanation!,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da lição?'),
        content: const Text(
          'Seu progresso nesta lição será perdido. Tem certeza que deseja sair?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pop();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
