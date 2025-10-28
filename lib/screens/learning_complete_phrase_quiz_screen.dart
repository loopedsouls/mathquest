import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/ai_explanation_service.dart';
import '../services/ai_firebase_ai_service.dart';
import '../services/learning_quiz_helper_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../widgets/core_mixins_widget.dart';
import '../widgets/core_modern_components_widget.dart';

class QuizCompleteAFraseScreen extends StatefulWidget {
  final String? topico;
  final String? dificuldade;

  const QuizCompleteAFraseScreen({
    super.key,
    this.topico,
    this.dificuldade,
  });

  @override
  State<QuizCompleteAFraseScreen> createState() =>
      _QuizCompleteAFraseScreenState();
}

class _QuizCompleteAFraseScreenState extends State<QuizCompleteAFraseScreen>
    with TickerProviderStateMixin, QuizStateMixin, AnimationMixin {
  final TextEditingController _respostaController = TextEditingController();

  // Estado específico do Quiz Complete a Frase
  String pergunta = '';
  String explicacao = '';
  String feedback = '';
  bool? _respostaCorreta;
  List<Map<String, String>> historico = [];
  int _nivelDificuldade = 1;
  final List<String> _niveis = ['fácil', 'médio', 'difícil', 'expert'];
  bool _perguntaDoCache = false;
  Map<String, dynamic>? _exercicioAtual;
  int _exerciciosRespondidos = 0;
  bool _mostrarEstatisticas = false;
  String? _respostaSelecionada;
  bool _carregandoAjuda = false;
  String _ajudaIA = '';

  // Animações específicas
  late AnimationController _cardAnimationController;
  late AnimationController _feedbackAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _feedbackFadeAnimation;
  late Animation<Offset> _feedbackSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTutoria();
    _respostaController.addListener(() {
      setState(() {});
    });
  }

  void _initializeAnimations() {
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _feedbackAnimationController = AnimationController(
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

    _feedbackFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeInOut,
    ));

    _feedbackSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _feedbackAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _initializeTutoria() async {
    await _carregarPreferencias();
    await _carregarHistorico();
    await _carregarProximoExercicio();
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

  Future<void> _carregarProximoExercicio() async {
    await gerarNovaPergunta();
  }

  Future<void> gerarNovaPergunta() async {
    setState(() {
      carregando = true;
      pergunta = '';
      explicacao = '';
      feedback = '';
      _respostaCorreta = null;
      _respostaController.clear();
      _respostaSelecionada = null;
    });

    try {
      // Primeiro tenta usar o cache inteligente
      final dificuldade = _niveis[_nivelDificuldade];
      final perguntaCache = await QuizHelperService.gerarPerguntaInteligente(
        unidade: 'números e operações',
        ano: '1º ano',
        tipoQuiz: 'complete_frase',
        dificuldade: dificuldade,
      );

      if (perguntaCache != null) {
        pergunta = perguntaCache['pergunta'] ?? '';
        // Verifica se veio do cache
        final fonteIA = perguntaCache['fonte_ia'];
        _perguntaDoCache = fonteIA == null || fonteIA == 'cache';
        debugPrint(
            'Pergunta complete-a-frase obtida do ${_perguntaDoCache ? "cache" : fonteIA}: $pergunta');
      } else {
        // Se não conseguiu gerar pergunta, mostra erro
        _mostrarErroSemPergunta();
      }

      // Após gerar a pergunta, solicitar que a IA armazene a resposta na memória
      if (pergunta.isNotEmpty && !pergunta.contains('Erro')) {
        await _armazenarRespostaNaMemoriaIA(pergunta);
      }
    } catch (e) {
      debugPrint('Erro ao gerar pergunta complete-a-frase: $e');
      _mostrarErroSemPergunta();
    }

    setState(() => carregando = false);
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  void _mostrarErroSemPergunta() {
    setState(() {
      pergunta =
          'Erro: Não foi possível carregar a pergunta.\n\nVerifique se:\n• A IA está configurada\n• Há perguntas precarregadas\n• A conexão está funcionando';
      carregando = false;
    });
  }

  Future<void> _armazenarRespostaNaMemoriaIA(String perguntaGerada) async {
    try {
      final promptMemoria = '''
Você acabou de gerar esta pergunta de matemática:
"$perguntaGerada"

Agora, por favor, calcule e armazene mentalmente a resposta correta desta pergunta. 
Analise a pergunta passo a passo e determine:

1. A resposta correta (numérica ou textual)
2. O método de resolução
3. Os passos principais para chegar à resposta

Mantenha essas informações na sua memória para quando o usuário solicitar verificação da resposta ou explicação.

Responda apenas com "Resposta armazenada na memória" para confirmar que você processou e guardou a solução.
''';

      final confirmacao = await FirebaseAIService.sendMessage(promptMemoria);

      // Log opcional para debug (pode ser removido em produção)
      debugPrint('IA confirmou armazenamento: $confirmacao');
    } catch (e) {
      // Falha silenciosa - não impacta a experiência do usuário
      debugPrint('Erro ao armazenar resposta na memória da IA: $e');
    }
  }

  Future<Map<String, dynamic>> _verificarRespostaComMemoria(
      String pergunta, String respostaUsuario) async {
    try {
      final promptVerificacao = '''
Você tem na sua memória a pergunta de matemática:
"$pergunta"

O usuário respondeu: "$respostaUsuario"

Com base na resposta correta que você calculou e armazenou anteriormente, analise se a resposta do usuário está correta.

Forneça uma resposta no seguinte formato:
- Se estiver CORRETA: "CORRETO: [explicação breve do porquê está certo]"
- Se estiver INCORRETA: "INCORRETO: [resposta correta] - [explicação detalhada dos passos corretos]"

Seja preciso na análise matemática e didático na explicação.
''';

      final resultado = await FirebaseAIService.sendMessage(promptVerificacao);

      if (resultado == null) {
        // Fallback se Firebase AI falhar
        return {
          'correta': false,
          'explicacao': 'Erro ao verificar resposta. Tente novamente.',
        };
      }

      // Analisar a resposta da IA
      final isCorrect = resultado.toUpperCase().startsWith('CORRETO');

      String explicacao = '';
      if (isCorrect) {
        explicacao = resultado.replaceFirst(
            RegExp(r'^CORRETO:\s*', caseSensitive: false), '');
      } else {
        explicacao = resultado.replaceFirst(
            RegExp(r'^INCORRETO:\s*', caseSensitive: false), '');
      }

      return {
        'correta': isCorrect,
        'explicacao': explicacao.trim(),
      };
    } catch (e) {
      // Fallback para o método original em caso de erro
      return {
        'correta': false,
        'explicacao': 'Erro ao verificar resposta: $e',
      };
    }
  }

  Future<void> _verificarResposta() async {
    setState(() => carregando = true);

    String resposta = _respostaSelecionada ?? _respostaController.text.trim();
    if (resposta.isEmpty) {
      setState(() => carregando = false);
      return;
    }

    bool correta = false;
    String explicacaoResposta = '';

    try {
      // Usar verificação com memória da IA
      final resultado = await _verificarRespostaComMemoria(pergunta, resposta);
      correta = resultado['correta'] as bool;
      explicacaoResposta = resultado['explicacao'] ?? '';
    } catch (e) {
      explicacaoResposta = 'Erro ao verificar resposta: $e';
    }

    // Ajustar nível baseado na resposta
    if (correta && _nivelDificuldade < _niveis.length - 1) {
      setState(() => _nivelDificuldade++);
    } else if (!correta && _nivelDificuldade > 0) {
      setState(() => _nivelDificuldade--);
    }

    // Incrementar contador de exercícios respondidos
    _exerciciosRespondidos++;

    // Mostrar estatísticas a cada 10 exercícios respondidos
    if (_exerciciosRespondidos % 10 == 0) {
      setState(() {
        _mostrarEstatisticas = true;
      });
    }

    setState(() {
      _respostaCorreta = correta;
      feedback = correta
          ? '🎉 Perfeito! Parabéns pela resposta correta!'
          : '❌ Ops! Vamos ver a explicação e tentar novamente.';
      explicacao = explicacaoResposta;
      carregando = false;
    });

    // Salvar explicação no histórico quando a resposta está errada
    if (!correta) {
      await ExplicacaoService.salvarExplicacao(
        unidade: _exercicioAtual?['topico'] ?? 'Geral',
        ano: 'Não especificado',
        pergunta: pergunta,
        respostaUsuario: resposta,
        respostaCorreta:
            _exercicioAtual?['resposta_correta'] ?? 'Não disponível',
        explicacao: explicacaoResposta.isNotEmpty
            ? explicacaoResposta
            : 'Explicação não disponível',
        topicoEspecifico: _exercicioAtual?['topico'] ?? 'Complete a Frase',
      );
    }

    // Animar feedback
    _feedbackAnimationController.reset();
    _feedbackAnimationController.forward();

    // Salvar no histórico
    historico.add({
      'pergunta': pergunta,
      'resposta': resposta,
      'tipo': _exercicioAtual?['tipo'] ?? 'completar_frase',
      'correta': correta ? 'Correto' : 'Incorreto',
      'explicacao': explicacao,
      'nivel': _niveis[_nivelDificuldade],
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _salvarHistorico();
  }

  Future<void> _salvarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoJson = jsonEncode(historico);
    await prefs.setString('historico_tutoria', historicoJson);
  }

  Future<void> _carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoJson = prefs.getString('historico_tutoria');
    if (historicoJson != null) {
      final List<dynamic> decoded = jsonDecode(historicoJson);
      setState(() {
        historico = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  void _proximoExercicio() {
    _carregarProximoExercicio();
    setState(() {
      _respostaController.clear();
      _respostaSelecionada = null;
      _respostaCorreta = null;
      feedback = '';
      explicacao = '';
      _mostrarEstatisticas = false;
    });
    _feedbackAnimationController.reset();
  }

  void _mostrarAjuda(BuildContext context, String tipo, bool isTablet) async {
    setState(() {
      _carregandoAjuda = true;
      _ajudaIA = '';
    });

    try {
      // Criar prompt personalizado baseado na pergunta atual
      final prompt = '''
Você é um tutor educacional especializado. O aluno está com dúvidas sobre como responder esta pergunta:

"$pergunta"

Tipo de exercício: ${_getTipoTitulo(tipo)}

Por favor, forneça instruções claras e específicas sobre:
1. Como abordar este tipo de pergunta
2. Estratégias para encontrar a resposta correta
3. Dicas práticas para resolver este exercício específico
4. O que observar na pergunta para não errar

Seja didático, encorajador e específico para esta pergunta. Limite sua resposta a cerca de 200 palavras.
''';

      final ajudaGerada = await FirebaseAIService.sendMessage(prompt);

      setState(() {
        _ajudaIA = ajudaGerada ?? 'Erro ao gerar ajuda. Tente novamente.';
        _carregandoAjuda = false;
      });

      if (mounted) {
        _mostrarModalAjudaIA(mounted as BuildContext, tipo, isTablet);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ajudaIA =
              'Erro ao gerar ajuda: ${e.toString()}\n\nTente novamente ou consulte as instruções básicas.';
          _carregandoAjuda = false;
        });
      }
      if (mounted) {
        _mostrarModalAjudaIA(mounted as BuildContext, tipo, isTablet);
      }
    }
  }

  void _mostrarModalAjudaIA(BuildContext context, String tipo, bool isTablet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: isTablet ? 600 : double.infinity,
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor,
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              border: Border.all(
                color: AppTheme.darkBorderColor,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(isTablet ? 12 : 10),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primaryColor,
                          size: isTablet ? 24 : 20,
                        ),
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ajuda Inteligente',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.darkTextPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dicas personalizadas da IA',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

                // Conteúdo
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: _carregandoAjuda
                        ? _buildLoadingAjuda(isTablet)
                        : _buildConteudoAjudaIA(isTablet),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingAjuda(bool isTablet) {
    return Column(
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
          'Gerando dicas personalizadas...',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          'A IA está analisando sua pergunta',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildConteudoAjudaIA(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppTheme.primaryColor,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                'Dicas da IA para esta pergunta:',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            _ajudaIA,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

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
              // Header responsivo
              ResponsiveHeader(
                title: 'Quiz Complete a Frase Inteligente',
                subtitle: _buildSubtitle(),
                showBackButton: true,
                trailing: _buildHeaderTrailing(isTablet),
              ),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
                  ),
                  child: Column(
                    children: [
                      // Status e progresso
                      _buildStatusProgress(isTablet),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Card do exercício
                      carregando
                          ? _buildLoadingCard(isTablet)
                          : _buildExercicioCard(isTablet),
                      SizedBox(height: isTablet ? 24 : 16),

                      // Seção de feedback
                      if (_respostaCorreta != null) ...[
                        _buildFeedbackSection(isTablet),
                        SizedBox(height: isTablet ? 24 : 16),
                      ],

                      // Botões de ação
                      _buildActionButtons(isTablet),
                      SizedBox(height: isTablet ? 30 : 20),

                      // Estatísticas (quando mostrar)
                      if (_mostrarEstatisticas) ...[
                        _buildEstatisticas(isTablet),
                        SizedBox(height: isTablet ? 24 : 16),
                      ] else if (_exerciciosRespondidos > 0 &&
                          _exerciciosRespondidos % 10 != 0) ...[
                        _buildStatsButton(isTablet),
                        SizedBox(height: isTablet ? 20 : 16),
                      ],
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
    String nivel = 'Nível: ${_niveis[_nivelDificuldade].toUpperCase()}';

    if (useGemini) {
      return '$nivel • IA: Gemini';
    } else {
      return '$nivel • IA: Ollama ($modeloOllama)';
    }
  }

  Widget _buildHeaderTrailing(bool isTablet) {
    // Mostrar IA e modelo ou indicador de cache
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
                  Icons.cached,
                  color: AppTheme.warningColor,
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 6 : 4),
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
                  useGemini ? Icons.auto_awesome_rounded : Icons.memory_rounded,
                  color: AppTheme.primaryColor,
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 6 : 4),
                Text(
                  '${useGemini ? 'Gemini' : 'Ollama'} (${useGemini ? 'Pro' : modeloOllama})',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: isTablet ? 12 : 10,
                    fontWeight: FontWeight.w600,
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
    final totalExercicios = historico.length;
    final corretos = historico.where((h) => h['correta'] == 'Correto').length;
    final progresso = totalExercicios > 0 ? corretos / totalExercicios : 0.0;

    return ModernCard(
      child: Column(
        children: [
          ModernProgressIndicator(
            value: (_nivelDificuldade + 1) / _niveis.length,
            label: 'Progresso do Nível',
            color: AppTheme.primaryColor,
          ),
          if (totalExercicios > 0) ...[
            SizedBox(height: isTablet ? 20 : 16),
            ModernProgressIndicator(
              value: progresso,
              label: 'Taxa de Acerto',
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
            'Carregando próximo exercício...',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(bool isTablet) {
    final tipo = _exercicioAtual?['tipo'] ?? 'completar_frase';

    return ScaleTransition(
      scale: _cardScaleAnimation,
      child: ModernCard(
        hasGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo do exercício e botão de ajuda
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTipoColor(tipo).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: _getTipoColor(tipo).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTipoIcon(tipo),
                        color: _getTipoColor(tipo),
                        size: isTablet ? 20 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 6),
                      Text(
                        _getTipoTitulo(tipo),
                        style: AppTheme.bodyMedium.copyWith(
                          color: _getTipoColor(tipo),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de ajuda
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: AppTheme.infoColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => _mostrarAjuda(context, tipo, isTablet),
                    icon: Icon(
                      Icons.help_outline_rounded,
                      color: AppTheme.infoColor,
                      size: isTablet ? 20 : 18,
                    ),
                    tooltip: 'Como responder?',
                    padding: EdgeInsets.all(isTablet ? 8 : 6),
                    constraints: BoxConstraints(
                      minWidth: isTablet ? 40 : 36,
                      minHeight: isTablet ? 40 : 36,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Pergunta
            Text(
              pergunta,
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkTextPrimaryColor,
                height: 1.4,
              ),
            ),
            SizedBox(height: isTablet ? 24 : 20),

            // Interface do tipo
            _buildTipoInterface(tipo, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoInterface(String tipo, bool isTablet) {
    switch (tipo) {
      case 'multipla_escolha':
        return _buildMultiplaEscolha(isTablet);
      case 'verdadeiro_falso':
        return _buildVerdadeiroFalso(isTablet);
      case 'completar_frase':
      default:
        return _buildCompletarFrase(isTablet);
    }
  }

  Widget _buildMultiplaEscolha(bool isTablet) {
    final opcoes = _exercicioAtual?['opcoes'] as List<dynamic>? ?? [];

    return Column(
      children: opcoes.asMap().entries.map((entry) {
        final index = entry.key;
        final opcao = entry.value.toString();
        final isSelected = _respostaSelecionada == opcao;

        return Container(
          margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
          child: InkWell(
            onTap: () => setState(() => _respostaSelecionada = opcao),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.darkBorderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 32 : 28,
                    height: isTablet ? 32 : 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.darkBorderColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index), // A, B, C, D
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.darkTextSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Text(
                      opcao,
                      style: AppTheme.bodyLarge.copyWith(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.darkTextPrimaryColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerdadeiroFalso(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _respostaSelecionada = 'verdadeiro'),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: _respostaSelecionada == 'verdadeiro'
                    ? AppTheme.successColor.withValues(alpha: 0.2)
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: _respostaSelecionada == 'verdadeiro'
                      ? AppTheme.successColor
                      : AppTheme.darkBorderColor,
                  width: _respostaSelecionada == 'verdadeiro' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: _respostaSelecionada == 'verdadeiro'
                        ? AppTheme.successColor
                        : AppTheme.darkTextSecondaryColor,
                    size: isTablet ? 32 : 28,
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    'Verdadeiro',
                    style: AppTheme.bodyLarge.copyWith(
                      color: _respostaSelecionada == 'verdadeiro'
                          ? AppTheme.successColor
                          : AppTheme.darkTextPrimaryColor,
                      fontWeight: _respostaSelecionada == 'verdadeiro'
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _respostaSelecionada = 'falso'),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: _respostaSelecionada == 'falso'
                    ? AppTheme.errorColor.withValues(alpha: 0.2)
                    : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                border: Border.all(
                  color: _respostaSelecionada == 'falso'
                      ? AppTheme.errorColor
                      : AppTheme.darkBorderColor,
                  width: _respostaSelecionada == 'falso' ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    color: _respostaSelecionada == 'falso'
                        ? AppTheme.errorColor
                        : AppTheme.darkTextSecondaryColor,
                    size: isTablet ? 32 : 28,
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    'Falso',
                    style: AppTheme.bodyLarge.copyWith(
                      color: _respostaSelecionada == 'falso'
                          ? AppTheme.errorColor
                          : AppTheme.darkTextPrimaryColor,
                      fontWeight: _respostaSelecionada == 'falso'
                          ? FontWeight.w600
                          : FontWeight.normal,
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

  Widget _buildCompletarFrase(bool isTablet) {
    return ModernTextField(
      hint: 'Digite sua resposta aqui',
      controller: _respostaController,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.edit_rounded,
    );
  }

  Widget _buildFeedbackSection(bool isTablet) {
    return SlideTransition(
      position: _feedbackSlideAnimation,
      child: FadeTransition(
        opacity: _feedbackFadeAnimation,
        child: ModernCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feedback principal
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: (_respostaCorreta == true
                          ? AppTheme.successColor
                          : AppTheme.errorColor)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                  border: Border.all(
                    color: (_respostaCorreta == true
                            ? AppTheme.successColor
                            : AppTheme.errorColor)
                        .withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _respostaCorreta == true
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _respostaCorreta == true
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      size: isTablet ? 28 : 24,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Expanded(
                      child: Text(
                        feedback,
                        style: AppTheme.bodyLarge.copyWith(
                          color: _respostaCorreta == true
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Explicação
              if (explicacao.isNotEmpty) ...[
                SizedBox(height: isTablet ? 16 : 12),
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                    border: Border.all(
                      color: AppTheme.infoColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            color: AppTheme.infoColor,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: isTablet ? 8 : 6),
                          Text(
                            'Explicação',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.infoColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        explicacao,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      children: [
        if (_respostaCorreta == null) ...[
          Expanded(
            child: ModernButton(
              text: 'Verificar Resposta',
              icon: Icons.check_rounded,
              onPressed: (_respostaSelecionada != null ||
                      _respostaController.text.isNotEmpty)
                  ? _verificarResposta
                  : null,
              isLoading: carregando,
              isPrimary: true,
            ),
          ),
        ] else ...[
          Expanded(
            child: ModernButton(
              text: 'Próximo Exercício',
              icon: Icons.arrow_forward_rounded,
              onPressed: _proximoExercicio,
              isPrimary: true,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: ModernButton(
              text: 'Tentar Novamente',
              icon: Icons.refresh_rounded,
              onPressed: () {
                setState(() {
                  _respostaCorreta = null;
                  _respostaSelecionada = null;
                  _respostaController.clear();
                  feedback = '';
                  explicacao = '';
                });
                _feedbackAnimationController.reset();
              },
              isPrimary: false,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstatisticas(bool isTablet) {
    final totalExercicios = historico.length;
    final corretos = historico.where((h) => h['correta'] == 'Correto').length;
    final taxaAcerto =
        totalExercicios > 0 ? (corretos / totalExercicios * 100).round() : 0;

    return ModernCard(
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Suas Estatísticas',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _mostrarEstatisticas = false),
                icon: Icon(
                  Icons.close_rounded,
                  color: AppTheme.darkTextSecondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            'Relatório após $_exerciciosRespondidos exercícios respondidos',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Exercícios', totalExercicios.toString(),
                  Icons.quiz_rounded, isTablet),
              _buildStatItem('Corretos', corretos.toString(),
                  Icons.check_circle_rounded, isTablet),
              _buildStatItem(
                  'Taxa', '$taxaAcerto%', Icons.trending_up_rounded, isTablet),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: AppTheme.successColor,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Nível Atual: ${_niveis[_nivelDificuldade].toUpperCase()}',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, bool isTablet) {
    return Column(
      children: [
        Container(
          width: isTablet ? 60 : 50,
          height: isTablet ? 60 : 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isTablet ? 4 : 2),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsButton(bool isTablet) {
    return Center(
      child: ModernButton(
        text: 'Ver Estatísticas (${historico.length} exercícios)',
        icon: Icons.analytics_rounded,
        onPressed: () => setState(() => _mostrarEstatisticas = true),
        isPrimary: false,
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return Icons.list_rounded;
      case 'verdadeiro_falso':
        return Icons.help_rounded;
      case 'completar_frase':
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
      case 'completar_frase':
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
      case 'completar_frase':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
