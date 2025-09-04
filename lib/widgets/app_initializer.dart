import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/preload_service.dart';
import '../screens/start_screen.dart';
import '../screens/preload_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _checkingPreload = true;
  bool _shouldPreload = false;
  String _selectedAI = 'gemini';
  String? _apiKey;
  String? _ollamaModel;

  @override
  void initState() {
    super.initState();
    _checkPreloadStatus();
  }

  Future<void> _checkPreloadStatus() async {
    try {
      // Carrega configurações
      final prefs = await SharedPreferences.getInstance();
      _selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      _apiKey = prefs.getString('gemini_api_key');
      _ollamaModel = prefs.getString('modelo_ollama') ?? 'llama2';

      // Verifica se deve fazer precarregamento
      final shouldPreload = await PreloadService.shouldPreload();
      
      setState(() {
        _shouldPreload = shouldPreload;
        _checkingPreload = false;
      });
    } catch (e) {
      // Em caso de erro, pula o precarregamento
      setState(() {
        _shouldPreload = false;
        _checkingPreload = false;
      });
    }
  }

  void _onPreloadComplete() {
    setState(() {
      _shouldPreload = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingPreload) {
      // Mostra uma tela de loading simples enquanto verifica
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0B),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_shouldPreload) {
      // Mostra a tela de precarregamento com mini-jogo
      return PreloadScreen(
        selectedAI: _selectedAI,
        apiKey: _apiKey,
        ollamaModel: _ollamaModel,
        onComplete: _onPreloadComplete,
      );
    }

    // Mostra a tela principal
    return const StartScreen();
  }
}
