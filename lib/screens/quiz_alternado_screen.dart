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
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _progressAnimation;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
    final modeloOllama = prefs.getString('modelo_ollama') ?? 'llama2';

    setState(() {
      _useGemini = selectedAI == 'gemini';
      _modeloOllama = modeloOllama;
      topico = widget.topico ?? 'números e operações';
      dificuldade = widget.dificuldade ?? 'fácil';
    });
  }

  Future<void> _initializeQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    if (_useGemini && (apiKey == null || apiKey.isEmpty)) {
      setState(() {
        carregando = false;
      });
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

    setState(() {
      carregando = true;
      perguntaAtual = null;
      respostaSelecionada = null;
      _respostaController.clear();
    });

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

    setState(() {
      carregando = false;
    });

    _animationController.reset();
    _animationController.forward();
  }

  void _processarPerguntaCache(Map<String, dynamic> pergunta) {
    setState(() {
      perguntaAtual = pergunta;
      _perguntaDoCache = pergunta['fonte_ia'] == null;
    });

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

    setState(() {
      perguntaAtual = pergunta;
      _perguntaDoCache = false;
    });
  }

  Widget _buildPerguntaWidget() {
    if (perguntaAtual == null) return Container();

    switch (tipoAtual) {
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

  Widget _buildMultiplaEscolha() {
    final opcoes = perguntaAtual!['opcoes'] as List<String>? ?? [];

    return Column(
      children: [
        _buildTipoBadge('Múltipla Escolha', Icons.quiz, AppTheme.primaryColor),
        const SizedBox(height: 24),
        _buildPerguntaCard(),
        const SizedBox(height: 24),
        ...opcoes.asMap().entries.map((entry) {
          final index = entry.key;
          final opcao = entry.value;
          final letra = String.fromCharCode(65 + index); // A, B, C, D
          final isSelected = respostaSelecionada == letra;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildOpcaoButton(letra, opcao, isSelected),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildVerdadeiroFalso() {
    return Column(
      children: [
        _buildTipoBadge(
            'Verdadeiro ou Falso', Icons.check_circle, AppTheme.successColor),
        const SizedBox(height: 24),
        _buildPerguntaCard(),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildOpcaoButton(
                'V',
                'Verdadeiro',
                respostaSelecionada == 'Verdadeiro',
                isVerdadeiroFalso: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOpcaoButton(
                'F',
                'Falso',
                respostaSelecionada == 'Falso',
                isVerdadeiroFalso: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteFrase() {
    return Column(
      children: [
        _buildTipoBadge('Complete a Frase', Icons.edit, AppTheme.warningColor),
        const SizedBox(height: 24),
        _buildPerguntaCard(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite sua resposta:',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _respostaController,
                decoration: InputDecoration(
                  hintText: 'Sua resposta...',
                  hintStyle: TextStyle(color: AppTheme.darkTextSecondaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.darkBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.darkBackgroundColor,
                ),
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                ),
                onChanged: (value) {
                  setState(() {
                    respostaSelecionada = value.trim();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipoBadge(String titulo, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cor, size: 16),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: AppTheme.bodySmall.copyWith(
              color: cor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerguntaCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          perguntaAtual!['pergunta'] ?? '',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.darkTextPrimaryColor,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (_perguntaDoCache)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  AppTheme.successColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                size: 12,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cache',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOpcaoButton(String letra, String texto, bool isSelected,
      {bool isVerdadeiroFalso = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ModernButton(
        text: isVerdadeiroFalso ? texto : '$letra) $texto',
        onPressed: () {
          setState(() {
            if (isVerdadeiroFalso) {
              respostaSelecionada = texto;
            } else {
              respostaSelecionada = letra;
            }
          });
        },
        isPrimary: isSelected,
        isFullWidth: true,
        icon: isSelected ? Icons.check_circle : null,
      ),
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

    setState(() {
      perguntaIndex++;
    });

    // Atualiza progresso
    _progressController.animateTo(perguntaIndex / totalPerguntas);

    // Mostra explicação se errou
    if (!acertou) {
      await _mostrarExplicacao();
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
    setState(() {
      quizFinalizado = true;
    });
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

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
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
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.darkTextPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quiz Alternado',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${perguntaIndex + 1}/$totalPerguntas',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progresso
          Container(
            height: 6,
            margin: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: AppTheme.darkBorderColor,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                );
              },
            ),
          ),

          // Conteúdo principal
          Expanded(
            child: carregando
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gerando pergunta...',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    child: _buildPerguntaWidget(),
                  ),
          ),

          // Botão para próxima pergunta
          if (!carregando && perguntaAtual != null)
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
              child: SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: perguntaIndex < totalPerguntas - 1
                      ? 'Próxima Pergunta'
                      : 'Finalizar Quiz',
                  onPressed: respostaSelecionada != null &&
                          respostaSelecionada!.isNotEmpty
                      ? _proximaPergunta
                      : null,
                  isPrimary: true,
                  icon: perguntaIndex < totalPerguntas - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                ),
              ),
            ),
        ],
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
