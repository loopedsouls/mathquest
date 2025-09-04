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
  static const int _totalQuestions = 100;
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
    {'unidade': 'probabilidade e estatística', 'ano': '2º ano', 'dificuldade': 'fácil'},
    {'unidade': 'probabilidade e estatística', 'ano': '3º ano', 'dificuldade': 'fácil'},
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

    final prefs = await SharedPreferences.getInstance();
    final lastPreload = prefs.getInt(_lastPreloadKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Precarrega se passou mais de 24 horas ou se nunca foi feito
    const oneDayMs = 24 * 60 * 60 * 1000;
    return (now - lastPreload) > oneDayMs;
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

      onProgress(0, _totalQuestions, 'Iniciando precarregamento...');

      final random = Random();
      int generated = 0;
      int failures = 0;
      const maxFailures = 10;

      for (int i = 0; i < _totalQuestions && failures < maxFailures; i++) {
        try {
          // Seleciona aleatoriamente um tópico e tipo de quiz
          final topic = _topics[random.nextInt(_topics.length)];
          final quizType = _quizTypes[random.nextInt(_quizTypes.length)];
          
          onProgress(i + 1, _totalQuestions, 
            'Gerando pergunta ${i + 1}/$_totalQuestions\n'
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

      // Atualiza timestamp do último precarregamento
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastPreloadKey, DateTime.now().millisecondsSinceEpoch);

      onProgress(_totalQuestions, _totalQuestions, 
        'Precarregamento concluído!\n'
        'Geradas: $generated perguntas\n'
        'Falhas: $failures');

    } catch (e) {
      onProgress(0, _totalQuestions, 'Erro: $e');
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
      final jsonResponse = response.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = json.decode(jsonResponse);
      
      // Salva no cache com dados estruturados
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
    } catch (e) {
      // Se falhar o parse, salva a resposta bruta
      await DatabaseService.salvarPerguntaCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
        pergunta: response,
        respostaCorreta: 'A', // padrão
        fonteIA: iaService.runtimeType.toString(),
      );
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
