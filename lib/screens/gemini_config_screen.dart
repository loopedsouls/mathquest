import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_screen.dart';
import '../services/gemini_service.dart';

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
      status = isAvailable
          ? 'Conexão com Gemini funcionando!'
          : 'Erro na conexão com Gemini.';
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
