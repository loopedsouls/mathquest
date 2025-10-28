import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../models/personagem_model.dart';
import '../services/performance_service.dart';
import '../services/personagem_service.dart';
import '../services/quiz_helper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/modern_components.dart';
import 'quiz_snake.dart';

class QuizAlternadoScreen extends StatefulWidget {
  final bool isOfflineMode;
  final String? topico;
  final String? dificuldade;

  const QuizAlternadoScreen({
    super.key,
    this.isOfflineMode = false,
    this.topico,
    this.dificuldade,
  });

  @override
  State<QuizAlternadoScreen> createState() => _QuizAlternadoScreenState();
}

class _QuizAlternadoScreenState extends State<QuizAlternadoScreen>
    with TickerProviderStateMixin {
  // ... existing fields ...

  // Character system
  late PersonagemService _personagemService;
  Personagem? _personagemSelecionado;

  // Quiz configuration
  late String ano;
  late String topico;
  late String dificuldade;

  // ... rest of existing fields ...
  // Estado do Quiz
  Map<String, dynamic>? perguntaAtual;
  String tipoAtual = '';
  int perguntaIndex = 0;
  int totalPerguntas = 10;
  String? respostaSelecionada;
  bool carregando = false;
  bool quizFinalizado = false;
  bool _useGemini = true;
  final String _modeloOllama = 'llama2';
  bool _perguntaDoCache = false;
  final TextEditingController _respostaController = TextEditingController();

  // Fila de perguntas pré-carregadas
  final List<Map<String, dynamic>> _perguntasPreCarregadas = [];
  bool _preCarregamentoAtivo = false;

  // Tipos de quiz disponíveis - ciclo através deles para garantir todos os tipos
  final List<String> _tiposQuiz = [
    'multipla_escolha',
    'verdadeiro_falso',
    'complete_frase'
  ];
  int _tipoIndex = 0;

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
  final int _initialSnakeLength = 10;
  int _currentSnakeLength = 10;
  int _snakeClickCount = 0;

  // Inimigos (tipo Slither.io)
  final List<List<Offset>> _enemySnakes = [];
  final List<Offset> _enemyDirections = [];
  final List<Color> _enemyColors = [];

  // Configurações do jogo - agora dinâmico
  int _gridSize = 20;
  double _cellSize = 15;

  // Sistema de dificuldade adaptiva
  String _dificuldadeAdaptiva = 'fácil';

  Future<String> _getDificuldadeAtual() async {
    // Usar dificuldade adaptiva baseada na performance do usuário
    _dificuldadeAdaptiva =
        await PerformanceService.calcularDificuldadeAdaptiva();
    return _dificuldadeAdaptiva;
  }

  @override
  void initState() {
    super.initState();
    // Inicializar variáveis
    ano = '1º ano';
    topico = widget.topico ?? 'números e operações';
    dificuldade = widget.dificuldade ?? 'fácil';

    // Inicializar serviços
    _personagemService = PersonagemService();

    _initializeAnimations();
    _initializeSnakeGame();
    _loadPreferences();
    _initializeQuiz();
    _respostaController.addListener(_onRespostaChanged);

    // Inicializar dificuldade adaptiva
    _initializeDificuldadeAdaptiva();
  }

  Future<void> _initializeDificuldadeAdaptiva() async {
    _dificuldadeAdaptiva = await PerformanceService.obterDificuldadeAtual();
    if (mounted) {
      setState(() {});
    }
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

    _animationController.forward();
    _cardAnimationController.forward();
  }

  void _initializeSnakeGame() {
    _snakeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

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
    _snakeController.repeat();

    // Loop do jogo
    _snakeController.addListener(() {
      if (mounted && _gameRunning) {
        _updateSnake();
      }
    });
  }

  void _updateSnake() {
    if (_snakeSegments.isEmpty) return;

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

  Future<void> _loadPreferences() async {
    // Firebase AI é o único serviço disponível
    if (mounted) {
      setState(() {
        _useGemini = true; // Sempre usar Firebase AI
        topico = widget.topico ?? 'números e operações';
        dificuldade = widget.dificuldade ?? 'fácil';
      });
    }
  }

  Future<void> _initializeQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
      _showErrorDialog('API Key do Gemini não configurada');
      return;
    }

    // Carregar personagem selecionado
    _personagemSelecionado = _personagemService.obterPersonagemSelecionado();

    // Usar Firebase AI Service

    // Limpa fila de perguntas pré-carregadas
    _perguntasPreCarregadas.clear();
    _preCarregamentoAtivo = false;

    // Não inicia o quiz automaticamente - espera pelo botão Start da tela inicial
  }

  String _getTipoAtual() {
    final tipo = _tiposQuiz[_tipoIndex % _tiposQuiz.length];
    _tipoIndex++;
    return tipo;
  }

  Future<void> _gerarPergunta() async {
    if (perguntaIndex >= totalPerguntas) {
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

    try {
      // Primeiro, verifica se há perguntas pré-carregadas disponíveis
      if (_perguntasPreCarregadas.isNotEmpty) {
        debugPrint(
            'Usando pergunta pré-carregada. Restam: ${_perguntasPreCarregadas.length - 1}');
        final perguntaPreCarregada = _perguntasPreCarregadas.removeAt(0);
        _processarPerguntaPreCarregada(perguntaPreCarregada);

        // Inicia pré-carregamento da próxima pergunta em background se necessário
        if (_perguntasPreCarregadas.length < 2 && !_preCarregamentoAtivo) {
          _iniciarPreCarregamento();
        }
        return;
      }

      // Se não há perguntas pré-carregadas, gera normalmente
      tipoAtual = _getTipoAtual();

      debugPrint('Gerando primeira pergunta tipo: $tipoAtual');
      debugPrint('Tópico: $topico, Dificuldade: $dificuldade, Ano: $ano');

      final dificuldadeAtual = await _getDificuldadeAtual();
      final pergunta = await QuizHelperService.gerarPerguntaInteligente(
        unidade: topico,
        ano: ano,
        tipoQuiz: tipoAtual,
        dificuldade: dificuldadeAtual,
      );

      if (pergunta != null) {
        debugPrint('Primeira pergunta obtida da IA: ${pergunta['pergunta']}');
        _processarPerguntaCache(pergunta);

        // Diminuir cobra quando gerar primeira pergunta
        _diminuirCobra();

        // Após gerar a primeira pergunta, inicia o pré-carregamento das próximas
        _iniciarPreCarregamento();
      } else {
        _showErrorDialog(
            'Falha ao gerar pergunta com IA. Verifique sua conexão ou configuração.');
        if (mounted) {
          setState(() {
            carregando = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('Erro ao gerar pergunta: $e');
      _showErrorDialog('Erro ao gerar pergunta: $e');
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
      return;
    }

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
        _perguntaDoCache = pergunta['fonte_ia'] == null;
      });
    }

    debugPrint('Pergunta processada. Do cache: $_perguntaDoCache');
    debugPrint('Conteúdo: ${pergunta['pergunta']}');
  }

  void _processarPerguntaPreCarregada(Map<String, dynamic> pergunta) {
    if (mounted) {
      setState(() {
        perguntaAtual = pergunta;
        tipoAtual = pergunta['tipo'] ?? 'multipla_escolha';
        _perguntaDoCache = pergunta['fonte_ia'] == null;
        carregando = false;
      });
    }

    debugPrint('Pergunta pré-carregada processada. Tipo: $tipoAtual');
    debugPrint('Conteúdo: ${pergunta['pergunta']}');

    _animationController.reset();
    _animationController.forward();
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  void _iniciarPreCarregamento() {
    if (_preCarregamentoAtivo || perguntaIndex >= totalPerguntas - 1) {
      return;
    }

    _preCarregamentoAtivo = true;
    debugPrint('Iniciando pré-carregamento de perguntas...');

    // Pré-carrega até 3 perguntas em background
    final perguntasParaCarregar = totalPerguntas - perguntaIndex - 1;
    final limite = perguntasParaCarregar > 3 ? 3 : perguntasParaCarregar;

    for (int i = 0; i < limite; i++) {
      _preCarregarPergunta();
    }
  }

  Future<void> _preCarregarPergunta() async {
    try {
      final tipo = _getTipoAtual();
      debugPrint('Pré-carregando pergunta tipo: $tipo');

      final dificuldadeAtual = await _getDificuldadeAtual();
      final pergunta = await QuizHelperService.gerarPerguntaInteligente(
        unidade: topico,
        ano: ano,
        tipoQuiz: tipo,
        dificuldade: dificuldadeAtual,
      );

      if (pergunta != null && mounted) {
        // Adiciona tipo à pergunta para uso posterior
        pergunta['tipo'] = tipo;
        _perguntasPreCarregadas.add(pergunta);
        debugPrint(
            'Pergunta pré-carregada adicionada. Total na fila: ${_perguntasPreCarregadas.length}');

        // Diminuir cobra quando pré-carregar pergunta
        _diminuirCobra();
      }
    } catch (e) {
      debugPrint('Erro ao pré-carregar pergunta: $e');
    } finally {
      _preCarregamentoAtivo = false;
    }
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
        acertou = respostaSelecionada == respostaCorreta;
        break;
      case 'verdadeiro_falso':
        acertou = respostaSelecionada == respostaCorreta;
        break;
      case 'complete_frase':
        final respostaUsuario = respostaSelecionada!.toLowerCase().trim();
        final respostaEsperada =
            respostaCorreta.toString().toLowerCase().trim();
        acertou = respostaUsuario == respostaEsperada;
        break;
    }

    if (acertou) {
      // Calcular bônus do personagem
      int bonusPontos = 0;
      if (_personagemSelecionado != null) {
        bonusPontos = (_personagemService.calcularBonusPontos(_personagemSelecionado!) * 10).round();
      }
      pontuacao += 10 + bonusPontos;
      estatisticas['corretas'] = estatisticas['corretas']! + 1;
    } else {
      estatisticas['incorretas'] = estatisticas['incorretas']! + 1;
    }

    // Registrar resposta no sistema de performance para ajustar dificuldade
    await PerformanceService.registrarResposta(
      acertou: acertou,
      dificuldade: _dificuldadeAdaptiva,
      tipoQuiz: tipoAtual,
    );

    // Salva a resposta
    respostas.add({
      'pergunta': perguntaAtual!['pergunta'],
      'tipo': tipoAtual,
      'resposta_usuario': respostaSelecionada,
      'resposta_correta': respostaCorreta,
      'acertou': acertou,
      'explicacao': perguntaAtual!['explicacao'] ?? '',
      'dificuldade_usada': _dificuldadeAdaptiva,
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
    // Limpa fila de perguntas pré-carregadas
    _perguntasPreCarregadas.clear();
    _preCarregamentoAtivo = false;

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

    // Adiciona indicador de perguntas pré-carregadas
    String preCarregadas = '';
    if (_perguntasPreCarregadas.isNotEmpty) {
      preCarregadas = ' • ${_perguntasPreCarregadas.length} prontas';
    }

    // Adiciona indicador de dificuldade adaptiva
    String dificuldadeInfo =
        ' • Dificuldade: ${_dificuldadeAdaptiva.toUpperCase()}';

    if (_useGemini) {
      return '$progresso • $nivel$dificuldadeInfo • IA: Gemini$preCarregadas';
    } else {
      return '$progresso • $nivel$dificuldadeInfo • IA: Ollama ($_modeloOllama)$preCarregadas';
    }
  }

  Widget _buildHeaderTrailing(bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StatusIndicator(
          text: 'Online',
          icon: Icons.wifi_rounded,
          color: AppTheme.successColor,
          isActive: true,
        ),
        const SizedBox(height: 4),
        // Indicador de perguntas pré-carregadas
        if (_perguntasPreCarregadas.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              border: Border.all(
                color: AppTheme.successColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flash_on,
                  size: isTablet ? 14 : 12,
                  color: AppTheme.successColor,
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Text(
                  '${_perguntasPreCarregadas.length} prontas',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 12 : 10,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_perguntaDoCache) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              border: Border.all(
                color: AppTheme.warningColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_bolt,
                  size: isTablet ? 14 : 12,
                  color: AppTheme.warningColor,
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Text(
                  'Cache',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 12 : 10,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 6 : 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy,
                  size: isTablet ? 14 : 12,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Text(
                  _useGemini ? 'Gemini' : 'Ollama',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 12 : 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
                const SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getDificuldadeColor(_dificuldadeAdaptiva)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: _getDificuldadeColor(_dificuldadeAdaptiva)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getDificuldadeIcon(_dificuldadeAdaptiva),
                        color: _getDificuldadeColor(_dificuldadeAdaptiva),
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        _dificuldadeAdaptiva.toUpperCase(),
                        style: AppTheme.bodySmall.copyWith(
                          color: _getDificuldadeColor(_dificuldadeAdaptiva),
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
                        '• 10 perguntas de tipos variados\n• IA gera conteúdo personalizado\n• Dificuldade adaptativa baseada na performance\n• Pré-carregamento para experiência fluida',
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

    // Iniciar jogo da cobrinha
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

    // Transicionar para o quiz
    if (mounted) {
      setState(() {
        _mostrarCarregamento = false;
        _gameRunning = false;
        _snakeController.stop();
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
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _snakeClickCount++;
                          if (_snakeClickCount >= 3) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => QuizSnakeScreen(
                                  topico: widget.topico,
                                  dificuldade: widget.dificuldade,
                                ),
                              ),
                            );
                          }
                        });
                      }
                    },
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
                    child: GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _snakeClickCount++;
                            if (_snakeClickCount >= 3) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => QuizSnakeScreen(
                                    topico: widget.topico,
                                    dificuldade: widget.dificuldade,
                                  ),
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.all(4), // Margem interna mínima
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
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.08),
                                    Colors.transparent,
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.04),
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
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
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
                    child: GestureDetector(
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            _snakeClickCount++;
                            if (_snakeClickCount >= 3) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => QuizSnakeScreen(
                                    topico: widget.topico,
                                    dificuldade: widget.dificuldade,
                                  ),
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.darkSurfaceColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
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
                            _gridSize =
                                30; // Grid fixo maior para telas grandes
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

            // Performance e Dificuldade Adaptiva
            _buildPerformanceCard(),

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
                          builder: (context) => QuizAlternadoScreen(
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
                    text: 'Voltar ao Início',
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _mostrarTelaInicial = true;
                          quizFinalizado = false;
                          perguntaIndex = 0;
                          pontuacao = 0;
                          respostas.clear();
                          estatisticas = {
                            'corretas': 0,
                            'incorretas': 0,
                            'multipla_escolha': 0,
                            'verdadeiro_falso': 0,
                            'complete_frase': 0,
                          };
                          _perguntasPreCarregadas.clear();
                          _preCarregamentoAtivo = false;
                          _gameRunning = false;
                          _snakeController.stop();
                        });
                      }
                    },
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

  Color _getDificuldadeColor(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
        return AppTheme.successColor;
      case 'médio':
        return AppTheme.warningColor;
      case 'difícil':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getDificuldadeIcon(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
        return Icons.sentiment_satisfied;
      case 'médio':
        return Icons.sentiment_neutral;
      case 'difícil':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildPerformanceCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: PerformanceService.obterEstatisticas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorderColor),
            ),
            child: const LoadingWidget(),
          );
        }

        final stats = snapshot.data!;
        final taxaAcertoGeral = stats['taxa_acerto_geral'] ?? 0.0;
        final taxaAcertoRecente = stats['taxa_acerto_recente'] ?? 0.0;
        final sequenciaAcertos = stats['sequencia_acertos'] ?? 0;
        final sequenciaErros = stats['sequencia_erros'] ?? 0;
        final dificuldadeAtual = stats['dificuldade_atual'] ?? 'fácil';

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Performance Adaptiva',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Taxa de acerto geral
              _buildPerformanceItem(
                'Taxa de Acerto Geral',
                '${taxaAcertoGeral.toStringAsFixed(1)}%',
                Icons.analytics,
                _getPerformanceColor(taxaAcertoGeral),
              ),

              // Taxa de acerto recente
              _buildPerformanceItem(
                'Performance Recente',
                '${taxaAcertoRecente.toStringAsFixed(1)}%',
                Icons.timeline,
                _getPerformanceColor(taxaAcertoRecente),
              ),

              // Sequência atual
              if (sequenciaAcertos > 0)
                _buildPerformanceItem(
                  'Sequência de Acertos',
                  '$sequenciaAcertos',
                  Icons.local_fire_department,
                  AppTheme.successColor,
                )
              else if (sequenciaErros > 0)
                _buildPerformanceItem(
                  'Sequência de Erros',
                  '$sequenciaErros',
                  Icons.warning,
                  AppTheme.errorColor,
                ),

              Divider(color: AppTheme.darkBorderColor, height: 32),

              // Dificuldade atual
              Row(
                children: [
                  Icon(
                    _getDificuldadeIcon(dificuldadeAtual),
                    color: _getDificuldadeColor(dificuldadeAtual),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dificuldade Atual',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getDificuldadeColor(dificuldadeAtual)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getDificuldadeColor(dificuldadeAtual)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      dificuldadeAtual.toUpperCase(),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getDificuldadeColor(dificuldadeAtual),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                'A dificuldade se ajusta automaticamente baseada na sua performance para otimizar o aprendizado.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceItem(
      String titulo, String valor, IconData icon, Color cor) {
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
            valor,
            style: AppTheme.bodyMedium.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(double taxa) {
    if (taxa >= 70) return AppTheme.successColor;
    if (taxa >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
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
