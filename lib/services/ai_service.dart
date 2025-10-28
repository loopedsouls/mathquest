// Firebase AI Service - Único serviço de IA do MathQuest
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'firebase_ai_service.dart';

/// Interface para serviços de IA
abstract class AIService {
  Future<String> gerarResposta(String pergunta, String contexto);
  Future<bool> isServiceAvailable();
  String get serviceName;
  Future<String> generate(String prompt, {String? context});
}

/// Serviço principal que usa Firebase AI (Gemini)
class GeminiService implements AIService {
  final String? apiKey;

  GeminiService({this.apiKey});

  @override
  String get serviceName => 'Firebase AI (Gemini)';

  @override
  Future<bool> isServiceAvailable() async {
    return FirebaseAIService.isAvailable;
  }

  @override
  Future<String> gerarResposta(String pergunta, String contexto) async {
    try {
      final resposta = await FirebaseAIService.gerarExplicacaoMatematica(
        problema: pergunta,
        ano: _extrairAno(contexto),
        unidade: _extrairUnidade(contexto),
      );

      return resposta ?? _respostaFallback(pergunta);
    } catch (e) {
      if (kDebugMode) {
        print('Erro no GeminiService: $e');
      }
      return _respostaFallback(pergunta);
    }
  }

  String _extrairAno(String contexto) {
    const anos = ['6º ano', '7º ano', '8º ano', '9º ano'];
    for (String ano in anos) {
      if (contexto.toLowerCase().contains(ano.toLowerCase())) {
        return ano;
      }
    }
    return '8º ano';
  }

  String _extrairUnidade(String contexto) {
    const unidades = [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ];

    for (String unidade in unidades) {
      if (contexto.toLowerCase().contains(unidade.toLowerCase())) {
        return unidade;
      }
    }
    return 'Números';
  }

  String _respostaFallback(String pergunta) {
    return 'Firebase AI não disponível. Configure no Firebase Console.\\n\\nPergunta: $pergunta';
  }

  Map<String, dynamic> getStatus() {
    return {
      'service_name': serviceName,
      'available': FirebaseAIService.isAvailable,
    };
  }

  // Método para compatibilidade com código antigo
  @override
  Future<String> generate(String prompt, {String? context}) async {
    return await gerarResposta(prompt, context ?? '');
  }
}

/// Compatibilidade - Ollama removido
@Deprecated('Use GeminiService')
class OllamaService implements AIService {
  OllamaService({String? baseUrl, String? defaultModel});

  @override
  String get serviceName => 'Ollama (Removido)';

  @override
  Future<bool> isServiceAvailable() async => false;

  @override
  Future<String> gerarResposta(String pergunta, String contexto) async {
    return 'Ollama removido. Use Firebase AI.';
  }

  // Métodos depreciados para compatibilidade
  Future<bool> isOllamaRunning() async => false;
  Future<List<String>> listModels() async => [];
  @override
  Future<String> generate(String prompt, {String? context}) async {
    return await gerarResposta(prompt, context ?? '');
  }
}

/// Compatibilidade - SmartAIService removido
@Deprecated('Use GeminiService')
class SmartAIService implements AIService {
  SmartAIService();

  @override
  String get serviceName => 'Smart AI (Removido)';

  @override
  Future<bool> isServiceAvailable() async => true;

  @override
  Future<String> gerarResposta(String pergunta, String contexto) async {
    final gemini = GeminiService();
    return await gemini.gerarResposta(pergunta, contexto);
  }

  @override
  Future<String> generate(String prompt, {String? context}) async {
    return await gerarResposta(prompt, context ?? '');
  }

  Future<String> getCurrentService() async => serviceName;
}

/// Compatibilidade - MathTutorService removido
@Deprecated('Use Firebase AI directly')
class MathTutorService {
  final AIService aiService;

  MathTutorService({required this.aiService});

  Future<String> gerarExplicacao(String problema, {String? contexto}) async {
    return await aiService.gerarResposta(problema, contexto ?? '');
  }

  Future<String> generate(String prompt, {String? context}) async {
    return await aiService.gerarResposta(prompt, context ?? '');
  }

  Future<bool> verificarResposta(String resposta, String gabarito) async {
    return resposta.toLowerCase().contains(gabarito.toLowerCase());
  }
}

/// Compatibilidade - FlutterGemmaService removido
@Deprecated('Use Firebase AI')
class FlutterGemmaService implements AIService {
  FlutterGemmaService(
      {void Function(String)? onStatusUpdate,
      void Function(double)? onDownloadProgress});

  @override
  String get serviceName => 'Flutter Gemma (Removido)';

  @override
  Future<bool> isServiceAvailable() async => false;

  @override
  Future<String> gerarResposta(String pergunta, String contexto) async {
    return 'Flutter Gemma removido. Use Firebase AI.';
  }

  // Métodos para compatibilidade
  @override
  Future<String> generate(String prompt, {String? context}) async {
    return await gerarResposta(prompt, context ?? '');
  }

  Future<Map<String, dynamic>> getModelInfo() async => {};
  Future<void> forceDownloadModel() async {}
}

/// Compatibilidade - AIQueueService removido
@Deprecated('Use Firebase AI directly')
class AIQueueService {
  AIQueueService();

  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  List<String> get queue => [];
  List<String> get activeRequests => [];

  Future<void> addToQueue(String request) async {}
  Future<String> addRequest(String request) async {
    // Usar Firebase AI diretamente
    final gemini = GeminiService();
    return await gemini.gerarResposta(request, '');
  }

  Map<String, dynamic> getQueueInfo() => {
        'queueLength': 0,
        'activeRequests': 0,
        'pendingRequests': 0,
      };

  void clearAll() {}

  Stream<int> get queueLength => Stream.value(0);
  bool get isProcessing => false;
}

/// Compatibilidade - CacheIAService removido
@Deprecated('Use Firebase AI directly')
class CacheIAService {
  static Future<void> limparCache() async {}
  static Future<void> configurarCache({bool? enabled}) async {}
  static Future<Map<String, dynamic>> getStatus() async => {};
  static Future<Map<String, dynamic>?> obterPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async =>
      null;
  static Future<void> preCarregarCache({
    required String unidade,
    required String ano,
    required int quantidadePorTipo,
  }) async {}
  static Future<Map<String, dynamic>> obterEstatisticasCache() async => {};
  static Future<void> otimizarCache() async {}
}
