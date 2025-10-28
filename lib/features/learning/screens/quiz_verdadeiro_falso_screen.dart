import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/modern_components.dart';
import '../../core/widgets/mixins.dart';
import '../../ai/services/explicacao_service.dart';
import '../services/quiz_helper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuizVerdadeiroFalsoScreen extends StatefulWidget {
  final bool isOfflineMode;
  final String? topico;
  final String? dificuldade;

  const QuizVerdadeiroFalsoScreen({
    super.key,
    this.isOfflineMode = false,
    this.topico,
    this.dificuldade,
  });

  @override
  State<QuizVerdadeiroFalsoScreen> createState() =>
      _QuizVerdadeiroFalsoScreenState();
}

class _QuizVerdadeiroFalsoScreenState extends State<QuizVerdadeiroFalsoScreen>
    with TickerProviderStateMixin, QuizStateMixin, AnimationMixin {
  // Estado específico do Quiz Verdadeiro/Falso
  int totalPerguntas = 10;
  bool? respostaSelecionada; // true para Verdadeiro, false para Falso
  bool _perguntaDoCache = false;

  // Resultados específicos
  List<Map<String, dynamic>> respostas = [];
  int pontuacao = 0;
  Map<String, int> estatisticasEspecificas = {
    'corretas': 0,
    'incorretas': 0,
    'tempo_total': 0,
  };

  // Controle de tempo
  late DateTime _inicioQuiz;
  late DateTime _inicioPergunta;

  // Animações
  late AnimationController _cardAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _progressAnimation;

  // Perguntas offline de exemplo
  final List<Map<String, dynamic>> perguntasOffline = [
    {
      'pergunta':
          'A soma de dois números pares sempre resulta em um número par.',
      'resposta_correta': true,
      'explicacao':
          'Verdadeiro. A soma de dois números pares (2n + 2m) = 2(n + m), que é sempre par.',
      'topico': 'Números Pares e Ímpares',
      'dificuldade': 'fácil'
    },
    {
      'pergunta': 'O resultado de 5 × 6 é igual a 35.',
      'resposta_correta': false,
      'explicacao': 'Falso. 5 × 6 = 30, não 35.',
      'topico': 'Multiplicação',
      'dificuldade': 'fácil'
    },
    {
      'pergunta': 'Um triângulo pode ter dois ângulos retos.',
      'resposta_correta': false,
      'explicacao':
          'Falso. A soma dos ângulos internos de um triângulo é 180°. Dois ângulos retos já somariam 180°.',
      'topico': 'Geometria',
      'dificuldade': 'médio'
    },
    {
      'pergunta': '0,5 é equivalente a 50%.',
      'resposta_correta': true,
      'explicacao': 'Verdadeiro. 0,5 = 5/10 = 50/100 = 50%.',
      'topico': 'Porcentagem',
      'dificuldade': 'fácil'
    },
    {
      'pergunta': 'A raiz quadrada de 16 é 4.',
      'resposta_correta': true,
      'explicacao': 'Verdadeiro. √16 = 4, pois 4 × 4 = 16.',
      'topico': 'Raízes',
      'dificuldade': 'fácil'
    },
    {
      'pergunta': 'Todo número primo é ímpar.',
      'resposta_correta': false,
      'explicacao': 'Falso. O número 2 é primo e é par.',
      'topico': 'Números Primos',
      'dificuldade': 'médio'
    },
    {
      'pergunta': 'A área de um círculo com raio 3 é 9π.',
      'resposta_correta': true,
      'explicacao': 'Verdadeiro. Área = π × r² = π × 3² = 9π.',
      'topico': 'Geometria',
      'dificuldade': 'médio'
    },
    {
      'pergunta': 'Se x = 5, então 2x + 3 = 13.',
      'resposta_correta': true,
      'explicacao': 'Verdadeiro. 2(5) + 3 = 10 + 3 = 13.',
      'topico': 'Álgebra',
      'dificuldade': 'fácil'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeQuiz();
    _inicioQuiz = DateTime.now();
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeQuiz() async {
    await _carregarPreferencias();
    await _carregarProximaPergunta();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
    final modeloOllamaPrefs = prefs.getString('modelo_ollama') ?? 'llama2';
    setState(() {
      useGemini = selectedAI == 'gemini';
      modeloOllama = modeloOllamaPrefs;
    });
  }

  Future<void> _carregarProximaPergunta() async {
    if (perguntaIndex >= totalPerguntas) {
      _finalizarQuiz();
      return;
    }

    setState(() {
      carregando = true;
      respostaSelecionada = null;
    });

    _inicioPergunta = DateTime.now();

    // Sempre usa o sistema de cache/IA, sem modo offline
    await _gerarPerguntaComIA();

    _cardAnimationController.reset();
    _cardAnimationController.forward();

    // Atualizar progresso
    final progress = (perguntaIndex + 1) / totalPerguntas;
    _progressAnimationController.animateTo(progress);

    setState(() => carregando = false);
  }

  Future<void> _gerarPerguntaComIA() async {
    try {
      final topico = widget.topico ?? 'números e operações';
      final dificuldade = widget.dificuldade ?? 'médio';
      const ano = '1º ano'; // Você pode adaptar isso baseado no contexto

      debugPrint('Iniciando geração de pergunta V/F inteligente...');
      debugPrint('Tópico: $topico, Dificuldade: $dificuldade, Ano: $ano');

      // Usa o QuizHelperService que verifica cache primeiro
      final pergunta = await QuizHelperService.gerarPerguntaInteligente(
        unidade: topico,
        ano: ano,
        tipoQuiz: 'verdadeiro_falso',
        dificuldade: dificuldade,
      );

      if (pergunta != null) {
        debugPrint(
            'Pergunta V/F obtida (cache ou IA): ${pergunta['pergunta']}');
        _processarPerguntaCache(pergunta);
      } else {
        // Mostra erro se não conseguir obter pergunta
        debugPrint('Erro: Não foi possível obter pergunta V/F');
        _mostrarErroSemPergunta();
      }
    } catch (e) {
      // Mostra erro em caso de falha
      debugPrint('Erro ao gerar pergunta V/F: $e');
      _mostrarErroSemPergunta();
    }
  }

  void _processarPerguntaCache(Map<String, dynamic> pergunta) {
    try {
      // Verifica se a pergunta veio do cache ou foi gerada na hora
      final fonteIA = pergunta['fonte_ia'];
      _perguntaDoCache = fonteIA == null || fonteIA == 'cache';

      // Para V/F, a resposta correta pode estar como "VERDADEIRO"/"FALSO" ou boolean
      bool respostaCorreta = true;
      final resposta = pergunta['resposta_correta'];
      if (resposta is String) {
        respostaCorreta = resposta.toUpperCase().contains('VERDADEIRO') ||
            resposta.toUpperCase().contains('TRUE');
      } else if (resposta is bool) {
        respostaCorreta = resposta;
      }

      setState(() {
        perguntaAtual = {
          'pergunta': pergunta['pergunta'] ?? 'Pergunta não encontrada',
          'resposta_correta': respostaCorreta,
          'explicacao': pergunta['explicacao'] ?? 'Explicação não disponível',
          'numero': perguntaIndex + 1,
          'fonte': fonteIA ?? 'Cache', // Identifica se veio do cache
        };
        carregando = false;
      });
      debugPrint(
          'Pergunta V/F processada com sucesso - Fonte: ${_perguntaDoCache ? "Cache" : fonteIA}');
    } catch (e) {
      debugPrint('Erro ao processar pergunta V/F do cache: $e');
      _mostrarErroSemPergunta();
    }
  }

  void _mostrarErroSemPergunta() {
    setState(() {
      perguntaAtual = {
        'pergunta':
            'Erro: Não foi possível carregar a pergunta.\n\nVerifique se:\n• A IA está configurada\n• Há perguntas precarregadas\n• A conexão está funcionando',
        'resposta_correta': true,
        'explicacao':
            'Configure a IA ou execute o precarregamento nas configurações',
        'numero': perguntaIndex + 1,
        'fonte': 'Erro',
      };
      carregando = false;
    });
  }

  void _selecionarResposta(bool resposta) {
    setState(() {
      respostaSelecionada = resposta;
    });
  }

  Future<void> _confirmarResposta() async {
    if (respostaSelecionada == null || perguntaAtual == null) return;

    final tempoResposta = DateTime.now().difference(_inicioPergunta).inSeconds;
    final isCorreta = respostaSelecionada == perguntaAtual!['resposta_correta'];

    // Registrar resposta
    respostas.add({
      'pergunta': perguntaAtual!['pergunta'],
      'resposta_selecionada': respostaSelecionada,
      'resposta_correta': perguntaAtual!['resposta_correta'],
      'correta': isCorreta,
      'explicacao': perguntaAtual!['explicacao'],
      'tempo_resposta': tempoResposta,
      'topico': perguntaAtual!['topico'],
    });

    // Atualizar estatísticas
    if (isCorreta) {
      estatisticas['corretas'] = estatisticas['corretas']! + 1;
      pontuacao += _calcularPontos(tempoResposta);
    } else {
      estatisticas['incorretas'] = estatisticas['incorretas']! + 1;

      // Salvar explicação no histórico quando a resposta está errada
      await ExplicacaoService.salvarExplicacao(
        unidade: perguntaAtual!['topico'] ?? 'Geral',
        ano: 'Não especificado',
        pergunta: perguntaAtual!['pergunta'],
        respostaUsuario: respostaSelecionada! ? 'Verdadeiro' : 'Falso',
        respostaCorreta:
            perguntaAtual!['resposta_correta'] ? 'Verdadeiro' : 'Falso',
        explicacao: perguntaAtual!['explicacao'] ?? 'Explicação não disponível',
        topicoEspecifico: perguntaAtual!['topico'] ?? 'Quiz Verdadeiro/Falso',
      );
    }

    // Mostrar feedback
    await _mostrarFeedback(isCorreta);

    // Próxima pergunta
    perguntaIndex++;
    await Future.delayed(const Duration(milliseconds: 1500));
    await _carregarProximaPergunta();
  }

  int _calcularPontos(int tempoSegundos) {
    // Sistema de pontuação baseado no tempo
    if (tempoSegundos <= 3) return 100;
    if (tempoSegundos <= 6) return 80;
    if (tempoSegundos <= 10) return 60;
    if (tempoSegundos <= 20) return 40;
    return 20;
  }

  Future<void> _mostrarFeedback(bool isCorreta) async {
    // Mostrar explicação em dialog quando a resposta estiver incorreta
    if (!isCorreta &&
        perguntaAtual != null &&
        perguntaAtual!['explicacao'] != null) {
      await _mostrarExplicacaoDialog(perguntaAtual!['explicacao']);
    }

    // Mostrar feedback visual temporário
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isCorreta ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isCorreta ? 'Resposta correta!' : 'Resposta incorreta',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor:
              isCorreta ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Aguardar um momento para mostrar o feedback
    await Future.delayed(const Duration(milliseconds: 1000));
  }

  Future<void> _mostrarExplicacaoDialog(String explicacao) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.warningColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Explicação',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
            ],
          ),
          content: Text(
            explicacao,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Entendi',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _finalizarQuiz() {
    final tempoTotal = DateTime.now().difference(_inicioQuiz).inMinutes;
    estatisticas['tempo_total'] = tempoTotal;

    setState(() {
      quizFinalizado = true;
    });

    _salvarResultados();
  }

  Future<void> _salvarResultados() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar histórico existente
    final historicoJson = prefs.getString('historico_quiz_vf');
    List<Map<String, dynamic>> historico = [];

    if (historicoJson != null) {
      final List<dynamic> decoded = jsonDecode(historicoJson);
      historico = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Adicionar resultado atual
    historico.add({
      'data': DateTime.now().toIso8601String(),
      'topico': widget.topico ?? 'Geral',
      'dificuldade': widget.dificuldade ?? 'médio',
      'total_perguntas': totalPerguntas,
      'corretas': estatisticas['corretas'],
      'incorretas': estatisticas['incorretas'],
      'pontuacao': pontuacao,
      'tempo_total': estatisticas['tempo_total'],
      'taxa_acerto': (estatisticas['corretas']! / totalPerguntas * 100).round(),
      'tipo': 'verdadeiro_falso',
    });

    // Manter apenas os últimos 50 resultados
    if (historico.length > 50) {
      historico = historico.sublist(historico.length - 50);
    }

    await prefs.setString('historico_quiz_vf', jsonEncode(historico));
  }

  void _reiniciarQuiz() {
    setState(() {
      perguntaIndex = 0;
      quizFinalizado = false;
      respostas.clear();
      pontuacao = 0;
      estatisticas = {'corretas': 0, 'incorretas': 0, 'tempo_total': 0};
      perguntaAtual = null;
      respostaSelecionada = null;
    });

    _inicioQuiz = DateTime.now();
    _progressAnimationController.reset();
    _carregarProximaPergunta();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (quizFinalizado) {
      return _buildResultadosScreen(isTablet, isDesktop);
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
              ResponsiveHeader(
                title: 'Quiz Verdadeiro/Falso',
                subtitle: _buildSubtitle(),
                showBackButton: true,
                trailing: _buildHeaderInfo(isTablet),
              ),

              // Barra de progresso
              _buildProgressBar(isTablet),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isTablet ? 30 : 20),

                      // Card da pergunta
                      if (carregando)
                        _buildLoadingCard(isTablet)
                      else if (perguntaAtual != null)
                        _buildPerguntaCard(isTablet),

                      SizedBox(height: isTablet ? 30 : 20),

                      // Botões Verdadeiro/Falso
                      if (!carregando && perguntaAtual != null)
                        _buildOpcoesVerdadeiroFalso(isTablet),

                      SizedBox(height: isTablet ? 30 : 20),

                      // Botão confirmar resposta
                      if (!carregando && perguntaAtual != null)
                        _buildConfirmarButton(isTablet),

                      SizedBox(height: isTablet ? 20 : 16),
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

  String _buildSubtitle() {
    String nivel = 'Nível: ${widget.dificuldade?.toUpperCase() ?? 'MÉDIO'}';

    if (widget.isOfflineMode) {
      return nivel;
    }

    if (useGemini) {
      return '$nivel • IA: Gemini';
    } else {
      return '$nivel • IA: Ollama ($modeloOllama)';
    }
  }

  Widget _buildHeaderInfo(bool isTablet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
          ),
          child: Text(
            '${perguntaIndex + 1}/$totalPerguntas',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 8,
            vertical: isTablet ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
          ),
          child: Text(
            'Pontos: $pontuacao',
            style: TextStyle(
              color: AppTheme.successColor,
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!widget.isOfflineMode) ...[
          const SizedBox(height: 4),
          if (_perguntaDoCache) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 8,
                vertical: isTablet ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cached,
                    size: isTablet ? 14 : 12,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cache',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w600,
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
                color: AppTheme.infoColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: Text(
                useGemini ? 'Gemini' : 'Ollama: $modeloOllama',
                style: TextStyle(
                  color: AppTheme.infoColor,
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildProgressBar(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 20,
        vertical: isTablet ? 20 : 16,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso do Quiz',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${((perguntaIndex / totalPerguntas) * 100).round()}%',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: AppTheme.darkBorderColor,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: isTablet ? 8 : 6,
              );
            },
          ),
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
            widget.isOfflineMode
                ? 'Carregando próxima pergunta...'
                : 'IA gerando pergunta personalizada...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerguntaCard(bool isTablet) {
    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: ModernCard(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header da pergunta
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        color: AppTheme.primaryColor,
                        size: isTablet ? 20 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        'Questão ${perguntaAtual!['numero']}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (perguntaAtual!['topico'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                    ),
                    child: Text(
                      perguntaAtual!['topico'],
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Pergunta
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: AppTheme.darkBorderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: AppTheme.primaryColor,
                    size: isTablet ? 32 : 28,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      perguntaAtual!['pergunta'],
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcoesVerdadeiroFalso(bool isTablet) {
    return Row(
      children: [
        // Botão Verdadeiro
        Expanded(
          child: InkWell(
            onTap: () => _selecionarResposta(true),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: respostaSelecionada == true
                    ? AppTheme.successColor.withValues(alpha: 0.2)
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                border: Border.all(
                  color: respostaSelecionada == true
                      ? AppTheme.successColor
                      : AppTheme.darkBorderColor,
                  width: respostaSelecionada == true ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      color: respostaSelecionada == true
                          ? AppTheme.successColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: respostaSelecionada == true
                            ? AppTheme.successColor
                            : AppTheme.darkBorderColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: respostaSelecionada == true
                          ? Colors.white
                          : AppTheme.successColor,
                      size: isTablet ? 32 : 28,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Text(
                    'VERDADEIRO',
                    style: AppTheme.bodyLarge.copyWith(
                      color: respostaSelecionada == true
                          ? AppTheme.successColor
                          : AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(width: isTablet ? 20 : 16),

        // Botão Falso
        Expanded(
          child: InkWell(
            onTap: () => _selecionarResposta(false),
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: respostaSelecionada == false
                    ? AppTheme.errorColor.withValues(alpha: 0.2)
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                border: Border.all(
                  color: respostaSelecionada == false
                      ? AppTheme.errorColor
                      : AppTheme.darkBorderColor,
                  width: respostaSelecionada == false ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      color: respostaSelecionada == false
                          ? AppTheme.errorColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: respostaSelecionada == false
                            ? AppTheme.errorColor
                            : AppTheme.darkBorderColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: respostaSelecionada == false
                          ? Colors.white
                          : AppTheme.errorColor,
                      size: isTablet ? 32 : 28,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  Text(
                    'FALSO',
                    style: AppTheme.bodyLarge.copyWith(
                      color: respostaSelecionada == false
                          ? AppTheme.errorColor
                          : AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmarButton(bool isTablet) {
    final isEnabled = respostaSelecionada != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ModernButton(
        text: 'Confirmar Resposta',
        icon: Icons.check_rounded,
        onPressed: isEnabled ? _confirmarResposta : null,
        isPrimary: true,
        isFullWidth: true,
      ),
    );
  }

  Widget _buildResultadosScreen(bool isTablet, bool isDesktop) {
    final taxaAcerto =
        (estatisticas['corretas']! / totalPerguntas * 100).round();
    final performance = _getPerformanceMessage(taxaAcerto);

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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
              vertical: isTablet ? 30 : 20,
            ),
            child: Column(
              children: [
                // Header de resultados
                Container(
                  padding: EdgeInsets.all(isTablet ? 30 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryLightColor
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: isTablet ? 64 : 48,
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Text(
                        'Quiz Finalizado!',
                        style: AppTheme.headingLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        performance['message'] ?? 'Parabéns!',
                        style: AppTheme.bodyLarge.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 30 : 24),

                // Estatísticas
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Acertos',
                        '${estatisticas['corretas']}/$totalPerguntas',
                        Icons.check_circle_rounded,
                        AppTheme.successColor,
                        isTablet,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: _buildStatCard(
                        'Taxa',
                        '$taxaAcerto%',
                        Icons.trending_up_rounded,
                        AppTheme.primaryColor,
                        isTablet,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Pontuação',
                        '$pontuacao',
                        Icons.stars_rounded,
                        AppTheme.warningColor,
                        isTablet,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: _buildStatCard(
                        'Tempo',
                        '${estatisticas['tempo_total']} min',
                        Icons.timer_rounded,
                        AppTheme.infoColor,
                        isTablet,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 30 : 24),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: ModernButton(
                        text: 'Fazer Novamente',
                        icon: Icons.refresh_rounded,
                        onPressed: _reiniciarQuiz,
                        isPrimary: true,
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: ModernButton(
                        text: 'Ver Respostas',
                        icon: Icons.list_rounded,
                        onPressed: () => _mostrarRevisao(context, isTablet),
                        isPrimary: false,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 16 : 12),

                ModernButton(
                  text: 'Voltar ao Menu',
                  icon: Icons.home_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: false,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String titulo, String valor, IconData icon, Color cor, bool isTablet) {
    return ModernCard(
      child: Column(
        children: [
          Container(
            width: isTablet ? 56 : 48,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: cor,
              size: isTablet ? 28 : 24,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            valor,
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            titulo,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getPerformanceMessage(int taxa) {
    if (taxa >= 90) {
      return {
        'message': 'Excelente! Você domina o assunto!',
        'emoji': '🏆',
      };
    } else if (taxa >= 70) {
      return {
        'message': 'Muito bem! Bom desempenho!',
        'emoji': '👏',
      };
    } else if (taxa >= 50) {
      return {
        'message': 'Bom trabalho! Continue praticando!',
        'emoji': '👍',
      };
    } else {
      return {
        'message': 'Continue estudando! Você vai melhorar!',
        'emoji': '💪',
      };
    }
  }

  void _mostrarRevisao(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isTablet ? 700 : double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 20),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              border: Border.all(
                color: AppTheme.darkBorderColor,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isTablet ? 20 : 16),
                      topRight: Radius.circular(isTablet ? 20 : 16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_rounded,
                        color: AppTheme.primaryColor,
                        size: isTablet ? 24 : 20,
                      ),
                      SizedBox(width: isTablet ? 12 : 8),
                      Expanded(
                        child: Text(
                          'Revisão das Respostas',
                          style: AppTheme.headingSmall.copyWith(
                            color: AppTheme.darkTextPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de respostas
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    itemCount: respostas.length,
                    itemBuilder: (context, index) {
                      final resposta = respostas[index];
                      final isCorreta = resposta['correta'];

                      return Container(
                        margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBackgroundColor,
                          borderRadius:
                              BorderRadius.circular(isTablet ? 16 : 12),
                          border: Border.all(
                            color: isCorreta
                                ? AppTheme.successColor.withValues(alpha: 0.3)
                                : AppTheme.errorColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 12 : 8,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCorreta
                                        ? AppTheme.successColor
                                            .withValues(alpha: 0.2)
                                        : AppTheme.errorColor
                                            .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(isTablet ? 8 : 6),
                                  ),
                                  child: Text(
                                    'Questão ${index + 1}',
                                    style: TextStyle(
                                      color: isCorreta
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                      fontSize: isTablet ? 12 : 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  isCorreta
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: isCorreta
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                  size: isTablet ? 20 : 18,
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Text(
                              resposta['pergunta'],
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.darkTextPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isTablet ? 8 : 6),
                            Text(
                              'Sua resposta: ${resposta['resposta_selecionada'] ? "VERDADEIRO" : "FALSO"}',
                              style: AppTheme.bodySmall.copyWith(
                                color: isCorreta
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                            ),
                            if (!isCorreta) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Resposta correta: ${resposta['resposta_correta'] ? "VERDADEIRO" : "FALSO"}',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                            if (resposta['explicacao'] != null) ...[
                              SizedBox(height: isTablet ? 8 : 6),
                              Text(
                                resposta['explicacao'],
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.darkTextSecondaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
