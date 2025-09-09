import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../services/ia_service.dart';
import '../services/quiz_helper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late MathTutorService tutorService;

  // Estado do Quiz
  Map<String, dynamic>? perguntaAtual;
  String tipoAtual = '';
  int perguntaIndex = 0;
  int totalPerguntas = 10;
  String? respostaSelecionada;
  bool carregando = false;
  bool quizFinalizado = false;
  bool _useGemini = true;
  String _modeloOllama = 'llama2';
  bool _perguntaDoCache = false;
  final TextEditingController _respostaController = TextEditingController();

  // Tipos de quiz disponíveis
  final List<String> _tiposQuiz = [
    'multipla_escolha',
    'verdadeiro_falso',
    'complete_frase'
  ];

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

  // Configurações visuais
  String ano = '1º ano';
  String topico = 'números e operações';
  String dificuldade = 'fácil';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPreferences();
    _initializeQuiz();
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

    _animationController.forward();
    _cardAnimationController.forward();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
    final modeloOllama = prefs.getString('modelo_ollama') ?? 'llama2';

    if (mounted) {
      setState(() {
        _useGemini = selectedAI == 'gemini';
        _modeloOllama = modeloOllama;
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

    AIService aiService;
    if (_useGemini) {
      aiService = GeminiService(apiKey: apiKey!);
    } else {
      aiService = OllamaService(defaultModel: _modeloOllama);
    }

    tutorService = MathTutorService(aiService: aiService);
    await _gerarPergunta();
  }

  String _getTipoAleatorio() {
    final random = Random();
    return _tiposQuiz[random.nextInt(_tiposQuiz.length)];
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
      // Escolhe tipo aleatório para esta pergunta
      tipoAtual = _getTipoAleatorio();

      debugPrint('Gerando pergunta tipo: $tipoAtual');
      debugPrint('Tópico: $topico, Dificuldade: $dificuldade, Ano: $ano');

      // Usa o QuizHelperService que verifica cache primeiro
      final pergunta = await QuizHelperService.gerarPerguntaInteligente(
        unidade: topico,
        ano: ano,
        tipoQuiz: tipoAtual,
        dificuldade: dificuldade,
      );

      if (pergunta != null) {
        debugPrint('Pergunta obtida (cache ou IA): ${pergunta['pergunta']}');
        _processarPerguntaCache(pergunta);
      } else {
        // Fallback para geração offline se disponível
        await _gerarPerguntaOffline();
      }
    } catch (e) {
      debugPrint('Erro ao gerar pergunta: $e');
      await _gerarPerguntaOffline();
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

  Future<void> _gerarPerguntaOffline() async {
    // Fallback simples para quando não há IA disponível
    Map<String, dynamic> pergunta;

    switch (tipoAtual) {
      case 'multipla_escolha':
        pergunta = {
          'pergunta': 'Quanto é 2 + 2?',
          'opcoes': ['3', '4', '5', '6'],
          'resposta_correta': 'B',
          'explicacao': '2 + 2 = 4, que corresponde à opção B.',
        };
        break;

      case 'verdadeiro_falso':
        pergunta = {
          'pergunta': '3 + 3 = 6',
          'resposta_correta': 'Verdadeiro',
          'explicacao': '3 + 3 realmente é igual a 6.',
        };
        break;

      case 'complete_frase':
        pergunta = {
          'pergunta': 'Complete: 5 + 3 = ___',
          'resposta_correta': '8',
          'explicacao': '5 + 3 = 8',
        };
        break;

      default:
        pergunta = {
          'pergunta': 'Erro na geração da pergunta',
          'opcoes': ['Erro'],
          'resposta_correta': 'A',
          'explicacao': 'Houve um erro.',
        };
    }

    if (mounted) {
      setState(() {
        perguntaAtual = pergunta;
        _perguntaDoCache = false;
      });
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

    // Próxima pergunta
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

    if (_useGemini) {
      return '$progresso • $nivel • IA: Gemini';
    } else {
      return '$progresso • $nivel • IA: Ollama ($_modeloOllama)';
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
        if (_perguntaDoCache) ...[
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

  @override
  void dispose() {
    _respostaController.removeListener(_onRespostaChanged);
    _animationController.dispose();
    _progressController.dispose();
    _cardAnimationController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

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
