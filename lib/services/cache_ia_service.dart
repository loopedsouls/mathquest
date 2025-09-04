import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';
import 'preload_service.dart';

class CacheIAService {
  static const int _maxCachePorParametro =
      50; // Máximo de perguntas por combinação
  static const int _diasExpiracao = 30; // Cache expira em 30 dias
  static const double _taxaUsoCache =
      0.7; // 70% das vezes usa cache, 30% gera nova

  // Estatísticas de cache
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _perguntasGeradas = 0;

  /// Busca uma pergunta no cache (sem gerar nova)
  static Future<Map<String, dynamic>?> obterPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    String? fonteIA,
  }) async {
    try {
      // Garante que o banco está inicializado antes de qualquer operação
      await DatabaseService.database;

      // Verifica se o modo preload está ativo e há créditos
      final preloadEnabled = await PreloadService.isPreloadEnabled();
      final hasCredits = await PreloadService.hasCredits();

      // Tenta buscar no cache
      final pergunta = await DatabaseService.buscarPerguntaCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );
      if (pergunta != null) {
        // Usa um crédito se disponível (só no modo preload)
        bool creditUsed = false;
        if (preloadEnabled && hasCredits) {
          creditUsed = await PreloadService.useCredit();
        }

        _cacheHits++;
        if (kDebugMode) {
          print(
              '🎯 Cache HIT: ${unidade}_${ano}_$tipoQuiz${creditUsed ? " (crédito usado)" : ""}');
        }

        // Se os créditos acabaram, inicia precarregamento em background
        if (preloadEnabled && !await PreloadService.hasCredits()) {
          _startBackgroundPreload();
        }

        return pergunta;
      }

      // Cache miss
      _cacheMisses++;
      if (kDebugMode) {
        print('❌ Cache MISS: ${unidade}_${ano}_$tipoQuiz');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar no cache: $e');
      }
      return null;
    }
  }

  /// Pré-carrega perguntas no cache para melhorar a experiência
  static Future<void> preCarregarCache({
    required String unidade,
    required String ano,
    int quantidadePorTipo = 10,
  }) async {
    // Garante que o banco está inicializado
    await DatabaseService.database;

    final tiposQuiz = [
      'multipla_escolha',
      'verdadeiro_falso',
      'complete_frase'
    ];
    final dificuldades = ['facil', 'medio', 'dificil', 'expert'];

    if (kDebugMode) {
      print('🔄 Pré-carregando cache para $unidade - $ano...');
    }

    for (final tipo in tiposQuiz) {
      for (final dif in dificuldades) {
        final countAtual = await DatabaseService.contarPerguntasCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipo,
          dificuldade: dif,
        );

        // Se tem menos que a quantidade mínima, gera mais
        if (countAtual < quantidadePorTipo) {
          final quantidadeGerar = quantidadePorTipo - countAtual;

          for (int i = 0; i < quantidadeGerar; i++) {
            await obterPergunta(
              unidade: unidade,
              ano: ano,
              tipoQuiz: tipo,
              dificuldade: dif,
            );

            // Pequena pausa para não sobrecarregar a IA
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      }
    }

    if (kDebugMode) {
      print('✅ Cache pré-carregado para $unidade - $ano');
    }
  }

  /// Limpa todo o cache (útil para testes ou reset)
  static Future<void> limparTodoCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      await DatabaseService.limparCacheAntigo(diasParaExpirar: 0);
      _resetarEstatisticas();
      if (kDebugMode) {
        print('🗑️ Cache completamente limpo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao limpar cache: $e');
      }
    }
  }

  /// Obtém estatísticas do cache
  static Future<Map<String, dynamic>> obterEstatisticasCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      final totalPerguntas = await DatabaseService.contarPerguntasCache();
      final estatisticasDB = await DatabaseService.obterEstatisticasGerais();

      final totalRequests = _cacheHits + _cacheMisses;
      final taxaAcertoCache =
          totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

      return {
        'total_perguntas_cache': totalPerguntas,
        'cache_hits': _cacheHits,
        'cache_misses': _cacheMisses,
        'perguntas_geradas': _perguntasGeradas,
        'taxa_acerto_cache': taxaAcertoCache,
        'tamanho_cache_bytes': estatisticasDB['tamanho_cache_bytes'],
        'eficiencia_cache': totalRequests > 0
            ? '${(taxaAcertoCache * 100).toStringAsFixed(1)}%'
            : '0%',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas: $e');
      }
      return {};
    }
  }

  /// Obtém estatísticas detalhadas por parâmetros
  static Future<Map<String, Map<String, int>>>
      obterEstatisticasDetalhadas() async {
    try {
      Map<String, Map<String, int>> estatisticas = {};

      final unidades = [
        'Números',
        'Álgebra',
        'Geometria',
        'Grandezas e Medidas',
        'Probabilidade e Estatística'
      ];
      final anos = ['6º ano', '7º ano', '8º ano', '9º ano'];
      final tipos = ['multipla_escolha', 'verdadeiro_falso', 'complete_frase'];

      for (final unidade in unidades) {
        estatisticas[unidade] = {};

        for (final ano in anos) {
          int totalUnidadeAno = 0;

          for (final tipo in tipos) {
            final count = await DatabaseService.contarPerguntasCache(
              unidade: unidade,
              ano: ano,
              tipoQuiz: tipo,
            );
            totalUnidadeAno += count;
          }

          estatisticas[unidade]![ano] = totalUnidadeAno;
        }
      }

      return estatisticas;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas detalhadas: $e');
      }
      return {};
    }
  }

  /// Reseta as estatísticas em memória
  static void _resetarEstatisticas() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _perguntasGeradas = 0;
  }

  /// Otimiza o cache removendo perguntas duplicadas ou inválidas
  static Future<void> otimizarCache() async {
    try {
      // Garante que o banco está inicializado
      await DatabaseService.database;

      if (kDebugMode) {
        print('🔧 Otimizando cache...');
      }

      // Remove perguntas antigas
      await DatabaseService.limparCacheAntigo(diasParaExpirar: _diasExpiracao);

      if (kDebugMode) {
        print('✅ Cache otimizado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao otimizar cache: $e');
      }
    }
  }

  /// Inicia precarregamento em background quando créditos acabam
  static void _startBackgroundPreload() {
    // Executa em background sem bloquear a UI
    Future.microtask(() async {
      try {
        if (await PreloadService.shouldPreload()) {
          if (kDebugMode) {
            print('🔄 Iniciando precarregamento em background...');
          }

          // Carrega configurações para o precarregamento
          final prefs = await SharedPreferences.getInstance();
          final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
          final apiKey = prefs.getString('gemini_api_key');
          final ollamaModel = prefs.getString('modelo_ollama') ?? 'llama2';

          await PreloadService.startPreload(
            selectedAI: selectedAI,
            apiKey: selectedAI == 'gemini' ? apiKey : null,
            ollamaModel: selectedAI == 'ollama' ? ollamaModel : null,
            onProgress: (current, total, status) {
              if (kDebugMode) {
                print('📊 Precarregamento: $current/$total - $status');
              }
            },
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Erro no precarregamento em background: $e');
        }
      }
    });
  }
}
