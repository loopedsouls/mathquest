import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'ia_service.dart';

class PreloadService {
  static const String _preloadEnabledKey = 'preload_enabled';
  static const String _lastPreloadKey = 'last_preload_timestamp';
  static const String _creditsKey = 'preload_credits';
  static const String _preloadQuantityKey = 'preload_quantity';
  static const int _defaultQuantity = 100;
  static bool _isPreloading = false;

  /// Lista de tópicos para precarregar
  static const List<Map<String, String>> _topics = [
    {'unidade': 'números e operações', 'ano': '1º ano', 'dificuldade': 'fácil'},
    {'unidade': 'números e operações', 'ano': '1º ano', 'dificuldade': 'médio'},
    {'unidade': 'números e operações', 'ano': '2º ano', 'dificuldade': 'fácil'},
    {'unidade': 'números e operações', 'ano': '2º ano', 'dificuldade': 'médio'},
    {'unidade': 'álgebra', 'ano': '3º ano', 'dificuldade': 'fácil'},
    {'unidade': 'álgebra', 'ano': '3º ano', 'dificuldade': 'médio'},
    {'unidade': 'geometria', 'ano': '1º ano', 'dificuldade': 'fácil'},
    {'unidade': 'geometria', 'ano': '2º ano', 'dificuldade': 'fácil'},
    {'unidade': 'grandezas e medidas', 'ano': '1º ano', 'dificuldade': 'fácil'},
    {'unidade': 'grandezas e medidas', 'ano': '2º ano', 'dificuldade': 'fácil'},
    {
      'unidade': 'probabilidade e estatística',
      'ano': '2º ano',
      'dificuldade': 'fácil'
    },
    {
      'unidade': 'probabilidade e estatística',
      'ano': '3º ano',
      'dificuldade': 'fácil'
    },
  ];

  static const List<String> _quizTypes = [
    'múltipla escolha',
    'verdadeiro ou falso',
    'complete a frase'
  ];

