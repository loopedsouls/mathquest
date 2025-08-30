import 'package:flutter/cupertino.dart';
import 'screens/game_screen.dart';
import 'screens/gemini_config_screen.dart';
import 'package:flutter/material.dart';
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(CupertinoIcons.book_solid,
                              size: 80, color: CupertinoColors.activeBlue),
                          SizedBox(height: 24),
                          Text(
                            'Tutor de Conheciimento Adaptativo',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Desafie-se e melhore suas habilidades e conhecimentos com a ajuda da IA Gemini.',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_error != null) ...[
                            Text(
                              _error!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                          ],
                          CupertinoButton.filled(
                            onPressed: _startGame,
                            borderRadius: BorderRadius.circular(12),
                            child: Text(
                                _error == null
                                    ? 'Iniciar Jogo'
                                    : 'Configurar API',
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
        // Desktop focus: fontes maiores, padding extra, visual mais "flat"
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontSize: 18),
          navTitleTextStyle:
              TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        barBackgroundColor: CupertinoColors.systemGrey5,
      ),
      home: StartScreen(),
      // Desktop: remove debug banner, usa scrollbars nativos
      debugShowCheckedModeBanner: false,
    );
  }
}
