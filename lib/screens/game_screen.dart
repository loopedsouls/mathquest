import 'package:flutter/cupertino.dart';
import '../../services/tutor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameScreen extends StatefulWidget {
  final String? apiKey;
  const GameScreen({super.key, this.apiKey});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TutorService tutorService;
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

    tutorService = TutorService(apiKey: apiKey);
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
    pergunta = await tutorService.gerarPergunta(
        area: 'matemática', nivelDificuldade: _niveis[_nivelDificuldade]);
    setState(() => carregando = false);
  }

  Future<void> _verificarResposta() async {
    setState(() => carregando = true);
    final resposta = _respostaController.text.trim();
    if (resposta.isEmpty) {
      setState(() => carregando = false);
      return;
    }

    final resultado = await tutorService.verificarResposta(
        area: 'matemática', pergunta: pergunta, resposta: resposta);
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
        area: 'matemática',
        pergunta: pergunta,
        respostaCorreta: 'Resposta correta',
        respostaUsuario: _respostaController.text);
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
