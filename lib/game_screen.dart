import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'math_tutor_service.dart';
import 'gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final GeminiService geminiService = GeminiService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkGemini();
  }

  Future<void> _checkGemini() async {
    try {
      final isAvailable = await geminiService.isServiceAvailable();
      if (mounted) {
        setState(() {
          if (!isAvailable) {
            _error = 'Serviço Gemini não está acessível. Verifique sua chave API.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao conectar com Gemini. Verifique sua configuração.';
          _isLoading = false;
        });
      }
    }
  }

  void _startGame() {
    if (_error == null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const GameScreen(),
        ),
      );
    } else {
      _goToConfig();
    }
  }

  void _goToConfig() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const GeminiConfigScreen(),
          ),
        )
        .then((_) => _checkGemini());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Bem-vindo'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(CupertinoIcons.book_solid, size: 80, color: CupertinoColors.activeBlue),
                    const SizedBox(height: 24),
                    const Text(
                      'Tutor de Matemática Adaptativo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Desafie-se e melhore suas habilidades matemáticas com a ajuda da IA Gemini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: CupertinoColors.systemRed, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CupertinoButton.filled(
                      onPressed: _startGame,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(_error == null ? 'Iniciar Jogo' : 'Configurar API', style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _goToConfig,
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(12),
                      child: const Text('Configurações', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
        ),
      ),
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

  @override
  void initState() {
    super.initState();
    _carregarApiKey();
  }

  Future<void> _carregarApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');
    if (apiKey != null) {
      apiKeyController.text = apiKey;
    } else {
      // Usar a chave padrão se não houver uma salva
      apiKeyController.text = 'AIzaSyAiNcBfK0i7P6qPuqfhbT3ijZgHJKyW0xo';
    }
  }

  Future<void> _salvarApiKey() async {
    final apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    
    setState(() {
      status = 'Chave API salva com sucesso!';
    });
  }

  Future<void> testarConexao() async {
    setState(() => carregando = true);
    try {
      final geminiService = GeminiService(apiKey: apiKeyController.text.trim());
      final isAvailable = await geminiService.isServiceAvailable();
      status = isAvailable ? 'Conexão com Gemini funcionando!' : 'Erro na conexão com Gemini.';
    } catch (e) {
      status = 'Erro ao testar conexão: $e';
    }
    setState(() => carregando = false);
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
                  const Text('Chave API do Gemini:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: apiKeyController,
                    placeholder: 'Cole sua chave API aqui',
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                  if (apiKeyController.text.isNotEmpty) ...[
                    CupertinoButton.filled(
                      onPressed: _startGame,
                      borderRadius: BorderRadius.circular(12),
                      child: const Text('Iniciar Jogo'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(status, style: const TextStyle(color: CupertinoColors.activeBlue)),
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

  @override
  void initState() {
    super.initState();
    _initializeService();
    _carregarHistorico().then((_) => gerarNovaPergunta());
  }

  Future<void> _initializeService() async {
    String? apiKey = widget.apiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('gemini_api_key');
    }
    
    tutorService = MathTutorService(apiKey: apiKey);
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
    explicacao = await tutorService
        .gerarExplicacao(pergunta, 'Resposta correta', _respostaController.text);
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
                ? Column(
                    children: [
                      const CupertinoActivityIndicator(),
                      const SizedBox(height: 16),
                      const Text('Carregando pergunta da IA...', style: TextStyle(color: CupertinoColors.systemGrey)),
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
              style: const TextStyle(fontSize: 20, color: CupertinoColors.black, height: 1.5),
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
                color: _respostaCorreta == true ? CupertinoColors.activeGreen : CupertinoColors.systemRed,
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
              style: const TextStyle(fontSize: 16, color: CupertinoColors.black, height: 1.4),
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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue),
        ),
        const SizedBox(height: 16),
        if (historico.isEmpty)
          const Text('Nenhuma atividade ainda.', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    if (item['nivel'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Nível: ${item['nivel']}', style: const TextStyle(fontSize: 14, color: CupertinoColors.activeBlue)),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Sua resposta: ${item['resposta'] ?? ''}',
                      style: const TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isCorrect ? CupertinoIcons.check_mark_circled : CupertinoIcons.clear_circled,
                          color: isCorrect ? CupertinoColors.activeGreen : CupertinoColors.systemRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['correta'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect ? CupertinoColors.activeGreen : CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                    if (item['explicacao'] != null && item['explicacao']!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Explicação: ${item['explicacao']}', style: const TextStyle(color: CupertinoColors.activeBlue)),
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
