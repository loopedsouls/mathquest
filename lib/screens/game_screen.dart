import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  final List<String> _tiposJogo = [
    'matemática',
    'quiz',
    'lógica',
    'palavras cruzadas',
    'forca',
    'adivinhação',
  ];
  String _tipoSelecionado = 'matemática';

  @override
  void initState() {
    super.initState();
    _initializeService().then((_) {
      _carregarHistorico().then((_) => gerarNovaPergunta());
    });
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
        area: _tipoSelecionado, nivelDificuldade: _niveis[_nivelDificuldade]);
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
        area: _tipoSelecionado, pergunta: pergunta, resposta: resposta);
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
        area: _tipoSelecionado,
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
        middle: Text('LLM the Game'),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Menu lateral estilo Ren'Py
            Container(
              width: 220,
              color: const Color(0xFFEEEEEE),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Text('Jogos',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ..._tiposJogo.map((tipo) => CupertinoButton(
                        onPressed: () {
                          setState(() {
                            _tipoSelecionado = tipo;
                          });
                          gerarNovaPergunta();
                        },
                        borderRadius: BorderRadius.circular(8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(tipo[0].toUpperCase() + tipo.substring(1),
                            style: const TextStyle(fontSize: 18)),
                      )),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Fechar',
                        pageBuilder: (context, _, __) {
                          return SafeArea(
                            child: Container(
                              color: const Color(0xFFEEEEEE),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 24),
                                    color: const Color(0xFFDDDDDD),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Histórico',
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold)),
                                        CupertinoButton(
                                          padding: EdgeInsets.zero,
                                          child: const Text('Fechar'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Ver Histórico',
                        style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Conteúdo principal à direita
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(32.0),
                children: [
                  Text(
                    _tipoSelecionado[0].toUpperCase() +
                        _tipoSelecionado.substring(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  carregando
                      ? const Column(
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(height: 16),
                            Text('Carregando pergunta da IA...'),
                          ],
                        )
                      : _buildQuestionCardCupertino(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCardCupertino() {
    // Adaptação para tipos de jogos específicos
    if (_tipoSelecionado == 'forca') {
      return Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Jogo da Forca',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                pergunta,
                key: ValueKey<String>(pergunta),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoTextField(
              controller: _respostaController,
              placeholder: 'Digite uma letra ou palavra',
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              style: const TextStyle(fontSize: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _verificarResposta,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Verificar', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 24),
            _buildFeedbackSectionCupertino(),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: gerarNovaPergunta,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Nova Palavra', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );
    }
    // Para outros tipos não implementados, exibe mensagem
    if (_tipoSelecionado == 'palavras cruzadas') {
      return Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32.0),
        child: const Center(
          child: Text(
            'Palavras cruzadas: Em breve!',
            style: TextStyle(fontSize: 22),
          ),
        ),
      );
    }
    // ...existing code...
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nível: ${_niveis[_nivelDificuldade].toUpperCase()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              pergunta,
              key: ValueKey<String>(pergunta),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          CupertinoTextField(
            controller: _respostaController,
            placeholder: 'Sua Resposta',
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            style: const TextStyle(fontSize: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCCCCCC)),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _verificarResposta,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Verificar', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 24),
          _buildFeedbackSectionCupertino(),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: gerarNovaPergunta,
            borderRadius: BorderRadius.circular(12),
            child: const Text('Nova Pergunta', style: TextStyle(fontSize: 18)),
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
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (feedback.isNotEmpty)
            Text(
              feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_respostaCorreta == false) ...[
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: mostrarExplicacao,
              borderRadius: BorderRadius.circular(12),
              child: const Text('Ver Explicação'),
            ),
          ],
          if (explicacao.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              explicacao,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
