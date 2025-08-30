import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'screens/game_screen.dart';
import 'screens/gemini_config_screen.dart';
import 'package:flutter/material.dart';
import '../services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            _error =
                'Serviço Gemini não está acessível. Verifique sua chave API.';
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
    showCupertinoDialog(
      context: context,
      builder: (context) => const GeminiConfigScreen(),
    ).then((_) => _checkGemini());
  }

  void _openHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historicoJson = prefs.getString('historico_perguntas');
    if (historicoJson != null) {
      jsonDecode(historicoJson);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Bem-vindo'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CupertinoActivityIndicator()
              : Row(
                  children: [
                    // Menu à esquerda (padrão Ren'Py)
                    Container(
                      width: 220,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CupertinoButton(
                            onPressed: _startGame,
                            borderRadius: BorderRadius.circular(12),
                            child: Text(
                              _error == null
                                  ? 'Iniciar Jogo'
                                  : 'Configurar API',
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            onPressed: _goToConfig,
                            borderRadius: BorderRadius.circular(12),
                            child: const Text(
                              'Configurações',
                            ),
                          ),
                          const SizedBox(height: 16),
                          CupertinoButton(
                            onPressed: _openHistory,
                            borderRadius: BorderRadius.circular(12),
                            child: const Text(
                              'Histórico',
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              _error!,
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Nome do jogo à direita
                    const Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(height: 32),
                            Text(
                              'Adaptive Check',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Tutor de Conhecimento Adaptativo',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Desafie-se e melhore suas habilidades e conhecimentos com a ajuda da IA Gemini.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                              ),
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
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bool isDark = brightness == Brightness.dark;
    return CupertinoApp(
      title: 'Adaptive Check',
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: isDark ? CupertinoColors.white : CupertinoColors.black,
        scaffoldBackgroundColor:
            isDark ? CupertinoColors.black : CupertinoColors.white,
        barBackgroundColor:
            isDark ? CupertinoColors.black : CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
              fontSize: 18,
              color: isDark ? CupertinoColors.white : CupertinoColors.black),
          navTitleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black),
        ),
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
