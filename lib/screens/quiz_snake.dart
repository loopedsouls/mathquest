import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../models/quiz_snake_questions_math.dart';

class QuizSnakeScreen extends StatefulWidget {
  final bool isOfflineMode;
  final String? topico;
  final String? dificuldade;

  const QuizSnakeScreen({
    super.key,
    this.isOfflineMode = false,
    this.topico,
    this.dificuldade,
  });

  @override
  State<QuizSnakeScreen> createState() => _QuizAlternadoScreenState();
}

class _QuizAlternadoScreenState extends State<QuizSnakeScreen>
    with TickerProviderStateMixin {
  // Estado do Quiz
  Map<String, dynamic>? perguntaAtual;
  String tipoAtual = '';
  int perguntaIndex = 0;
  int totalPerguntas = 10;
  String? respostaSelecionada;
  bool carregando = false;
  bool quizFinalizado = false;
  final TextEditingController _respostaController = TextEditingController();

  // Questões estáticas baseadas na velocidade
  late List<Map<String, dynamic>> _questions;

  // Resultados
  List<Map<String, dynamic>> respostas = [];
  int pontuacao = 0;
  Map<String, int> estatisticas = {
    'corretas': 0,
    'incorretas': 0,
    'multipla_escolha': 0,
    'verdadeiro_falso': 0,
    'complete_frase': 0,
  };

  // Animações
  late AnimationController _animationController;
  late AnimationController _progressController;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardScaleAnimation;

  // Estado da tela
  bool _mostrarTelaInicial = true;
  bool _mostrarCarregamento = false;

  // Jogo da Cobrinha
  List<Offset> _snakeSegments = [];
  Offset _foodPosition = Offset.zero;
  Offset _direction = const Offset(1, 0); // Direita
  bool _gameRunning = false;
  late AnimationController _snakeController;
  Timer? _gameTimer; // Timer para movimento contínuo
  final int _initialSnakeLength = 10;
  int _currentSnakeLength = 10;

  // Inimigos (tipo Slither.io)
  final List<List<Offset>> _enemySnakes = [];
  final List<Offset> _enemyDirections = [];
  final List<Color> _enemyColors = [];

  // Configurações do jogo - agora dinâmico
  int _gridSize = 20;
  double _cellSize = 15;

  // Modos de velocidade
  SnakeSpeed _currentSpeed = SnakeSpeed.normal;

  // Configurações visuais
  late String ano;
  late String topico;
  late String dificuldade;
  @override
  void initState() {
    super.initState();
    // Inicializar variáveis
    ano = '1º ano';
    topico = widget.topico ?? 'números e operações';
    dificuldade = widget.dificuldade ?? 'fácil';

    _initializeAnimations();
    _initializeSnakeGame();
    _questions = getQuizSnakeQuestions(_currentSpeed);
    debugPrint('Questões carregadas: ${_questions.length}');
    debugPrint('Velocidade atual: $_currentSpeed');
    _respostaController.addListener(_onRespostaChanged);
  }

  void _onRespostaChanged() {
    if (mounted) {
      setState(() {
        respostaSelecionada = _respostaController.text.trim();
      });
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _snakeController = AnimationController(
      duration: _getSnakeSpeedDuration(),
      vsync: this,
    );

    _animationController.forward();
    _cardAnimationController.forward();
  }

  Duration _getSnakeSpeedDuration() {
    switch (_currentSpeed) {
      case SnakeSpeed.lento:
        return const Duration(milliseconds: 500);
      case SnakeSpeed.normal:
        return const Duration(milliseconds: 200);
      case SnakeSpeed.rapido:
        return const Duration(milliseconds: 100);
      case SnakeSpeed.hardcore:
        return const Duration(milliseconds: 50);
    }
  }

  String _getSpeedName(SnakeSpeed speed) {
    switch (speed) {
      case SnakeSpeed.lento:
        return 'Lento';
      case SnakeSpeed.normal:
        return 'Normal';
      case SnakeSpeed.rapido:
        return 'Rápido';
      case SnakeSpeed.hardcore:
        return 'Hardcore';
    }
  }

  Widget _buildSnakePanel() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: Column(
        children: [
          // Título e contador
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.games_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Cobra: ${_snakeSegments.length} • ${_getSpeedName(_currentSpeed)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Área do jogo
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _cellSize = (constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight) /
                      _gridSize;

                  return CustomPaint(
                    painter: SnakePainter(
                      snakeSegments: _snakeSegments,
                      foodPosition: _foodPosition,
                      cellSize: _cellSize,
                      enemySnakes: _enemySnakes,
                      enemyColors: _enemyColors,
                      gridSize: _gridSize,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPanel(bool isTablet) {
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          children: [
            // Progresso e status
            _buildStatusProgress(isTablet),
            SizedBox(height: isTablet ? 24 : 20),

            // Card do exercício
            if (carregando)
              _buildLoadingCard(isTablet)
            else if (perguntaAtual != null)
              _buildExercicioCard(isTablet),

            SizedBox(height: isTablet ? 24 : 20),

            // Botões de ação
            if (!carregando && perguntaAtual != null)
              _buildActionButtons(isTablet),
          ],
        ),
      ),
    );
  }

  void _initializeSnakeGame() {
    // Inicializar cobra com 10 segmentos no centro do grid
    _snakeSegments = [];
    final centerX = _gridSize ~/ 2;
    final centerY = _gridSize ~/ 2;
    for (int i = 0; i < _initialSnakeLength; i++) {
      _snakeSegments.add(Offset(centerX - i.toDouble(), centerY.toDouble()));
    }

    // Posição inicial da comida (longe da cobra)
    _foodPosition = Offset((centerX + 5).toDouble(), centerY.toDouble());

    // Inicializar inimigos
    _initializeEnemies();
  }

  void _initializeEnemies() {
    _enemySnakes.clear();
    _enemyDirections.clear();
    _enemyColors.clear();

    // Criar 3 inimigos
    for (int i = 0; i < 3; i++) {
      // Posições iniciais diferentes para cada inimigo
      List<Offset> enemySegments = [];
      for (int j = 0; j < 5; j++) {
        enemySegments.add(Offset(
          (5 + i * 5).toDouble() - j,
          (5 + i * 3).toDouble(),
        ));
      }

      _enemySnakes.add(enemySegments);
      _enemyDirections.add(_getRandomDirection());
      _enemyColors.add(_getEnemyColor(i));
    }
  }

  Offset _getRandomDirection() {
    final directions = [
      const Offset(1, 0), // direita
      const Offset(-1, 0), // esquerda
      const Offset(0, 1), // baixo
      const Offset(0, -1), // cima
    ];
    return directions[(DateTime.now().millisecondsSinceEpoch +
            DateTime.now().microsecondsSinceEpoch) %
        4];
  }

  Color _getEnemyColor(int index) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void _startSnakeGame() {
    if (_gameRunning) return;

    _gameRunning = true;
    // Iniciar movimento contínuo da cobra
    _startContinuousMovement();
  }

  void _startContinuousMovement() {
    _gameTimer?.cancel(); // Cancelar timer anterior se existir
    final duration = _getSnakeSpeedDuration();
    _gameTimer = Timer.periodic(duration, (timer) {
      if (_gameRunning && mounted) {
        _moveSnakeOnce();
      } else {
        timer.cancel();
      }
    });
  }

  void _moveSnakeOnce() {
    if (!_gameRunning || _snakeSegments.isEmpty) return;

    final head = _snakeSegments.first;
    var newHead = head + _direction;

    // Wrap-around nas bordas - a cobra pode atravessar para o lado oposto
    if (newHead.dx < 0) {
      newHead = Offset(_gridSize - 1, newHead.dy);
    } else if (newHead.dx >= _gridSize) {
      newHead = Offset(0, newHead.dy);
    }

    if (newHead.dy < 0) {
      newHead = Offset(newHead.dx, _gridSize - 1);
    } else if (newHead.dy >= _gridSize) {
      newHead = Offset(newHead.dx, 0);
    }

    // Adicionar nova cabeça
    _snakeSegments.insert(0, newHead);

    // Remover cauda se não comeu comida
    if (_snakeSegments.first != _foodPosition) {
      _snakeSegments.removeLast();
    } else {
      // Comeu comida - gerar nova posição
      _generateFood();
    }

    // Atualizar inimigos
    _updateEnemies();

    if (mounted) {
      setState(() {});
    }
  }

  void _updateEnemies() {
    for (int i = 0; i < _enemySnakes.length; i++) {
      if (_enemySnakes[i].isEmpty) continue;

      final head = _enemySnakes[i].first;
      Offset newDirection = _enemyDirections[i];

      // Lógica simples: 70% chance de continuar na mesma direção, 30% de mudar
      if ((DateTime.now().millisecondsSinceEpoch + i * 100) % 10 < 3) {
        newDirection = _getRandomDirection();
      }

      var newHead = head + newDirection;

      // Wrap-around nas bordas para inimigos também
      if (newHead.dx < 0) {
        newHead = Offset(_gridSize - 1, newHead.dy);
      } else if (newHead.dx >= _gridSize) {
        newHead = Offset(0, newHead.dy);
      }

      if (newHead.dy < 0) {
        newHead = Offset(newHead.dx, _gridSize - 1);
      } else if (newHead.dy >= _gridSize) {
        newHead = Offset(newHead.dx, 0);
      }

      // Adicionar nova cabeça
      _enemySnakes[i].insert(0, newHead);

      // Remover cauda se não comeu comida
      if (_enemySnakes[i].first != _foodPosition) {
        _enemySnakes[i].removeLast();
      } else {
        // Inimigo comeu a comida - gerar nova posição
        _generateFood();
      }

      _enemyDirections[i] = newDirection;
    }
  }

  void _generateFood() {
    final random = DateTime.now().millisecondsSinceEpoch;
    _foodPosition = Offset(
      (random % (_gridSize - 2)).toDouble() + 1,
      ((random ~/ 100) % (_gridSize - 2)).toDouble() + 1,
    );
  }

  void _changeDirection(Offset newDirection) {
    // Evitar mudança para direção oposta (não pode ir para trás)
    if (_direction + newDirection != Offset.zero) {
      _direction = newDirection;
    }
  }

  void _moveUp() => _changeDirection(const Offset(0, -1));
  void _moveDown() => _changeDirection(const Offset(0, 1));
  void _moveLeft() => _changeDirection(const Offset(-1, 0));
  void _moveRight() => _changeDirection(const Offset(1, 0));

  void _diminuirCobra() {
    if (_snakeSegments.length > 1) {
      _snakeSegments.removeLast();
      _currentSnakeLength = _snakeSegments.length;
      debugPrint('Cobra diminuiu para $_currentSnakeLength segmentos');
    }
  }

  int _calculateGridSize(double availableWidth, double availableHeight) {
    // Calcular grid size baseado no tamanho da tela
    final minSize =
        availableWidth < availableHeight ? availableWidth : availableHeight;

    if (minSize > 400) {
      return 25; // Tela grande - mais células
    } else if (minSize > 300) {
      return 20; // Tela média
    } else {
      return 15; // Tela pequena - menos células
    }
  }

  Future<void> _gerarPergunta() async {
    if (perguntaIndex >= _questions.length) {
      _finalizarQuiz();
      return;
    }

    if (mounted) {
      setState(() {
        carregando = true;
        perguntaAtual = null;
        respostaSelecionada = null;
        _respostaController.clear();
      });
    }

    final pergunta = _questions[perguntaIndex];
    _processarPerguntaCache(pergunta);

    _diminuirCobra();

    if (mounted) {
      setState(() {
        carregando = false;
      });
    }

    _animationController.reset();
    _animationController.forward();
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  void _processarPerguntaCache(Map<String, dynamic> pergunta) {
    if (mounted) {
      setState(() {
        perguntaAtual = pergunta;
        tipoAtual = pergunta['tipo'] ?? 'multipla_escolha';
      });
    }

    debugPrint('Pergunta processada: ${pergunta['pergunta']}');
    debugPrint('Tipo: ${pergunta['tipo']}');
    debugPrint('Opções: ${pergunta['opcoes']}');
    debugPrint('Resposta correta: ${pergunta['resposta_correta']}');
  }

  Widget _buildMultiplaEscolha() {
    final opcoes = perguntaAtual!['opcoes'] as List<String>? ?? [];

    return Column(
      children: opcoes.asMap().entries.map((entry) {
        final index = entry.key;
        final opcao = entry.value;
        final letra = String.fromCharCode(65 + index); // A, B, C, D
        final isSelected = respostaSelecionada == letra;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ModernButton(
            text: '$letra) $opcao',
            onPressed: () {
              if (mounted) {
                setState(() {
                  respostaSelecionada = letra;
                });
              }
            },
            isPrimary: isSelected,
            isFullWidth: true,
            icon: isSelected ? Icons.check_circle : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerdadeiroFalso() {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: 'Verdadeiro',
            onPressed: () {
              if (mounted) {
                setState(() {
                  respostaSelecionada = 'Verdadeiro';
                });
              }
            },
            isPrimary: respostaSelecionada == 'Verdadeiro',
            icon: respostaSelecionada == 'Verdadeiro'
                ? Icons.check_circle
                : Icons.check,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ModernButton(
            text: 'Falso',
            onPressed: () {
              if (mounted) {
                setState(() {
                  respostaSelecionada = 'Falso';
                });
              }
            },
            isPrimary: respostaSelecionada == 'Falso',
            icon: respostaSelecionada == 'Falso'
                ? Icons.check_circle
                : Icons.close,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteFrase() {
    return ModernTextField(
      hint: 'Digite sua resposta aqui',
      controller: _respostaController,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.edit_rounded,
    );
  }

  void _proximaPergunta() async {
    if (respostaSelecionada == null || respostaSelecionada!.isEmpty) {
      _showErrorDialog('Por favor, selecione uma resposta.');
      return;
    }

    // Incrementa estatística do tipo atual
    estatisticas[tipoAtual] = (estatisticas[tipoAtual] ?? 0) + 1;

    final respostaCorreta = perguntaAtual!['resposta_correta'];
    bool acertou = false;

    // Verifica resposta baseada no tipo
    switch (tipoAtual) {
      case 'multipla_escolha':
        // Para múltipla escolha, precisamos encontrar qual letra corresponde à resposta correta
        final opcoes = perguntaAtual!['opcoes'] as List<String>? ?? [];
        final respostaCorretaValor = respostaCorreta;
        int respostaCorretaIndex = -1;

        // Encontrar o índice da resposta correta nas opções
        for (int i = 0; i < opcoes.length; i++) {
          if (opcoes[i] == respostaCorretaValor) {
            respostaCorretaIndex = i;
            break;
          }
        }

        if (respostaCorretaIndex != -1) {
          final letraCorreta =
              String.fromCharCode(65 + respostaCorretaIndex); // A, B, C, D
          acertou = respostaSelecionada == letraCorreta;
          debugPrint(
              'Múltipla escolha - Selecionada: "$respostaSelecionada", Correta: "$letraCorreta", Acertou: $acertou');
          debugPrint('Opções: $opcoes');
          debugPrint('Resposta correta valor: "$respostaCorretaValor"');
        } else {
          acertou = false; // Resposta correta não encontrada nas opções
          debugPrint(
              'ERRO: Resposta correta "$respostaCorretaValor" não encontrada nas opções: $opcoes');
        }
        break;
      case 'verdadeiro_falso':
        acertou = respostaSelecionada == respostaCorreta;
        debugPrint(
            'Verdadeiro/Falso - Selecionada: $respostaSelecionada, Correta: $respostaCorreta, Acertou: $acertou');
        break;
      case 'complete_frase':
        final respostaUsuario = respostaSelecionada!.toLowerCase().trim();
        final respostaEsperada =
            respostaCorreta.toString().toLowerCase().trim();
        acertou = respostaUsuario == respostaEsperada;
        debugPrint(
            'Complete frase - Usuario: "$respostaUsuario", Esperada: "$respostaEsperada", Acertou: $acertou');
        break;
    }

    if (acertou) {
      pontuacao += 10;
      estatisticas['corretas'] = estatisticas['corretas']! + 1;
    } else {
      estatisticas['incorretas'] = estatisticas['incorretas']! + 1;
    }

    // Salva a resposta
    respostas.add({
      'pergunta': perguntaAtual!['pergunta'],
      'tipo': tipoAtual,
      'resposta_usuario': respostaSelecionada,
      'resposta_correta': respostaCorreta,
      'acertou': acertou,
      'explicacao': perguntaAtual!['explicacao'] ?? '',
    });

    if (mounted) {
      setState(() {
        perguntaIndex++;
      });
    }

    // Atualiza progresso
    _progressController.animateTo(perguntaIndex / totalPerguntas);

    // Mostra explicação se errou
    if (!acertou) {
      await _mostrarExplicacao();
    }

    // Reset das animações e próxima pergunta
    _cardAnimationController.reset();
    if (mounted) {
      setState(() {
        respostaSelecionada = null;
        _respostaController.clear();
      });
    }

    // Próxima pergunta - será instantânea se houver pré-carregada
    await _gerarPergunta();
  }

  Future<void> _mostrarExplicacao() async {
    final explicacao =
        perguntaAtual!['explicacao'] ?? 'Explicação não disponível.';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Explicação',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          explicacao,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendi',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _finalizarQuiz() {
    // Parar o jogo da cobra
    _gameRunning = false;
    _gameTimer?.cancel();

    if (mounted) {
      setState(() {
        quizFinalizado = true;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          'Erro',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    String progresso = 'Pergunta ${perguntaIndex + 1}/$totalPerguntas';
    String nivel = 'Tipo: ${_getTipoTitulo(tipoAtual)}';

    return '$progresso • $nivel';
  }

  Widget _buildHeaderTrailing(bool isTablet) {
    return StatusIndicator(
      text: 'Offline',
      icon: Icons.games_rounded,
      color: AppTheme.primaryColor,
      isActive: true,
    );
  }

  Widget _buildStatusProgress(bool isTablet) {
    final totalExercicios = respostas.length;
    final corretos = respostas.where((r) => r['acertou'] == true).length;
    final progresso = totalExercicios > 0 ? corretos / totalExercicios : 0.0;

    return ModernCard(
      child: Column(
        children: [
          ModernProgressIndicator(
            value: (perguntaIndex + 1) / totalPerguntas,
            label: 'Progresso do Quiz',
            color: AppTheme.primaryColor,
          ),
          if (totalExercicios > 0) ...[
            SizedBox(height: isTablet ? 20 : 16),
            ModernProgressIndicator(
              value: progresso,
              label: 'Taxa de Acertos: ${(progresso * 100).round()}%',
              color: AppTheme.successColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard(bool isTablet) {
    return ModernCard(
      hasGlow: true,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Gerando próximo exercício...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(bool isTablet) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: ModernCard(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo do exercício
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTipoColor(tipoAtual).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: _getTipoColor(tipoAtual).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTipoIcon(tipoAtual),
                        color: _getTipoColor(tipoAtual),
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        _getTipoTitulo(tipoAtual),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getTipoColor(tipoAtual),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Pergunta
            Text(
              perguntaAtual!['pergunta'] ?? '',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.darkTextPrimaryColor,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Interface do tipo
            _buildTipoInterface(tipoAtual, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return ModernButton(
      text: perguntaIndex < totalPerguntas - 1
          ? 'Próxima Pergunta'
          : 'Finalizar Quiz',
      onPressed: respostaSelecionada != null && respostaSelecionada!.isNotEmpty
          ? _proximaPergunta
          : null,
      isPrimary: true,
      icon: perguntaIndex < totalPerguntas - 1
          ? Icons.arrow_forward
          : Icons.check,
      isFullWidth: true,
    );
  }

  Widget _buildTelaInicial() {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone do quiz
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryLightColor
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Título
                Text(
                  'Quiz Alternado',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Descrição
                Text(
                  'Teste seus conhecimentos com perguntas\nde múltipla escolha, verdadeiro/falso\ne complete a frase!',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 60),

                // Seleção de modo de velocidade
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.darkBorderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Modo da Cobra',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: SnakeSpeed.values.map((speed) {
                          final isSelected = _currentSpeed == speed;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: ModernButton(
                                text: _getSpeedName(speed),
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _currentSpeed = speed;
                                      // Reiniciar movimento com nova velocidade
                                      if (_gameRunning) {
                                        _startContinuousMovement();
                                      }
                                    });
                                  }
                                },
                                isPrimary: isSelected,
                                isFullWidth: true,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botão Start
                ModernButton(
                  text: 'Começar Quiz',
                  onPressed: _iniciarQuiz,
                  isPrimary: true,
                  icon: Icons.play_arrow_rounded,
                  isFullWidth: false,
                ),

                const SizedBox(height: 40),

                // Informações
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sobre o Quiz',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.darkTextPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• 10 perguntas de tipos variados\n• IA gera conteúdo personalizado\n• Pré-carregamento para experiência fluida',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _iniciarQuiz() {
    if (mounted) {
      setState(() {
        _mostrarTelaInicial = false;
        _mostrarCarregamento = true;
      });
    }

    // Iniciar jogo da cobrinha imediatamente
    _startSnakeGame();

    // Iniciar carregamento das perguntas
    _iniciarCarregamentoPerguntas();
  }

  Future<void> _iniciarCarregamentoPerguntas() async {
    // Aguardar um pouco para mostrar a tela de carregamento
    await Future.delayed(const Duration(milliseconds: 500));

    // Iniciar geração da primeira pergunta
    await _gerarPergunta();

    // Aguardar mais um pouco para mostrar o jogo
    await Future.delayed(const Duration(seconds: 2));

    // Transicionar para o quiz - manter jogo rodando
    if (mounted) {
      setState(() {
        _mostrarCarregamento = false;
        // Não parar o jogo - _gameRunning permanece true
      });
    }
  }

  Widget _buildTelaCarregamento() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;

    if (isDesktop) {
      // Tela cheia apenas com o jogo para desktop
      return _buildFullscreenSnakeGame();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _mostrarCarregamento = false;
                            _mostrarTelaInicial = true;
                            _gameRunning = false;
                            _gameTimer?.cancel();
                            _snakeController.stop();
                          });
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Preparando seu Quiz...',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Jogo da Cobrinha - Console ou interface simples baseado no tamanho da tela
              Expanded(
                child:
                    isTablet ? _buildRetroConsole() : _buildSimpleSnakeGame(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleSnakeGame() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorderColor),
      ),
      child: Column(
        children: [
          // Título e contador
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.games_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Jogo da Cobrinha',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_snakeSegments.length} segmentos',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Área do jogo com controles
          Expanded(
            child: Column(
              children: [
                // Área do jogo (usa LayoutBuilder para auto-redimensionamento)
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calcular tamanho da célula baseado no espaço disponível
                        final availableWidth = constraints.maxWidth;
                        final availableHeight = constraints.maxHeight;
                        _cellSize = (availableWidth < availableHeight
                                ? availableWidth
                                : availableHeight) /
                            _gridSize;

                        return CustomPaint(
                          painter: SnakePainter(
                            snakeSegments: _snakeSegments,
                            foodPosition: _foodPosition,
                            cellSize: _cellSize,
                            enemySnakes: _enemySnakes,
                            enemyColors: _enemyColors,
                            gridSize: _gridSize,
                          ),
                          child: Container(),
                        );
                      },
                    ),
                  ),
                ),

                // Controles de toque
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      // Botão cima
                      IconButton(
                        onPressed: _moveUp,
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Linha com esquerda, centro (vazio), direita
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _moveLeft,
                            icon: Icon(
                              Icons.keyboard_arrow_left,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40), // Espaço vazio no centro
                          IconButton(
                            onPressed: _moveRight,
                            icon: Icon(
                              Icons.keyboard_arrow_right,
                              color: AppTheme.primaryColor,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Botão baixo
                      IconButton(
                        onPressed: _moveDown,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Gerando perguntas inteligentes...',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A cobra diminui conforme as perguntas são criadas!',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetroConsole() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Ajustar margens e aspect ratio baseado no tamanho da tela
    final isLargeScreen = screenWidth > 1200;
    final margin = isLargeScreen ? 40.0 : 24.0;
    final aspectRatio = screenWidth > screenHeight ? 1.4 : 1.1;

    return Container(
      margin: EdgeInsets.all(margin),
      child: AspectRatio(
        aspectRatio: aspectRatio, // Responsivo baseado na orientação
        child: Container(
          decoration: BoxDecoration(
            // Gradiente usando as cores do tema
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkSurfaceColor,
                AppTheme.darkBackgroundColor,
                AppTheme.darkSurfaceColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.darkBorderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Tela do jogo ocupando todo o espaço
              Expanded(
                flex: 6, // Aumentado ainda mais
                child: Container(
                  margin: const EdgeInsets.all(8), // Margem mínima apenas
                  child: Container(
                    decoration: BoxDecoration(
                      // Tela com bordas do tema
                      color: AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.darkBorderColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.darkBackgroundColor
                              .withValues(alpha: 0.8),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4), // Margem interna mínima
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.darkBackgroundColor,
                            AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Efeito de tela retrô com brilho
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.08),
                                  Colors.transparent,
                                  AppTheme.primaryColor.withValues(alpha: 0.04),
                                ],
                              ),
                            ),
                          ),
                          // Jogo da cobrinha
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final availableHeight = constraints.maxHeight;
                              _gridSize = _calculateGridSize(
                                  availableWidth, availableHeight);
                              _cellSize = (availableWidth < availableHeight
                                      ? availableWidth
                                      : availableHeight) /
                                  _gridSize;

                              return CustomPaint(
                                painter: SnakePainter(
                                  snakeSegments: _snakeSegments,
                                  foodPosition: _foodPosition,
                                  cellSize: _cellSize,
                                  enemySnakes: _enemySnakes,
                                  enemyColors: _enemyColors,
                                  gridSize: _gridSize,
                                ),
                                child: Container(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Controles do console
              Expanded(
                flex: 1, // Reduzido de 2 para 1
                child: Container(
                  margin:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(
                    children: [
                      // D-Pad (Esquerda)
                      Expanded(
                        child: _buildDPad(),
                      ),

                      // Área central com informações
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Indicadores do console com pontuação
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildConsoleLED(true),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_snakeSegments.length}',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildConsoleLED(false),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerando Quiz...',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.darkTextPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cobra diminui a cada pergunta!',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.darkTextSecondaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Botões de ação (Direita)
                      Expanded(
                        child: _buildConsoleActionButtons(),
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

  Widget _buildConsoleLED(bool isOn) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isOn ? Colors.greenAccent : Colors.red,
        borderRadius: BorderRadius.circular(4),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
      ),
    );
  }

  Widget _buildDPad() {
    final screenWidth = MediaQuery.of(context).size.width;
    final dPadSize =
        screenWidth > 1200 ? 140.0 : 120.0; // Maior em telas grandes

    return SizedBox(
      width: dPadSize,
      height: dPadSize,
      child: Stack(
        children: [
          // Centro do D-Pad
          Positioned(
            left: dPadSize / 3,
            top: dPadSize / 3,
            child: Container(
              width: dPadSize / 3,
              height: dPadSize / 3,
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Cima
          Positioned(
            left: dPadSize / 3,
            top: 0,
            child: _buildDPadButton(Icons.keyboard_arrow_up, _moveUp),
          ),
          // Baixo
          Positioned(
            left: dPadSize / 3,
            bottom: 0,
            child: _buildDPadButton(Icons.keyboard_arrow_down, _moveDown),
          ),
          // Esquerda
          Positioned(
            left: 0,
            top: dPadSize / 3,
            child: _buildDPadButton(Icons.keyboard_arrow_left, _moveLeft),
          ),
          // Direita
          Positioned(
            right: 0,
            top: dPadSize / 3,
            child: _buildDPadButton(Icons.keyboard_arrow_right, _moveRight),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton(IconData icon, VoidCallback onPressed) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize =
        screenWidth > 1200 ? 45.0 : 40.0; // Maior em telas grandes

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppTheme.darkTextPrimaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildConsoleActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildConsoleButton('A', Colors.blue),
            const SizedBox(width: 12),
            _buildConsoleButton('B', Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildConsoleButton('X', Colors.purple),
            const SizedBox(width: 12),
            _buildConsoleButton('Y', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildConsoleButton(String label, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize =
        screenWidth > 1200 ? 38.0 : 32.0; // Maior em telas grandes

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkBorderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenSnakeGame() {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.keyW) {
            _moveUp();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.keyS) {
            _moveDown();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
              event.logicalKey == LogicalKeyboardKey.keyA) {
            _moveLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.keyD) {
            _moveRight();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            // ESC para voltar
            if (mounted) {
              setState(() {
                _mostrarCarregamento = false;
                _mostrarTelaInicial = true;
                _gameRunning = false;
                _gameTimer?.cancel();
                _snakeController.stop();
              });
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBackgroundColor,
        body: Stack(
          children: [
            // Jogo da cobrinha centralizado
            Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.darkBackgroundColor,
                      AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0, // Área quadrada para o jogo
                    child: Container(
                      margin: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final gameSize =
                              constraints.maxWidth < constraints.maxHeight
                                  ? constraints.maxWidth
                                  : constraints.maxHeight;
                          _gridSize = 30; // Grid fixo maior para telas grandes
                          _cellSize = gameSize / _gridSize;

                          return CustomPaint(
                            painter: SnakePainter(
                              snakeSegments: _snakeSegments,
                              foodPosition: _foodPosition,
                              cellSize: _cellSize,
                              enemySnakes: _enemySnakes,
                              enemyColors: _enemyColors,
                              gridSize: _gridSize,
                            ),
                            child: Container(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // HUD com informações no canto superior esquerdo
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorderColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparando Quiz...',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_snakeSegments.length} segmentos',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextPrimaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Instruções de controle no canto superior direito
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorderColor,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Controles:',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WASD ou Setas para mover',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    Text(
                      'ESC para voltar',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _respostaController.removeListener(_onRespostaChanged);
    _gameTimer?.cancel(); // Cancelar timer do jogo
    _animationController.dispose();
    _progressController.dispose();
    _cardAnimationController.dispose();
    _snakeController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    // Mostrar tela inicial primeiro
    if (_mostrarTelaInicial) {
      return _buildTelaInicial();
    }

    // Mostrar tela de carregamento com jogo da cobrinha
    if (_mostrarCarregamento) {
      return _buildTelaCarregamento();
    }

    if (quizFinalizado) {
      return _buildResultadoScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header responsivo com botão voltar para a tela inicial
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: isTablet ? 8 : 6,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      icon: Icon(
                        Icons.home_rounded,
                        color: AppTheme.primaryColor,
                        size: isTablet ? 28 : 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: ResponsiveHeader(
                        title: 'Quiz Alternado',
                        subtitle: _buildSubtitle(),
                        trailing: _buildHeaderTrailing(isTablet),
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo principal
              Expanded(
                child: Row(
                  children: [
                    _buildSnakePanel(),
                    const SizedBox(width: 16),
                    _buildQuizPanel(isTablet),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultadoScreen() {
    final porcentagem = (pontuacao / (totalPerguntas * 10) * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurfaceColor,
        elevation: 0,
        title: Text(
          'Resultado do Quiz',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Pontuação principal
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorderColor),
              ),
              child: Column(
                children: [
                  Text(
                    'Quiz Finalizado!',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$pontuacao pontos',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    '$porcentagem% de acertos',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Estatísticas por tipo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estatísticas por Tipo',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEstatisticaItem(
                      'Múltipla Escolha',
                      estatisticas['multipla_escolha'] ?? 0,
                      Icons.quiz,
                      AppTheme.primaryColor),
                  _buildEstatisticaItem(
                      'Verdadeiro/Falso',
                      estatisticas['verdadeiro_falso'] ?? 0,
                      Icons.check_circle,
                      AppTheme.successColor),
                  _buildEstatisticaItem(
                      'Complete a Frase',
                      estatisticas['complete_frase'] ?? 0,
                      Icons.edit,
                      AppTheme.warningColor),
                  Divider(color: AppTheme.darkBorderColor),
                  _buildEstatisticaItem(
                      'Acertos',
                      estatisticas['corretas'] ?? 0,
                      Icons.check,
                      AppTheme.successColor),
                  _buildEstatisticaItem(
                      'Erros',
                      estatisticas['incorretas'] ?? 0,
                      Icons.close,
                      AppTheme.errorColor),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'Novo Quiz',
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => QuizSnakeScreen(
                            topico: widget.topico,
                            dificuldade: widget.dificuldade,
                          ),
                        ),
                      );
                    },
                    isPrimary: false,
                    icon: Icons.refresh,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ModernButton(
                    text: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    isPrimary: true,
                    icon: Icons.home,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoInterface(String tipo, bool isTablet) {
    switch (tipo) {
      case 'multipla_escolha':
        return _buildMultiplaEscolha();
      case 'verdadeiro_falso':
        return _buildVerdadeiroFalso();
      case 'complete_frase':
        return _buildCompleteFrase();
      default:
        return Container();
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return Icons.list_rounded;
      case 'verdadeiro_falso':
        return Icons.help_rounded;
      case 'complete_frase':
        return Icons.edit_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  String _getTipoTitulo(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return 'Múltipla Escolha';
      case 'verdadeiro_falso':
        return 'Verdadeiro ou Falso';
      case 'complete_frase':
        return 'Complete a Frase';
      default:
        return 'Exercício';
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return AppTheme.primaryColor;
      case 'verdadeiro_falso':
        return AppTheme.secondaryColor;
      case 'complete_frase':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildEstatisticaItem(
      String titulo, int valor, IconData icon, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: cor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextPrimaryColor,
              ),
            ),
          ),
          Text(
            valor.toString(),
            style: AppTheme.bodyMedium.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Classe para desenhar o jogo da cobrinha
class SnakePainter extends CustomPainter {
  final List<Offset> snakeSegments;
  final Offset foodPosition;
  final double cellSize;
  final List<List<Offset>> enemySnakes;
  final List<Color> enemyColors;
  final int gridSize;

  SnakePainter({
    required this.snakeSegments,
    required this.foodPosition,
    required this.cellSize,
    required this.enemySnakes,
    required this.enemyColors,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Desenhar grade de fundo
    paint.color = Colors.grey.withValues(alpha: 0.1);
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        canvas.drawRect(
          Rect.fromLTWH(i * cellSize, j * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }

    // Desenhar inimigos primeiro (atrás da cobra principal)
    for (int enemyIndex = 0; enemyIndex < enemySnakes.length; enemyIndex++) {
      if (enemyIndex < enemyColors.length) {
        paint.color = enemyColors[enemyIndex];
        for (final segment in enemySnakes[enemyIndex]) {
          canvas.drawRect(
            Rect.fromLTWH(
              segment.dx * cellSize,
              segment.dy * cellSize,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }

        // Desenhar cabeça do inimigo (mais clara)
        if (enemySnakes[enemyIndex].isNotEmpty) {
          paint.color = enemyColors[enemyIndex].withValues(alpha: 0.7);
          final head = enemySnakes[enemyIndex].first;
          canvas.drawRect(
            Rect.fromLTWH(
              head.dx * cellSize,
              head.dy * cellSize,
              cellSize - 1,
              cellSize - 1,
            ),
            paint,
          );
        }
      }
    }

    // Desenhar cobra principal
    paint.color = Colors.green;
    for (final segment in snakeSegments) {
      canvas.drawRect(
        Rect.fromLTWH(
          segment.dx * cellSize,
          segment.dy * cellSize,
          cellSize - 1,
          cellSize - 1,
        ),
        paint,
      );
    }

    // Desenhar cabeça da cobra principal (diferente)
    if (snakeSegments.isNotEmpty) {
      paint.color = Colors.greenAccent;
      final head = snakeSegments.first;
      canvas.drawRect(
        Rect.fromLTWH(
          head.dx * cellSize,
          head.dy * cellSize,
          cellSize - 1,
          cellSize - 1,
        ),
        paint,
      );
    }

    // Desenhar comida
    paint.color = Colors.red;
    canvas.drawCircle(
      Offset(
        foodPosition.dx * cellSize + cellSize / 2,
        foodPosition.dy * cellSize + cellSize / 2,
      ),
      cellSize / 2 - 1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
