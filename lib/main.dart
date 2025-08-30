import 'package:flutter/cupertino.dart';
import 'screens/gemini_config_screen.dart';
import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../services/gemini_service.dart';

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
                    const Icon(CupertinoIcons.book_solid,
                        size: 80, color: CupertinoColors.activeBlue),
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
                        style: const TextStyle(
                            color: CupertinoColors.systemRed, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CupertinoButton.filled(
                      onPressed: _startGame,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                          _error == null ? 'Iniciar Jogo' : 'Configurar API',
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: _goToConfig,
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(12),
                      child: const Text('Configurações',
                          style: TextStyle(fontSize: 16)),
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
    return const CupertinoApp(
      title: 'Adaptive Check',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
      ),
      home: StartScreen(),
    );
  }
}