  /// Verifica se o precarregamento está habilitado
  static Future<bool> isPreloadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_preloadEnabledKey) ?? false;
  }

  /// Habilita ou desabilita o precarregamento
  static Future<void> setPreloadEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_preloadEnabledKey, enabled);
  }

  /// Verifica se é necessário fazer precarregamento
  static Future<bool> shouldPreload() async {
    if (!await isPreloadEnabled()) return false;
    if (_isPreloading) return false;

    // Verifica se há créditos suficientes
    final credits = await getCredits();
    if (credits > 0) return false; // Ainda há créditos, não precisa precarregar

    // Verifica se a IA está disponível antes de tentar precarregar
    if (!await _isAIAvailable()) return false;

    return true;
  }

  /// Verifica se a IA está disponível
  static Future<bool> _isAIAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';

      if (selectedAI == 'gemini') {
        final apiKey = prefs.getString('gemini_api_key');
        if (apiKey == null || apiKey.isEmpty) return false;

        final gemini = GeminiService(apiKey: apiKey);
        return await gemini.isServiceAvailable();
      } else if (selectedAI == 'ollama') {
        final ollama = OllamaService();
        return await ollama.isOllamaRunning();
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtém o número atual de créditos
  static Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final credits = prefs.getInt(_creditsKey) ?? 0;

    // Log de debug temporário
    if (kDebugMode) {
      print('💰 Créditos lidos: $credits');
    }

    return credits;
  }

  /// Define o número de créditos
  static Future<void> setCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditsKey, credits);
    // Força a sincronização para garantir que os dados sejam salvos imediatamente
    await prefs.reload();

    // Log de debug temporário
    if (kDebugMode) {
      print('💰 Créditos salvos: $credits');
    }
  }

  /// Usa um crédito (retorna true se foi possível usar)
  static Future<bool> useCredit() async {
    final currentCredits = await getCredits();
    if (currentCredits > 0) {
      await setCredits(currentCredits - 1);

      // Log de debug temporário
      if (kDebugMode) {
        print('💰 Crédito usado: $currentCredits -> ${currentCredits - 1}');
      }

      return true;
    }

    // Log de debug temporário
    if (kDebugMode) {
      print('💰 Sem créditos para usar: $currentCredits');
    }

    return false;
  }

  /// Verifica se há créditos disponíveis
  static Future<bool> hasCredits() async {
    final credits = await getCredits();
    return credits > 0;
  }

  /// Obtém a quantidade configurada de perguntas para precarregar
  static Future<int> getPreloadQuantity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_preloadQuantityKey) ?? _defaultQuantity;
  }

  /// Define a quantidade de perguntas para precarregar
  static Future<void> setPreloadQuantity(int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_preloadQuantityKey, quantity);
  }

  /// Inicia o precarregamento de perguntas
  static Future<void> startPreload({
    required Function(int current, int total, String status) onProgress,
    required String selectedAI,
    String? apiKey,
    String? ollamaModel,
  }) async {
    if (_isPreloading) return;

    _isPreloading = true;

    try {
      // PRIMEIRO: Inicializa o banco de dados para garantir que está pronto
      try {
        await DatabaseService.database;
        onProgress(0, 1, 'Banco de dados inicializado com sucesso');
      } catch (dbError) {
        onProgress(0, 1, 'Erro na inicialização do banco: $dbError');
        // Continua mesmo com erro de banco, pois pode não ser crítico para o preload
      }

      // Obtém a quantidade configurada de perguntas
      final totalQuestions = await getPreloadQuantity();

      // Inicializa o serviço de IA
      late AIService iaService;

      if (selectedAI == 'gemini') {
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('API Key do Gemini não configurada');
        }
        iaService = GeminiService(apiKey: apiKey);
      } else if (selectedAI == 'ollama') {
        final ollama = OllamaService();
        if (!await ollama.isOllamaRunning()) {
          throw Exception('Ollama não está rodando');
        }
        iaService = ollama;
      } else {
        throw Exception('Serviço de IA não suportado: $selectedAI');
      }

      onProgress(0, totalQuestions, 'Iniciando precarregamento...');

      final random = Random();
      int generated = 0;
      int failures = 0;
      const maxFailures = 10;

      for (int i = 0; i < totalQuestions && failures < maxFailures; i++) {
        try {
          // Seleciona aleatoriamente um tópico e tipo de quiz
          final topic = _topics[random.nextInt(_topics.length)];
          final quizType = _quizTypes[random.nextInt(_quizTypes.length)];

          onProgress(
              i + 1,
              totalQuestions,
              'Gerando pergunta ${i + 1}/$totalQuestions\n'
              '${topic['unidade']} - ${topic['ano']}\n'
              'Tipo: $quizType');

          // Gera a pergunta
          await _generateAndCacheQuestion(
            iaService: iaService,
            unidade: topic['unidade']!,
            ano: topic['ano']!,
            tipoQuiz: quizType,
            dificuldade: topic['dificuldade']!,
          );

          generated++;

          // Pequena pausa para não sobrecarregar
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failures++;
          if (kDebugMode) {
            print('Erro ao gerar pergunta ${i + 1}: $e');
          }
        }
      }

      // Atualiza timestamp do último precarregamento e define créditos
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastPreloadKey, DateTime.now().millisecondsSinceEpoch);

      // Define créditos baseado no número de perguntas geradas com sucesso
      await setCredits(generated);

      // Força a sincronização dos dados para garantir que foram salvos
      await prefs.reload();

      onProgress(
          totalQuestions,
          totalQuestions,
          'Precarregamento concluído!\n'
          'Geradas: $generated perguntas\n'
          'Créditos disponíveis: $generated\n'
          'Falhas: $failures');
    } catch (e) {
      final totalQuestions = await getPreloadQuantity();
      onProgress(0, totalQuestions, 'Erro: $e');
      rethrow;
    } finally {
      _isPreloading = false;
    }
  }

  /// Gera e armazena uma pergunta no cache
  static Future<void> _generateAndCacheQuestion({
    required AIService iaService,
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    // Garante que o banco está inicializado antes de salvar
    try {
      await DatabaseService.database;
    } catch (dbError) {
      if (kDebugMode) {
        print('Aviso: Erro de banco ignorado durante preload: $dbError');
      }
      // Continua mesmo com erro de banco
    }

    String prompt = '';

    switch (tipoQuiz) {
      case 'múltipla escolha':
        prompt = '''
Crie uma questão de múltipla escolha de matemática para o $ano sobre "$unidade" com dificuldade $dificuldade.

Formato de resposta (JSON):
{
  "pergunta": "texto da pergunta",
  "opcoes": ["A) opção1", "B) opção2", "C) opção3", "D) opção4"],
  "resposta_correta": "A",
  "explicacao": "explicação detalhada da resolução"
}
''';
        break;

      case 'verdadeiro ou falso':
        prompt = '''
Crie uma questão verdadeiro ou falso de matemática para o $ano sobre "$unidade" com dificuldade $dificuldade.

Formato de resposta (JSON):
{
  "pergunta": "texto da pergunta",
  "resposta_correta": "Verdadeiro",
  "explicacao": "explicação detalhada"
}
''';
        break;

      case 'complete a frase':
        prompt = '''
Crie uma questão de completar a frase de matemática para o $ano sobre "$unidade" com dificuldade $dificuldade.

Formato de resposta (JSON):
{
  "pergunta": "texto com lacuna marcada por ___",
  "resposta_correta": "palavra ou número que completa",
  "explicacao": "explicação detalhada"
}
''';
        break;
    }

    // Gera a pergunta
    final response = await iaService.generate(prompt);

    try {
      // Tenta fazer parse do JSON para extrair dados
      final jsonResponse =
          response.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = json.decode(jsonResponse);

      // Tenta salvar no cache com dados estruturados
      try {
        await DatabaseService.salvarPerguntaCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipoQuiz,
          dificuldade: dificuldade,
          pergunta: decoded['pergunta'] ?? response,
          opcoes: decoded['opcoes']?.cast<String>(),
          respostaCorreta: decoded['resposta_correta'] ?? 'A',
          explicacao: decoded['explicacao'],
          fonteIA: iaService.runtimeType.toString(),
        );
      } catch (dbError) {
        if (kDebugMode) {
          print('Erro ao salvar no banco (dados estruturados): $dbError');
        }
        // Ignora erro de banco durante preload
      }
    } catch (e) {
      // Se falhar o parse, tenta salvar a resposta bruta
      try {
        await DatabaseService.salvarPerguntaCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipoQuiz,
          dificuldade: dificuldade,
          pergunta: response,
          respostaCorreta: 'A', // padrão
          fonteIA: iaService.runtimeType.toString(),
        );
      } catch (dbError) {
        if (kDebugMode) {
          print('Erro ao salvar no banco (resposta bruta): $dbError');
        }
        // Ignora erro de banco durante preload
      }
    }
  }

  /// Obtém estatísticas do cache
  static Future<Map<String, int>> getCacheStats() async {
    // Implementação simples - retorna dados básicos
    return {
      'total_perguntas': 0,
      'perguntas_hoje': 0,
      'cache_hits': 0,
    };
  }

  /// Limpa todo o cache de perguntas
  static Future<void> clearCache() async {
    // Usa o método disponível para limpar cache antigo
    await DatabaseService.limparCacheAntigo(diasParaExpirar: 0);
  }

  /// Verifica se está em processo de precarregamento
  static bool get isPreloading => _isPreloading;
}
