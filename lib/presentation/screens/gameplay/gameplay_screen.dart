import 'package:flutter/material.dart';
import '../../../app/routes.dart';
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

  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  // Sample questions - TODO: Load from repository
  final List<QuestionData> _questions = [
    const QuestionData(
      text: 'Qual é o resultado de 15 + 27?',
      options: ['32', '42', '52', '62'],
      correctIndex: 1,
      explanation: '15 + 27 = 42. Somamos unidades (5+7=12, escrevemos 2 e levamos 1) e depois dezenas (1+2+1=4).',
    ),
    const QuestionData(
      text: 'Qual é o menor múltiplo comum de 4 e 6?',
      options: ['6', '12', '24', '36'],
      correctIndex: 1,
      explanation: 'Os múltiplos de 4 são: 4, 8, 12, 16... Os múltiplos de 6 são: 6, 12, 18... O menor comum é 12.',
    ),
    const QuestionData(
      text: 'Qual número é divisor de 20?',
      options: ['3', '6', '7', '5'],
      correctIndex: 3,
      explanation: '20 ÷ 5 = 4, sem resto. Portanto, 5 é divisor de 20.',
    ),
    const QuestionData(
      text: 'Quanto é 8 × 7?',
      options: ['54', '56', '48', '64'],
      correctIndex: 1,
      explanation: '8 × 7 = 56. Uma forma de lembrar: 7 × 8 = 56 (os números 5, 6, 7, 8 em sequência).',
    ),
    const QuestionData(
      text: 'Qual é o resultado de 100 - 37?',
      options: ['73', '67', '63', '53'],
      correctIndex: 2,
      explanation: '100 - 37 = 63. Podemos calcular: 100 - 40 = 60, depois 60 + 3 = 63.',
    ),
  ];

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
    // TODO: Load questions from repository based on lessonId
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
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

    final isCorrect = index == _questions[_currentQuestionIndex].correctIndex;
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

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Questão ${_currentQuestionIndex + 1}/${_questions.length}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          TimerWidget(
            duration: 30,
            onTimeUp: _onTimeUp,
            key: ValueKey(_currentQuestionIndex),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress bar
              GameProgressBar(
                current: _currentQuestionIndex + 1,
                total: _questions.length,
              ),
              const SizedBox(height: 24),
              // Question
              Expanded(
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: QuestionCard(
                    question: currentQuestion.text,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Answer options
              ...List.generate(currentQuestion.options.length, (index) {
                final isSelected = _selectedAnswerIndex == index;
                final isCorrect = index == currentQuestion.correctIndex;
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
              // Explanation (shown after answering)
              if (_hasAnswered)
                AnimatedOpacity(
                  opacity: _hasAnswered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentQuestion.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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

/// Data class for questions
class QuestionData {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuestionData({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
