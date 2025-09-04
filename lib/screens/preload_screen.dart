import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/preload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';

class PreloadScreen extends StatefulWidget {
  final String selectedAI;
  final String? apiKey;
  final String? ollamaModel;
  final VoidCallback onComplete;

  const PreloadScreen({
    super.key,
    required this.selectedAI,
    this.apiKey,
    this.ollamaModel,
    required this.onComplete,
  });

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen>
    with TickerProviderStateMixin {
  // Progresso do precarregamento
  int _currentQuestion = 0;
  int _totalQuestions = 100;
  String _status = 'Iniciando...';
  bool _isCompleted = false;
  
  // Mini-jogo: Math Bubble Pop
  late AnimationController _gameController;
  late AnimationController _progressController;
  late Timer _gameTimer;
  
  final List<MathBubble> _bubbles = [];
  int _score = 0;
  int _lives = 3;
  String _currentProblem = '';
  int _correctAnswer = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPreloading();
    _initializeGame();
  }

  void _initializeAnimations() {
    _gameController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  void _initializeGame() {
    _generateNewProblem();
    _gameTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isCompleted) {
        _addBubble();
      }
    });
  }

  void _generateNewProblem() {
    final random = Random();
    final a = random.nextInt(10) + 1;
    final b = random.nextInt(10) + 1;
    final operation = random.nextInt(2); // 0 = soma, 1 = subtração
    
    if (operation == 0) {
      _currentProblem = '$a + $b = ?';
      _correctAnswer = a + b;
    } else {
      if (a >= b) {
        _currentProblem = '$a - $b = ?';
        _correctAnswer = a - b;
      } else {
        _currentProblem = '$b - $a = ?';
        _correctAnswer = b - a;
      }
    }
    
    setState(() {});
  }

  void _addBubble() {
    final random = Random();
    final isCorrect = random.nextDouble() < 0.3; // 30% chance de ser a resposta correta
    
    int answer;
    if (isCorrect) {
      answer = _correctAnswer;
    } else {
      // Gera resposta incorreta próxima da correta
      answer = _correctAnswer + random.nextInt(5) - 2;
      if (answer == _correctAnswer) answer += 1;
      if (answer < 0) answer = random.nextInt(10);
    }
    
    final bubble = MathBubble(
      id: DateTime.now().millisecondsSinceEpoch,
      answer: answer,
      isCorrect: isCorrect,
      startY: -50,
      x: random.nextDouble() * 250 + 25, // Ajusta para caber na tela
      color: isCorrect ? Colors.green : Colors.red.withValues(alpha: 0.8),
    );
    
    setState(() {
      _bubbles.add(bubble);
    });
    
    // Anima a bolha descendo
    _animateBubble(bubble);
    
    // Remove bubble after 8 seconds if not popped
    Timer(const Duration(seconds: 8), () {
      _bubbles.removeWhere((b) => b.id == bubble.id);
      if (mounted) setState(() {});
    });
  }

  void _animateBubble(MathBubble bubble) {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_bubbles.any((b) => b.id == bubble.id)) {
        timer.cancel();
        return;
      }
      
      setState(() {
        bubble.currentY += 2; // Velocidade de descida
      });
      
      // Para quando sai da tela
      if (bubble.currentY > MediaQuery.of(context).size.height) {
        timer.cancel();
        _bubbles.removeWhere((b) => b.id == bubble.id);
        setState(() {});
      }
    });
  }

  void _popBubble(MathBubble bubble) {
    setState(() {
      _bubbles.removeWhere((b) => b.id == bubble.id);
      
      if (bubble.isCorrect) {
        _score += 10;
        _generateNewProblem();
      } else {
        _lives--;
        if (_lives <= 0) {
          _lives = 3; // Reset lives
          _score = max(0, _score - 20);
        }
      }
    });
  }

  void _startPreloading() async {
    try {
      await PreloadService.startPreload(
        selectedAI: widget.selectedAI,
        apiKey: widget.apiKey,
        ollamaModel: widget.ollamaModel,
        onProgress: (current, total, status) {
          setState(() {
            _currentQuestion = current;
            _totalQuestions = total;
            _status = status;
            
            if (current == total) {
              _isCompleted = true;
              _gameTimer.cancel();
              
              // Aguarda 3 segundos para garantir que os créditos sejam salvos
              Timer(const Duration(seconds: 3), () {
                widget.onComplete();
              });
            }
          });
          
          _progressController.animateTo(current / total);
        },
      );
    } catch (e) {
      setState(() {
        _status = 'Erro: $e';
        _isCompleted = true;
      });
      
      Timer(const Duration(seconds: 3), () {
        widget.onComplete();
      });
    }
  }

  @override
  void dispose() {
    _gameController.dispose();
    _progressController.dispose();
    _gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkBackgroundColor,
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.darkBackgroundColor,
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(isTablet),

                  // Progress Section
                  _buildProgressSection(isTablet),

                  // Game Area
                  _buildGameArea(isTablet),

                  // Footer
                  _buildFooter(isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Container(
            width: isTablet ? 50 : 40,
            height: isTablet ? 50 : 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Precarregando Perguntas',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Enquanto isso, jogue Math Bubble Pop!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
      child: ModernCard(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$_currentQuestion/$_totalQuestions',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 12 : 8),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: AppTheme.darkBorderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  );
                },
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Text(
                _status,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24 : 16),
      child: ModernCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Game Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Math Bubble Pop',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Estoure as bolhas com a resposta correta!',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGameStat('💰', _score.toString()),
                    SizedBox(width: isTablet ? 16 : 12),
                    _buildGameStat('❤️', _lives.toString()),
                  ],
                ),
              ],
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Current Problem
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _currentProblem,
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: isTablet ? 28 : 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: isTablet ? 12 : 8),

            // Bubbles Area - Limitar altura máxima
            SizedBox(
              height: isTablet ? 300 : 250,
              child: Stack(
                children: [
                  // Background pattern
                  AnimatedBuilder(
                    animation: _gameController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: BackgroundPatternPainter(_gameController.value),
                        size: Size.infinite,
                      );
                    },
                  ),

                  // Bubbles
                  ..._bubbles.map((bubble) => _buildBubble(bubble, isTablet)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStat(String icon, String value) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(MathBubble bubble, bool isTablet) {
    return Positioned(
      left: bubble.x,
      top: bubble.currentY,
      child: GestureDetector(
        onTap: () => _popBubble(bubble),
        child: Container(
          width: isTablet ? 80 : 60,
          height: isTablet ? 80 : 60,
          decoration: BoxDecoration(
            color: bubble.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bubble.color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              bubble.answer.toString(),
              style: AppTheme.headingSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCompleted) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: isTablet ? 8 : 6),
                  Expanded(
                    child: Text(
                      'Precarregamento concluído!',
                      style: AppTheme.bodyLarge.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
          ],

          Text(
            'Sua pontuação final: $_score pontos',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class MathBubble {
  final int id;
  final int answer;
  final bool isCorrect;
  final double x;
  double currentY;
  final double startY;
  final Color color;

  MathBubble({
    required this.id,
    required this.answer,
    required this.isCorrect,
    required this.x,
    required this.startY,
    required this.color,
  }) : currentY = startY;
}

class BackgroundPatternPainter extends CustomPainter {
  final double animation;

  BackgroundPatternPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        final centerX = (size.width / 5) * i + (size.width / 10);
        final centerY = (size.height / 5) * j + (size.height / 10);
        final radius = 15 + sin(animation * 2 * pi + i + j) * 5;
        
        canvas.drawCircle(
          Offset(centerX, centerY),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
