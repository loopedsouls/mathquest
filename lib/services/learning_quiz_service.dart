import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/learning_quiz_model.dart';
import 'data_database_service.dart';
import 'learning_quiz_helper_service.dart';

/// Serviço para gerenciar lógica de quizzes
///
/// Centraliza operações relacionadas a:
/// - Geração de perguntas via IA ou cache
/// - Gerenciamento de sessões de quiz
/// - Cálculo de estatísticas
/// - Persistência de resultados
/// Serviço centralizado para gerenciamento de quizzes no módulo de aprendizado.
///
/// Esta classe fornece métodos para:
/// - Geração de perguntas via IA ou cache
/// - Gerenciamento de sessões de quiz
/// - Salvamento de histórico e estatísticas
/// - Limpeza de cache antigo
///
/// Todas as operações incluem tratamento de erros adequado e fallback gracioso.
class QuizService {
  static const String _historicoKey = 'historico_quiz';

  /// Gera pergunta via IA com fallback para cache
  static Future<QuizQuestion?> gerarPergunta({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    try {
      // Primeiro tenta obter do cache
      final perguntaCache = await _obterPerguntaDoCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );

      if (perguntaCache != null) {
        if (kDebugMode) {
          print('✅ Pergunta obtida do cache: ${perguntaCache.pergunta}');
        }
        return perguntaCache;
      }

      // Se não tem no cache, tenta gerar via IA
      if (kDebugMode) {
        print('🤖 Cache vazio, gerando via IA...');
      }

      final perguntaIA = await QuizHelperService.gerarPerguntaInteligente(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );

      if (perguntaIA != null) {
        // Salva no cache para futuras consultas
        await _salvarPerguntaNoCache(perguntaIA);
        return QuizQuestion.fromMap(perguntaIA);
      }

      // Fallback: retorna pergunta padrão se tudo falhar
      if (kDebugMode) {
        print('❌ Falha ao gerar pergunta, usando fallback');
      }

      return _criarPerguntaFallback(unidade, ano, tipoQuiz, dificuldade);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro crítico ao gerar pergunta: $e');
      }

      // Mesmo em erro crítico, tenta retornar fallback
      return _criarPerguntaFallback(unidade, ano, tipoQuiz, dificuldade);
    }
  }

  /// Obtém pergunta do cache local
  static Future<QuizQuestion?> _obterPerguntaDoCache({
    required String unidade,
    required String ano,
    required String tipoQuiz,
    required String dificuldade,
  }) async {
    try {
      final perguntaCache = await DatabaseService.buscarPerguntaCache(
        unidade: unidade,
        ano: ano,
        tipoQuiz: tipoQuiz,
        dificuldade: dificuldade,
      );

      if (perguntaCache != null) {
        return QuizQuestion.fromMap(perguntaCache);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter pergunta do cache: $e');
      }
      return null;
    }
  }

  /// Salva pergunta no cache
  static Future<void> _salvarPerguntaNoCache(Map<String, dynamic> pergunta) async {
    try {
      final opcoes = pergunta['opcoes'];
      List<String>? opcoesList;
      if (opcoes is List) {
        opcoesList = opcoes.map((e) => e.toString()).toList();
      }

      await DatabaseService.salvarPerguntaCache(
        unidade: pergunta['unidade'] ?? 'Números',
        ano: pergunta['ano'] ?? '7º ano',
        tipoQuiz: pergunta['tipo'] ?? 'multipla_escolha',
        dificuldade: pergunta['dificuldade'] ?? 'médio',
        pergunta: pergunta['pergunta'] ?? '',
        opcoes: opcoesList,
        respostaCorreta: pergunta['resposta_correta'] ?? '',
        explicacao: pergunta['explicacao'],
        fonteIA: pergunta['fonte_ia'] ?? 'firebase_ai',
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar pergunta no cache: $e');
      }
    }
  }

  /// Calcula pontuação baseada no tempo de resposta
  static int calcularPontos(int tempoSegundos, bool isCorreta) {
    if (!isCorreta) return 0;

    // Sistema de pontuação baseado no tempo
    if (tempoSegundos <= 5) return 100;
    if (tempoSegundos <= 10) return 80;
    if (tempoSegundos <= 15) return 60;
    if (tempoSegundos <= 30) return 40;
    return 20;
  }

  /// Salva resultado de quiz no histórico
  static Future<void> salvarResultadoQuiz(QuizSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historicoJson = prefs.getString(_historicoKey);
      List<Map<String, dynamic>> historico = [];

      if (historicoJson != null) {
        final List<dynamic> decoded = jsonDecode(historicoJson);
        historico = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      // Adiciona resultado atual
      final statistics = QuizStatistics.fromSession(session);
      historico.add({
        'id': session.id,
        'data': session.fim?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'unidade': session.unidade,
        'ano': session.ano,
        'dificuldade': session.dificuldade,
        'total_perguntas': statistics.totalPerguntas,
        'corretas': statistics.corretas,
        'incorretas': statistics.incorretas,
        'pontuacao': statistics.pontuacao,
        'tempo_total': statistics.tempoTotal,
        'taxa_acerto': statistics.taxaAcerto,
        'is_offline': session.isOfflineMode,
      });

      // Mantém apenas os últimos 50 resultados
      if (historico.length > 50) {
        historico = historico.sublist(historico.length - 50);
      }

      await prefs.setString(_historicoKey, jsonEncode(historico));

      if (kDebugMode) {
        print('💾 Resultado do quiz salvo: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao salvar resultado do quiz: $e');
      }
    }
  }

  /// Obtém histórico de quizzes
  static Future<List<Map<String, dynamic>>> obterHistoricoQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historicoJson = prefs.getString(_historicoKey);

      if (historicoJson != null) {
        final List<dynamic> decoded = jsonDecode(historicoJson);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao obter histórico de quiz: $e');
      }
      return [];
    }
  }

  /// Limpa cache de perguntas antigas (mais de 30 dias)
  static Future<void> limparCacheAntigo() async {
    try {
      await DatabaseService.limparCacheAntigo(diasParaExpirar: 30);

      if (kDebugMode) {
        print('🧹 Cache de perguntas antigo limpo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao limpar cache antigo: $e');
      }
    }
  }

  /// Cria pergunta de fallback quando IA/cache falham
  static QuizQuestion _criarPerguntaFallback(
    String unidade,
    String ano,
    String tipoQuiz,
    String dificuldade,
  ) {
    // Pergunta simples de matemática básica
    return QuizQuestion(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      pergunta: 'Quanto é 2 + 2?',
      opcoes: ['3', '4', '5', '6'],
      respostaCorreta: '4',
      explicacao: '2 + 2 = 4. Esta é uma operação básica de adição.',
      tipo: 'multipla_escolha',
      unidade: unidade,
      ano: ano,
      dificuldade: dificuldade,
      fonte: 'fallback',
    );
  }

  /// Mapeia tópico para unidade BNCC
  static String mapearTopicoParaUnidade(String topico) {
    final mapeamento = {
      'números': 'Números',
      'álgebra': 'Álgebra',
      'geometria': 'Geometria',
      'medidas': 'Grandezas e Medidas',
      'estatística': 'Probabilidade e Estatística',
      'probabilidade': 'Probabilidade e Estatística',
    };

    return mapeamento[topico.toLowerCase()] ?? 'Números';
  }

  /// Mapeia dificuldade para ano escolar
  static String mapearDificuldadeParaAno(String dificuldade) {
    switch (dificuldade.toLowerCase()) {
      case 'iniciante':
      case 'fácil':
        return '6º ano';
      case 'intermediário':
      case 'médio':
        return '7º ano';
      case 'avançado':
      case 'difícil':
        return '8º ano';
      case 'especialista':
      case 'expert':
        return '9º ano';
      default:
        return '7º ano';
    }
  }
}