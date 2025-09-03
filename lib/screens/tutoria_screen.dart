import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/math_tutor_service.dart';
import '../services/gemini_service.dart';
import '../services/ollama_service.dart';
import '../services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TutoriaScreen extends StatefulWidget {
  const TutoriaScreen({super.key});

  @override
  State<TutoriaScreen> createState() => _TutoriaScreenState();
}

class _TutoriaScreenState extends State<TutoriaScreen> {
  final GeminiService geminiService = GeminiService();
  bool _isLoading = true;
  String? _error;
  bool _isOfflineMode = false;
  List<Map<String, dynamic>> _exerciciosOffline = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _carregarExerciciosOffline();
    await _checkAIServices();
  }

  Future<void> _carregarExerciciosOffline() async {
    // Exercícios pré-definidos para modo offline com vários tipos
    _exerciciosOffline = [
      // Quiz Múltipla Escolha - Frações
      {
        'tipo': 'multipla_escolha',
        'topico': 'Frações',
        'nivel': 'fácil',
        'pergunta': 'Quanto é 1/2 + 1/4?',
        'resposta_correta': '3/4',
        'explicacao':
            'Para somar frações com denominadores diferentes, primeiro encontramos o mínimo múltiplo comum (MMC) dos denominadores. MMC de 2 e 4 é 4. Convertemos 1/2 para 2/4 e somamos: 2/4 + 1/4 = 3/4.',
        'opcoes': ['3/4', '1/2', '1/4', '2/4']
      },
      // Quiz Verdadeiro/Falso - Geometria
      {
        'tipo': 'verdadeiro_falso',
        'topico': 'Geometria',
        'nivel': 'fácil',
        'pergunta': 'Um quadrado tem quatro lados iguais.',
        'resposta_correta': 'verdadeiro',
        'explicacao':
            'Por definição, um quadrado é um polígono com quatro lados de comprimento igual e quatro ângulos retos.',
        'opcoes': ['verdadeiro', 'falso']
      },
      // Quiz Completar Frase - Porcentagem
      {
        'tipo': 'completar_frase',
        'topico': 'Porcentagem',
        'nivel': 'médio',
        'pergunta': '20% de 150 é igual a _____.',
        'resposta_correta': '30',
        'explicacao':
            'Para calcular 20% de 150: (20/100) × 150 = 0,2 × 150 = 30.',
        'opcoes': []
      },
      // Quiz Múltipla Escolha - Geometria
      {
        'tipo': 'multipla_escolha',
        'topico': 'Geometria',
        'nivel': 'médio',
        'pergunta': 'Qual é a área de um retângulo com base 5cm e altura 3cm?',
        'resposta_correta': '15 cm²',
        'explicacao':
            'A área de um retângulo é calculada multiplicando a base pela altura: 5 × 3 = 15 cm².',
        'opcoes': ['15 cm²', '8 cm²', '25 cm²', '10 cm²']
      },
      // Quiz Verdadeiro/Falso - Álgebra
      {
        'tipo': 'verdadeiro_falso',
        'topico': 'Álgebra',
        'nivel': 'médio',
        'pergunta': 'A equação 2x + 3 = 7 tem como solução x = 2.',
        'resposta_correta': 'verdadeiro',
        'explicacao': 'Resolvendo a equação: 2x + 3 = 7 → 2x = 4 → x = 2.',
        'opcoes': ['verdadeiro', 'falso']
      },
      // Quiz Completar Frase - Frações
      {
        'tipo': 'completar_frase',
        'topico': 'Frações',
        'nivel': 'difícil',
        'pergunta': 'A fração 3/4 equivale a _____%.',
        'resposta_correta': '75',
        'explicacao':
            'Para converter fração em porcentagem: (3/4) × 100 = 75%.',
        'opcoes': []
      },
      // Quiz Múltipla Escolha - Estatística
      {
        'tipo': 'multipla_escolha',
        'topico': 'Estatística',
        'nivel': 'difícil',
        'pergunta': 'Qual é a média dos números: 2, 4, 6, 8, 10?',
        'resposta_correta': '6',
        'explicacao':
            'A média é calculada somando todos os valores e dividindo pelo número de valores: (2+4+6+8+10)/5 = 30/5 = 6.',
        'opcoes': ['6', '5', '7', '8']
      },
      // Quiz Verdadeiro/Falso - Geometria
      {
        'tipo': 'verdadeiro_falso',
        'topico': 'Geometria',
        'nivel': 'difícil',
        'pergunta': 'A soma dos ângulos internos de um triângulo é 180 graus.',
        'resposta_correta': 'verdadeiro',
        'explicacao':
            'A soma dos ângulos internos de qualquer triângulo é sempre 180 graus.',
        'opcoes': ['verdadeiro', 'falso']
      },
      // Quiz Completar Frase - Álgebra
      {
        'tipo': 'completar_frase',
        'topico': 'Álgebra',
        'nivel': 'fácil',
        'pergunta': 'Se x = 5, então 2x + 3 = _____.',
        'resposta_correta': '13',
        'explicacao': 'Substituindo x = 5 na expressão: 2×5 + 3 = 10 + 3 = 13.',
        'opcoes': []
      },
      // Quiz Múltipla Escolha - Porcentagem
      {
        'tipo': 'multipla_escolha',
        'topico': 'Porcentagem',
        'nivel': 'difícil',
        'pergunta': '20% de 150 é igual a:',
        'resposta_correta': '30',
        'explicacao':
            'Para calcular 20% de 150: (20/100) × 150 = 0,2 × 150 = 30.',
        'opcoes': ['30', '20', '150', '300']
      },
      // Quiz Verdadeiro/Falso - Números
      {
        'tipo': 'verdadeiro_falso',
        'topico': 'Números',
        'nivel': 'médio',
        'pergunta': 'O número 17 é um número primo.',
        'resposta_correta': 'verdadeiro',
        'explicacao':
            '17 é um número primo porque só é divisível por 1 e por ele mesmo.',
        'opcoes': ['verdadeiro', 'falso']
      },
      // Quiz Completar Frase - Geometria
      {
        'tipo': 'completar_frase',
        'topico': 'Geometria',
        'nivel': 'médio',
        'pergunta': 'Um círculo tem _____ graus.',
        'resposta_correta': '360',
        'explicacao': 'Um círculo completo mede 360 graus.',
        'opcoes': []
      }
    ];
  }

  Future<void> _checkAIServices() async {
    try {
      final geminiAvailable = await geminiService.isServiceAvailable();
      final ollamaService = OllamaService();
      final ollamaAvailable = await ollamaService.isServiceAvailable();

      if (mounted) {
        setState(() {
          if (!geminiAvailable && !ollamaAvailable) {
            _isOfflineMode = true;
            _error = 'Modo offline ativado. Serviços de IA não disponíveis.';
          } else {
            _error = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
          _error = 'Modo offline ativado. Erro na conexão com IA.';
          _isLoading = false;
        });
      }
    }
  }

  void _startTutoria() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TutoriaInterativaScreen(
          isOfflineMode: _isOfflineMode,
          exerciciosOffline: _exerciciosOffline,
        ),
      ),
    );
  }

  void _goToConfig() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const ConfiguracaoScreen(),
          ),
        )
        .then((_) => _checkAIServices());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Sistema de Tutoria Inteligente'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: _isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(radius: 20),
                      SizedBox(height: 24),
                      Text(
                        'Inicializando sistema...',
                        style: TextStyle(
                          fontSize: 18,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CupertinoColors.activeBlue.withOpacity(0.1),
                              CupertinoColors.systemGreen.withOpacity(0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isOfflineMode
                                  ? CupertinoIcons.wifi_slash
                                  : CupertinoIcons.book_solid,
                              size: 80,
                              color: _isOfflineMode
                                  ? CupertinoColors.systemOrange
                                  : CupertinoColors.activeBlue,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isOfflineMode
                                  ? 'Modo Offline Ativado'
                                  : 'Sistema de Tutoria Inteligente',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isOfflineMode
                                    ? CupertinoColors.systemOrange
                                    : CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isOfflineMode
                            ? 'Aprenda matemática mesmo sem conexão! Temos exercícios pré-carregados para você.'
                            : 'Desafie-se e melhore suas habilidades matemáticas com IA generativa adaptativa.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isOfflineMode
                              ? CupertinoColors.systemOrange.withOpacity(0.1)
                              : CupertinoColors.activeGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isOfflineMode
                                  ? CupertinoIcons.exclamationmark_triangle
                                  : CupertinoIcons.checkmark_circle,
                              color: _isOfflineMode
                                  ? CupertinoColors.systemOrange
                                  : CupertinoColors.activeGreen,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isOfflineMode
                                    ? 'Sem conexão com IA - usando exercícios offline'
                                    : 'IA conectada - experiência completa disponível',
                                style: TextStyle(
                                  color: _isOfflineMode
                                      ? CupertinoColors.systemOrange
                                      : CupertinoColors.activeGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (_error != null && !_isOfflineMode) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      CupertinoButton.filled(
                        onPressed: _startTutoria,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isOfflineMode
                                  ? CupertinoIcons.book
                                  : CupertinoIcons.rocket,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOfflineMode
                                  ? 'Iniciar Tutoria Offline'
                                  : 'Iniciar Tutoria Inteligente',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        onPressed: _goToConfig,
                        color: CupertinoColors.systemGrey4,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.settings),
                            SizedBox(width: 8),
                            Text(
                              'Configurações Avançadas',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Funcionalidades:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFeatureList(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      '✅ Exercícios adaptativos por nível',
      '✅ Explicações passo-a-passo com IA',
      '✅ Histórico de progresso detalhado',
      '✅ Modo offline com exercícios pré-carregados',
      '✅ Alternância entre Gemini e Ollama',
      '✅ Interface intuitiva e gamificada',
      '🎯 Múltipla escolha interativa',
      '✓ Quiz verdadeiro/falso',
      '📝 Complete a frase',
      '📊 Estatísticas de desempenho',
      '🎮 Experiência gamificada',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  feature,
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class GeminiConfigScreen extends StatefulWidget {
  const GeminiConfigScreen({super.key});

  @override
  State<GeminiConfigScreen> createState() => _GeminiConfigScreenState();
}

class _GeminiConfigScreenState extends State<GeminiConfigScreen> {
  final TextEditingController apiKeyController = TextEditingController();
  bool carregando = false;
  String status = '';
  bool _useGeminiDefault = true;

  @override
  void initState() {
    super.initState();
    _carregarApiKey();
  }

  Future<void> _carregarApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    final useGemini = prefs.getBool('use_gemini') ?? true;
    if (apiKey != null) {
      apiKeyController.text = apiKey;
    } else {
      // Usar a chave padrão se não houver uma salva
      apiKeyController.text = 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo';
    }
    setState(() {
      _useGeminiDefault = useGemini;
    });
  }

  Future<void> _salvarApiKey() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    await prefs.setBool('use_gemini', _useGeminiDefault);

    setState(() {
      status = 'Configurações salvas com sucesso!';
    });
  }

  Future<void> testarConexao() async {
    setState(() => carregando = true);
    try {
      final geminiService = GeminiService(apiKey: apiKeyController.text.trim());
      final isAvailable = await geminiService.isServiceAvailable();
      status = isAvailable
          ? 'Conexão com Gemini funcionando!'
          : 'Erro na conexão com Gemini.';
    } catch (e) {
      status = 'Erro ao testar conexão: $e';
    }
    setState(() => carregando = false);
  }

  void _toggleDefaultService() {
    setState(() {
      _useGeminiDefault = !_useGeminiDefault;
    });
  }

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(apiKey: apiKeyController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Configuração do Gemini'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: carregando
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para usar o Gemini, você precisa de uma chave API:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Vá para https://makersuite.google.com/app/apikey\n2. Crie uma nova chave API\n3. Cole a chave abaixo',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 24),
                  const Text('Chave API do Gemini:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: apiKeyController,
                    placeholder: 'Cole sua chave API aqui',
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          onPressed: _salvarApiKey,
                          color: CupertinoColors.activeBlue,
                          borderRadius: BorderRadius.circular(12),
                          child: const Text('Salvar API Key'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoButton(
                          onPressed: testarConexao,
                          color: CupertinoColors.systemGrey,
                          borderRadius: BorderRadius.circular(12),
                          child: const Text('Testar Conexão'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Serviço de IA Padrão:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: _toggleDefaultService,
                    color: _useGeminiDefault
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemOrange,
                    borderRadius: BorderRadius.circular(12),
                    child: Text(
                        _useGeminiDefault ? 'Usando Gemini' : 'Usando Ollama'),
                  ),
                  const SizedBox(height: 16),
                  if (apiKeyController.text.isNotEmpty) ...[
                    CupertinoButton.filled(
                      onPressed: _startGame,
                      borderRadius: BorderRadius.circular(12),
                      child: const Text('Iniciar Jogo'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(status,
                      style:
                          const TextStyle(color: CupertinoColors.activeBlue)),
                ],
              ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String? apiKey;
  const GameScreen({super.key, this.apiKey});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late MathTutorService tutorService;
  final TextEditingController _respostaController = TextEditingController();
  String pergunta = '';
  String explicacao = '';
  String feedback = '';
  bool carregando = false;
  bool? _respostaCorreta;
  List<Map<String, String>> historico = [];
  int _nivelDificuldade = 1; // 0: Fácil, 1: Médio, 2: Difícil
  final List<String> _niveis = ['fácil', 'médio', 'difícil', 'expert'];
  bool _useGemini = true; // Estado para controlar qual serviço usar

  @override
  void initState() {
    super.initState();
    _carregarPreferencias().then((_) {
      _initializeService().then((_) {
        _carregarHistorico().then((_) => gerarNovaPergunta());
      });
    });
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useGemini = prefs.getBool('use_gemini') ?? true;
    });
  }

  Future<void> _initializeService() async {
    String? apiKey = widget.apiKey;

    if (apiKey == null || apiKey.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('gemini_api_key');
    }

    AIService aiService;
    if (_useGemini) {
      aiService = GeminiService(apiKey: apiKey);
    } else {
      aiService = OllamaService();
    }

    tutorService = MathTutorService(aiService: aiService);
  }

  Future<void> _toggleAIService() async {
    setState(() {
      _useGemini = !_useGemini;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_gemini', _useGemini);
    await _initializeService();
  }

  Future<void> _salvarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoJson = jsonEncode(historico);
    await prefs.setString('historico_perguntas', historicoJson);
  }

  Future<void> _carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoJson = prefs.getString('historico_perguntas');
    if (historicoJson != null) {
      final List<dynamic> decoded = jsonDecode(historicoJson);
      setState(() {
        historico = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> gerarNovaPergunta() async {
    setState(() {
      carregando = true;
      pergunta = '';
      explicacao = '';
      feedback = '';
      _respostaCorreta = null;
      _respostaController.clear();
    });
    pergunta = await tutorService.gerarPergunta(_niveis[_nivelDificuldade]);
    setState(() => carregando = false);
  }

  Future<void> _verificarResposta() async {
    setState(() => carregando = true);
    final resposta = _respostaController.text.trim();
    if (resposta.isEmpty) {
      setState(() => carregando = false);
      return;
    }

    final resultado = await tutorService.verificarResposta(pergunta, resposta);
    final correta = resultado['correta'] as bool;

    if (correta) {
      if (_nivelDificuldade < _niveis.length - 1) {
        setState(() => _nivelDificuldade++);
      }
    } else {
      if (_nivelDificuldade > 0) {
        setState(() => _nivelDificuldade--);
      }
    }

    setState(() {
      _respostaCorreta = correta;
      feedback = correta
          ? 'Correto! Próximo nível: ${_niveis[_nivelDificuldade]}'
          : 'Incorreto. Tente novamente ou peça uma explicação.';
      historico.add({
        'pergunta': pergunta,
        'resposta': resposta,
        'correta': correta ? 'Correto' : 'Incorreto',
        'explicacao': '',
        'nivel': _niveis[_nivelDificuldade],
      });
      carregando = false;
    });
    await _salvarHistorico();
  }

  Future<void> mostrarExplicacao() async {
    setState(() => carregando = true);
    explicacao = await tutorService.gerarExplicacao(
        pergunta, 'Resposta correta', _respostaController.text);
    if (historico.isNotEmpty) {
      historico.last['explicacao'] = explicacao;
    }
    setState(() => carregando = false);
    await _salvarHistorico();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Tutor de Matemática'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            carregando
                ? const Column(
                    children: [
                      CupertinoActivityIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando pergunta da IA...',
                          style: TextStyle(color: CupertinoColors.systemGrey)),
                    ],
                  )
                : _buildQuestionCardCupertino(),
            const SizedBox(height: 30),
            _buildHistoryListCupertino(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCardCupertino() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nível: ${_niveis[_nivelDificuldade].toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              pergunta,
              key: ValueKey<String>(pergunta),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, color: CupertinoColors.black, height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoTextField(
            controller: _respostaController,
            placeholder: 'Sua Resposta',
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            style: const TextStyle(fontSize: 18),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: _verificarResposta,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Verificar', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          _buildFeedbackSectionCupertino(),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: gerarNovaPergunta,
            color: CupertinoColors.activeGreen,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Nova Pergunta'),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _toggleAIService,
            color: _useGemini
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemOrange,
            borderRadius: BorderRadius.circular(12),
            child: Text(_useGemini ? 'Usar Ollama' : 'Usar Gemini'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSectionCupertino() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _respostaCorreta == null
            ? CupertinoColors.systemGrey6
            : _respostaCorreta == true
                ? CupertinoColors.activeGreen.withOpacity(0.1)
                : CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (feedback.isNotEmpty)
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _respostaCorreta == true
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          if (_respostaCorreta == false) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: mostrarExplicacao,
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Ver Explicação'),
            ),
          ],
          if (explicacao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              explicacao,
              style: const TextStyle(
                  fontSize: 16, color: CupertinoColors.black, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryListCupertino() {
    return Column(
      children: [
        const Text(
          'Histórico de Atividades',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.activeBlue),
        ),
        const SizedBox(height: 16),
        if (historico.isEmpty)
          const Text('Nenhuma atividade ainda.',
              style:
                  TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historico.length,
          itemBuilder: (context, index) {
            final item = historico.reversed.toList()[index];
            final isCorrect = item['correta'] == 'Correto';
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['pergunta'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (item['nivel'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Nível: ${item['nivel']}',
                          style: const TextStyle(
                              fontSize: 14, color: CupertinoColors.activeBlue)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Sua resposta: ${item['resposta'] ?? ''}',
                      style: const TextStyle(
                          fontSize: 16, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? CupertinoIcons.check_mark_circled
                              : CupertinoIcons.clear_circled,
                          color: isCorrect
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['correta'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                    if (item['explicacao'] != null &&
                        item['explicacao']!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Explicação: ${item['explicacao']}',
                            style: const TextStyle(
                                color: CupertinoColors.activeBlue)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class ConfiguracaoScreen extends StatefulWidget {
  const ConfiguracaoScreen({super.key});

  @override
  State<ConfiguracaoScreen> createState() => _ConfiguracaoScreenState();
}

class _ConfiguracaoScreenState extends State<ConfiguracaoScreen> {
  final TextEditingController apiKeyController = TextEditingController();
  bool carregando = false;
  String status = '';
  bool _useGeminiDefault = true;
  String _modeloOllama = 'llama2';

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    final useGemini = prefs.getBool('use_gemini') ?? true;
    final modeloOllama = prefs.getString('modelo_ollama') ?? 'llama2';

    if (apiKey != null) {
      apiKeyController.text = apiKey;
    } else {
      apiKeyController.text = 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo';
    }

    setState(() {
      _useGeminiDefault = useGemini;
      _modeloOllama = modeloOllama;
    });
  }

  Future<void> _salvarConfiguracoes() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    await prefs.setBool('use_gemini', _useGeminiDefault);
    await prefs.setString('modelo_ollama', _modeloOllama);

    setState(() {
      status = 'Configurações salvas com sucesso!';
    });
  }

  Future<void> testarConexao() async {
    setState(() => carregando = true);
    try {
      if (_useGeminiDefault) {
        final geminiService =
            GeminiService(apiKey: apiKeyController.text.trim());
        final isAvailable = await geminiService.isServiceAvailable();
        status = isAvailable
            ? 'Conexão com Gemini funcionando!'
            : 'Erro na conexão com Gemini.';
      } else {
        final ollamaService = OllamaService(defaultModel: _modeloOllama);
        final isAvailable = await ollamaService.isServiceAvailable();
        status = isAvailable
            ? 'Conexão com Ollama funcionando!'
            : 'Erro na conexão com Ollama.';
      }
    } catch (e) {
      status = 'Erro ao testar conexão: $e';
    }
    setState(() => carregando = false);
  }

  void _toggleServicoPadrao() {
    setState(() {
      _useGeminiDefault = !_useGeminiDefault;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Configurações Avançadas'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Configuração de Serviços de IA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(height: 24),

            // Configuração Gemini
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Gemini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chave API do Gemini (necessária para usar o serviço):',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: apiKeyController,
                    placeholder: 'Cole sua chave API aqui',
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    obscureText: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Seleção de serviço padrão
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Serviço Padrão',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: _toggleServicoPadrao,
                    color: _useGeminiDefault
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemOrange,
                    borderRadius: BorderRadius.circular(12),
                    child: Text(
                      _useGeminiDefault ? 'Usando Gemini' : 'Usando Ollama',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _useGeminiDefault
                        ? 'O sistema usará Google Gemini como IA principal.'
                        : 'O sistema usará Ollama (local) como IA principal.',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Configuração Ollama
            if (!_useGeminiDefault) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ollama (Local)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Modelo a ser usado:',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _modeloOllama,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nota: Certifique-se de que o Ollama está instalado e o modelo está disponível.',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    onPressed: _salvarConfiguracoes,
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Salvar Configurações'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CupertinoButton(
                    onPressed: testarConexao,
                    color: CupertinoColors.systemGrey,
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Testar Conexão'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (status.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: status.contains('funcionando')
                      ? CupertinoColors.activeGreen.withOpacity(0.1)
                      : CupertinoColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: status.contains('funcionando')
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemRed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TutoriaInterativaScreen extends StatefulWidget {
  final bool isOfflineMode;
  final List<Map<String, dynamic>> exerciciosOffline;

  const TutoriaInterativaScreen({
    super.key,
    required this.isOfflineMode,
    required this.exerciciosOffline,
  });

  @override
  State<TutoriaInterativaScreen> createState() =>
      _TutoriaInterativaScreenState();
}

class _TutoriaInterativaScreenState extends State<TutoriaInterativaScreen> {
  late MathTutorService tutorService;
  final TextEditingController _respostaController = TextEditingController();
  String pergunta = '';
  String explicacao = '';
  String feedback = '';
  bool carregando = false;
  bool? _respostaCorreta;
  List<Map<String, String>> historico = [];
  int _nivelDificuldade = 1;
  final List<String> _niveis = ['fácil', 'médio', 'difícil', 'expert'];
  bool _useGemini = true;
  Map<String, dynamic>? _exercicioAtual;
  int _exercicioIndex = 0;
  int _exerciciosRespondidos = 0; // Contador de exercícios respondidos
  bool _mostrarEstatisticas = false; // Flag para mostrar estatísticas

  @override
  void initState() {
    super.initState();
    _initializeTutoria();
  }

  Future<void> _initializeTutoria() async {
    await _carregarPreferencias();
    await _initializeService();
    await _carregarHistorico();
    await _carregarProximoExercicio();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useGemini = prefs.getBool('use_gemini') ?? true;
    });
  }

  Future<void> _initializeService() async {
    if (!widget.isOfflineMode) {
      String? apiKey;
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('gemini_api_key');

      AIService aiService;
      if (_useGemini) {
        aiService = GeminiService(apiKey: apiKey);
      } else {
        aiService = OllamaService();
      }

      tutorService = MathTutorService(aiService: aiService);
    }
  }

  Future<void> _carregarProximoExercicio() async {
    if (widget.isOfflineMode && widget.exerciciosOffline.isNotEmpty) {
      // Modo offline - usar exercícios pré-carregados
      final exerciciosNivel = widget.exerciciosOffline
          .where((ex) => ex['nivel'] == _niveis[_nivelDificuldade])
          .toList();

      if (exerciciosNivel.isNotEmpty) {
        _exercicioAtual =
            exerciciosNivel[_exercicioIndex % exerciciosNivel.length];
        setState(() {
          pergunta = _exercicioAtual!['pergunta'];
          carregando = false;
        });
      }
    } else if (!widget.isOfflineMode) {
      // Modo online - gerar com IA
      await gerarNovaPergunta();
    }
  }

  Future<void> gerarNovaPergunta() async {
    if (widget.isOfflineMode) return;

    setState(() {
      carregando = true;
      pergunta = '';
      explicacao = '';
      feedback = '';
      _respostaCorreta = null;
      _respostaController.clear();
    });

    try {
      pergunta = await tutorService.gerarPergunta(_niveis[_nivelDificuldade]);
    } catch (e) {
      pergunta = 'Erro ao gerar pergunta. Tente novamente.';
    }

    setState(() => carregando = false);
  }

  Future<void> _verificarResposta() async {
    setState(() => carregando = true);
    final resposta = _respostaController.text.trim();
    if (resposta.isEmpty) {
      setState(() => carregando = false);
      return;
    }

    bool correta = false;
    String explicacaoResposta = '';

    if (widget.isOfflineMode && _exercicioAtual != null) {
      // Verificação offline baseada no tipo de quiz
      final tipo = _exercicioAtual!['tipo'] ?? 'completar_frase';

      switch (tipo) {
        case 'multipla_escolha':
        case 'verdadeiro_falso':
        case 'completar_frase':
          correta = resposta.toLowerCase() ==
              _exercicioAtual!['resposta_correta'].toLowerCase();
          break;
        default:
          correta = resposta.toLowerCase() ==
              _exercicioAtual!['resposta_correta'].toLowerCase();
      }

      explicacaoResposta = _exercicioAtual!['explicacao'];
    } else if (!widget.isOfflineMode) {
      // Verificação com IA
      try {
        final resultado =
            await tutorService.verificarResposta(pergunta, resposta);
        correta = resultado['correta'] as bool;
      } catch (e) {
        correta = false;
      }
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
          ? '🎉 Correto! Próximo nível: ${_niveis[_nivelDificuldade]}'
          : '❌ Incorreto. Tente novamente ou veja a explicação.';
      explicacao = explicacaoResposta;
      carregando = false;
    });

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
    _exercicioIndex++;
    _carregarProximoExercicio();
    setState(() {
      _respostaController.clear();
      _respostaCorreta = null;
      feedback = '';
      explicacao = '';
      _mostrarEstatisticas = false; // Ocultar estatísticas ao avançar
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          widget.isOfflineMode ? 'Tutoria Offline' : 'Tutoria Inteligente',
        ),
        backgroundColor: CupertinoColors.systemGrey6,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.xmark),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Status do sistema
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isOfflineMode
                    ? CupertinoColors.systemOrange.withOpacity(0.1)
                    : CupertinoColors.activeGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isOfflineMode
                        ? CupertinoIcons.wifi_slash
                        : CupertinoIcons.wifi,
                    color: widget.isOfflineMode
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.activeGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isOfflineMode
                        ? 'Modo Offline Ativo'
                        : 'IA Conectada',
                    style: TextStyle(
                      color: widget.isOfflineMode
                          ? CupertinoColors.systemOrange
                          : CupertinoColors.activeGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Barra de progresso
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nível: ${_niveis[_nivelDificuldade].toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      Text(
                        'Exercícios: ${historico.length}',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_nivelDificuldade + 1) / _niveis.length,
                    backgroundColor: CupertinoColors.systemGrey4,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            carregando
                ? const Column(
                    children: [
                      CupertinoActivityIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Carregando exercício...',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ],
                  )
                : _buildExercicioCard(),

            const SizedBox(height: 30),

            // Mostrar estatísticas apenas a cada 10 exercícios ou quando solicitado
            if (_mostrarEstatisticas) ...[
              _buildEstatisticas(),
              const SizedBox(height: 16),
            ] else if (_exerciciosRespondidos > 0 && _exerciciosRespondidos % 10 != 0) ...[
              // Botão para mostrar estatísticas manualmente
              Center(
                child: CupertinoButton(
                  onPressed: () {
                    setState(() {
                      _mostrarEstatisticas = true;
                    });
                  },
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.chart_bar,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Estatísticas (${historico.length} exercícios)',
                        style: const TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExercicioCard() {
    final tipo = _exercicioAtual?['tipo'] ?? 'completar_frase';

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _getTipoIcon(tipo),
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTipoTitulo(tipo),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              pergunta,
              key: ValueKey<String>(pergunta),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: CupertinoColors.black,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildTipoInterface(tipo),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: _verificarResposta,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Verificar Resposta',
                style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          _buildFeedbackSection(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: _proximoExercicio,
                  color: CupertinoColors.activeGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: const Text('Próximo Exercício'),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(12),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return CupertinoIcons.list_bullet;
      case 'verdadeiro_falso':
        return CupertinoIcons.checkmark_square;
      case 'completar_frase':
        return CupertinoIcons.text_cursor;
      default:
        return CupertinoIcons.book;
    }
  }

  String _getTipoTitulo(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return 'Quiz de Múltipla Escolha';
      case 'verdadeiro_falso':
        return 'Verdadeiro ou Falso';
      case 'completar_frase':
        return 'Complete a Frase';
      default:
        return 'Exercício de Matemática';
    }
  }

  Widget _buildTipoInterface(String tipo) {
    switch (tipo) {
      case 'multipla_escolha':
        return _buildMultiplaEscolha();
      case 'verdadeiro_falso':
        return _buildVerdadeiroFalso();
      case 'completar_frase':
      default:
        return _buildCompletarFrase();
    }
  }

  Widget _buildMultiplaEscolha() {
    final opcoes = _exercicioAtual?['opcoes'] as List<dynamic>? ?? [];

    return Column(
      children: opcoes.map((opcao) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              setState(() {
                _respostaController.text = opcao.toString();
              });
            },
            child: Row(
              children: [
                Icon(
                  _respostaController.text == opcao.toString()
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: _respostaController.text == opcao.toString()
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opcao.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerdadeiroFalso() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: _respostaController.text == 'verdadeiro'
                ? CupertinoColors.activeGreen
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              setState(() {
                _respostaController.text = 'verdadeiro';
              });
            },
            child: const Text(
              'Verdadeiro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: _respostaController.text == 'falso'
                ? CupertinoColors.systemRed
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              setState(() {
                _respostaController.text = 'falso';
              });
            },
            child: const Text(
              'Falso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletarFrase() {
    return CupertinoTextField(
      controller: _respostaController,
      placeholder: 'Digite sua resposta aqui',
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      style: const TextStyle(fontSize: 18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _respostaCorreta == null
            ? CupertinoColors.systemGrey6
            : _respostaCorreta == true
                ? CupertinoColors.activeGreen.withOpacity(0.1)
                : CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (feedback.isNotEmpty)
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _respostaCorreta == true
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          if (_respostaCorreta == false && explicacao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📚 Explicação:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    explicacao,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.black,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstatisticas() {
    final totalExercicios = historico.length;
    final corretos = historico.where((h) => h['correta'] == 'Correto').length;
    final taxaAcerto =
        totalExercicios > 0 ? (corretos / totalExercicios * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Suas Estatísticas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _mostrarEstatisticas = false;
                  });
                },
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Relatório após ${_exerciciosRespondidos} exercícios respondidos',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Exercícios', totalExercicios.toString()),
              _buildStatItem('Corretos', corretos.toString()),
              _buildStatItem('Taxa', '$taxaAcerto%'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nível Atual: ${_niveis[_nivelDificuldade].toUpperCase()}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.activeGreen,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '💡 As estatísticas aparecem automaticamente a cada 10 exercícios!',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.activeBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
