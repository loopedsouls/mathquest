import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';
import 'preload_service.dart';

class CacheIAService {
  static const int _maxCachePorParametro = 50; // Máximo de perguntas por combinação
  static const int _diasExpiracao = 30; // Cache expira em 30 dias
  static const double _taxaUsoCache = 0.7; // 70% das vezes usa cache, 30% gera nova

  // Estatísticas de cache
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _perguntasGeradas = 0;

  /// Gera ou busca uma pergunta do cache de forma inteligente
  static Future<Map<String, dynamic>?> obterPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    String? fonteIA,
  }) async {
    try {
      // Verifica se o modo preload está ativo e há créditos
      final preloadEnabled = await PreloadService.isPreloadEnabled();
      final hasCredits = await PreloadService.hasCredits();
      
      // Se preload ativo e há créditos, SEMPRE prioriza cache
      bool deveUsarCache;
      if (preloadEnabled && hasCredits) {
        deveUsarCache = true;
        if (kDebugMode) {
          print('🎯 Modo preload ativo - priorizando cache');
        }
      } else {
        // Decide normalmente se deve usar cache ou gerar nova pergunta
        deveUsarCache = await _deveUsarCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipoQuiz,
          dificuldade: dificuldade,
        );
      }

      Map<String, dynamic>? pergunta;

      if (deveUsarCache) {
        // Tenta buscar no cache primeiro
        pergunta = await DatabaseService.buscarPerguntaCache(
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
            print('🎯 Cache HIT: ${unidade}_${ano}_$tipoQuiz${creditUsed ? " (crédito usado)" : ""}');
          }
          
          // Se os créditos acabaram, inicia precarregamento em background
          if (preloadEnabled && !await PreloadService.hasCredits()) {
            _startBackgroundPreload();
          }
          
          return pergunta;
        } else if (preloadEnabled && hasCredits) {
          // Se modo preload ativo mas não achou no cache, força geração para manter créditos
          if (kDebugMode) {
            print('⚠️ Modo preload ativo mas pergunta não encontrada no cache');
          }
        }
      }

      // Cache miss ou decisão de gerar nova - gera pergunta via IA
      _cacheMisses++;
      _perguntasGeradas++;
      
      if (kDebugMode) {
              
      if (kDebugMode) {
        print('🔄 Gerando nova pergunta: ${unidade}_${ano}_$tipoQuiz');
      }
      }
      
      pergunta = await _gerarNovaPergunta(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
        fonteIA: fonteIA,
      );

      if (pergunta != null) {
        // Salva no cache para uso futuro
        await _salvarNoCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipoQuiz,
          dificuldade: dificuldade,
          pergunta: pergunta,
          fonteIA: fonteIA ?? 'gemini',
        );

        // Gerencia o tamanho do cache
        await _gerenciarTamanhoCache(
          unidade: unidade,
          ano: ano,
          tipoQuiz: tipoQuiz,
          dificuldade: dificuldade,
        );
      }

      return pergunta;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter pergunta: $e');
      }
      return null;
    }
  }

  /// Decide se deve usar cache baseado em estatísticas e disponibilidade
  static Future<bool> _deveUsarCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    // Conta quantas perguntas existem no cache para estes parâmetros
    final countCache = await DatabaseService.contarPerguntasCache(
      unidade: unidade,
      ano: ano,
      tipoQuiz: tipoQuiz,
      dificuldade: dificuldade,
    );

    // Se não há perguntas no cache, deve gerar
    if (countCache == 0) return false;

    // Se há poucas perguntas (menos de 5), gera mais algumas
    if (countCache < 5) {
      return Random().nextDouble() < 0.3; // 30% chance de usar cache
    }

    // Se há muitas perguntas, usa cache mais frequentemente
    if (countCache >= _maxCachePorParametro) {
      return Random().nextDouble() < 0.9; // 90% chance de usar cache
    }

    // Chance normal de usar cache
    return Random().nextDouble() < _taxaUsoCache;
  }

  /// Gera uma nova pergunta via prompt direto (para integração com sistema atual)
  static Future<Map<String, dynamic>?> _gerarNovaPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    String? fonteIA,
  }) async {
    try {
      // Retorna null para que o sistema atual gere a pergunta
      // Esta função será expandida quando integrar diretamente com IA
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar pergunta via IA: $e');
      }
      return null;
    }
  }

  /// Salva a pergunta no cache
  static Future<void> _salvarNoCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
    required Map<String, dynamic> pergunta,
    required String fonteIA,
  }) async {
    try {
      await DatabaseService.salvarPerguntaCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
        pergunta: pergunta['pergunta'] as String,
        opcoes: pergunta['opcoes'] as List<String>?,
        respostaCorreta: pergunta['resposta_correta'] as String,
        explicacao: pergunta['explicacao'] as String?,
        fonteIA: fonteIA,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar no cache: $e');
      }
    }
  }

  /// Gerencia o tamanho do cache removendo perguntas antigas ou menos usadas
  static Future<void> _gerenciarTamanhoCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    try {
      final count = await DatabaseService.contarPerguntasCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );

      // Se excedeu o limite, remove perguntas antigas
      if (count > _maxCachePorParametro) {
        await DatabaseService.limparCacheAntigo(diasParaExpirar: _diasExpiracao);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerenciar cache: $e');
      }
    }
  }

  /// Pré-carrega perguntas no cache para melhorar a experiência
  static Future<void> preCarregarCache({
    required String unidade,
    required String ano,
    int quantidadePorTipo = 10,
  }) async {
    final tiposQuiz = ['multipla_escolha', 'verdadeiro_falso', 'complete_frase'];
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
      final totalPerguntas = await DatabaseService.contarPerguntasCache();
      final estatisticasDB = await DatabaseService.obterEstatisticasGerais();
      
      final totalRequests = _cacheHits + _cacheMisses;
      final taxaAcertoCache = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

      return {
        'total_perguntas_cache': totalPerguntas,
        'cache_hits': _cacheHits,
        'cache_misses': _cacheMisses,
        'perguntas_geradas': _perguntasGeradas,
        'taxa_acerto_cache': taxaAcertoCache,
        'tamanho_cache_bytes': estatisticasDB['tamanho_cache_bytes'],
        'eficiencia_cache': totalRequests > 0 ? '${(taxaAcertoCache * 100).toStringAsFixed(1)}%' : '0%',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter estatísticas: $e');
      }
      return {};
    }
  }

  /// Obtém estatísticas detalhadas por parâmetros
  static Future<Map<String, Map<String, int>>> obterEstatisticasDetalhadas() async {
    try {
      Map<String, Map<String, int>> estatisticas = {};
      
      final unidades = ['Números', 'Álgebra', 'Geometria', 'Grandezas e Medidas', 'Probabilidade e Estatística'];
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
