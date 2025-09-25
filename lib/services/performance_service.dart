import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Serviço para gerenciar a performance do usuário e ajustar dificuldade dinamicamente
class PerformanceService {
  static const String _keyTotalPerguntas = 'total_perguntas';
  static const String _keyTotalAcertos = 'total_acertos';
  static const String _keyTotalErros = 'total_erros';
  static const String _keySequenciaAcertos = 'sequencia_acertos';
  static const String _keySequenciaErros = 'sequencia_erros';
  static const String _keyDificuldadeAtual = 'dificuldade_atual';
  static const String _keyHistoricoPerformance = 'historico_performance';
  static const String _keyUltimasRespostas = 'ultimas_respostas';
  static const String _keyTemposResposta = 'tempos_resposta';
  static const String _keyBoosterAtivo = 'booster_ativo';

  /// Registra uma resposta do usuário e atualiza as estatísticas
  static Future<void> registrarResposta({
    required bool acertou,
    required String dificuldade,
    required String tipoQuiz,
    int? tempoRespostaSegundos,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Atualizar contadores gerais
      final totalPerguntas = prefs.getInt(_keyTotalPerguntas) ?? 0;
      final totalAcertos = prefs.getInt(_keyTotalAcertos) ?? 0;
      final totalErros = prefs.getInt(_keyTotalErros) ?? 0;

      await prefs.setInt(_keyTotalPerguntas, totalPerguntas + 1);

      if (acertou) {
        await prefs.setInt(_keyTotalAcertos, totalAcertos + 1);

        // Atualizar sequência de acertos
        final sequenciaAcertos = prefs.getInt(_keySequenciaAcertos) ?? 0;
        await prefs.setInt(_keySequenciaAcertos, sequenciaAcertos + 1);
        await prefs.setInt(_keySequenciaErros, 0); // Resetar sequência de erros
      } else {
        await prefs.setInt(_keyTotalErros, totalErros + 1);

        // Atualizar sequência de erros
        final sequenciaErros = prefs.getInt(_keySequenciaErros) ?? 0;
        await prefs.setInt(_keySequenciaErros, sequenciaErros + 1);
        await prefs.setInt(
            _keySequenciaAcertos, 0); // Resetar sequência de acertos
      }

      // Registrar nas últimas respostas (manter apenas as últimas 10)
      await _registrarUltimaResposta(
          acertou, dificuldade, tipoQuiz, tempoRespostaSegundos);

      // Registrar no histórico detalhado
      await _registrarHistorico(
          acertou, dificuldade, tipoQuiz, tempoRespostaSegundos);

      // Atualizar booster de dificuldade baseado no tempo de resposta
      await _atualizarBoosterDificuldade(
          acertou, dificuldade, tempoRespostaSegundos);

      if (kDebugMode) {
        final taxaAcerto = await obterTaxaAcerto();
        print(
            '📊 Performance atualizada: ${taxaAcerto.toStringAsFixed(1)}% de acertos');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao registrar resposta: $e');
      }
    }
  }

  /// Registra a última resposta para análise de padrões recentes
  static Future<void> _registrarUltimaResposta(bool acertou, String dificuldade,
      String tipoQuiz, int? tempoRespostaSegundos) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimasRespostas = prefs.getStringList(_keyUltimasRespostas) ?? [];

    final tempo = tempoRespostaSegundos ?? 0;
    final resposta =
        '${acertou ? 1 : 0}|$dificuldade|$tipoQuiz|${DateTime.now().millisecondsSinceEpoch}|$tempo';
    ultimasRespostas.add(resposta);

    // Manter apenas as últimas 10 respostas
    if (ultimasRespostas.length > 10) {
      ultimasRespostas.removeAt(0);
    }

    await prefs.setStringList(_keyUltimasRespostas, ultimasRespostas);
  }

  /// Registra no histórico detalhado de performance
  static Future<void> _registrarHistorico(bool acertou, String dificuldade,
      String tipoQuiz, int? tempoRespostaSegundos) async {
    final prefs = await SharedPreferences.getInstance();
    final historico = prefs.getStringList(_keyHistoricoPerformance) ?? [];

    final tempo = tempoRespostaSegundos ?? 0;
    final entrada =
        '${DateTime.now().millisecondsSinceEpoch}|${acertou ? 1 : 0}|$dificuldade|$tipoQuiz|$tempo';
    historico.add(entrada);

    // Manter apenas os últimos 100 registros para não sobrecarregar o storage
    if (historico.length > 100) {
      historico.removeAt(0);
    }

    await prefs.setStringList(_keyHistoricoPerformance, historico);
  }

  /// Atualiza o booster de dificuldade baseado no tempo de resposta
  static Future<void> _atualizarBoosterDificuldade(
      bool acertou, String dificuldade, int? tempoRespostaSegundos) async {
    if (tempoRespostaSegundos == null || !acertou) return;

    final prefs = await SharedPreferences.getInstance();

    // Definir limites de tempo por dificuldade (em segundos)
    Map<String, int> limitesTempoRapido = {
      'fácil': 8, // Menos de 8 segundos é considerado muito rápido
      'médio': 12, // Menos de 12 segundos é considerado muito rápido
      'difícil': 18, // Menos de 18 segundos é considerado muito rápido
    };

    final limiteRapido = limitesTempoRapido[dificuldade] ?? 10;

    if (tempoRespostaSegundos < limiteRapido) {
      // Resposta muito rápida - ativar booster
      final boosterAtual = prefs.getInt(_keyBoosterAtivo) ?? 0;
      await prefs.setInt(_keyBoosterAtivo, boosterAtual + 1);

      if (kDebugMode) {
        print(
            '🚀 Booster ativado! Tempo: ${tempoRespostaSegundos}s (limite: ${limiteRapido}s)');
        print('   Nível do booster: ${boosterAtual + 1}');
      }

      // Salvar histórico de tempos rápidos
      final temposRapidos = prefs.getStringList(_keyTemposResposta) ?? [];
      temposRapidos.add(
          '$tempoRespostaSegundos|$dificuldade|${DateTime.now().millisecondsSinceEpoch}');

      // Manter apenas os últimos 20 tempos rápidos
      if (temposRapidos.length > 20) {
        temposRapidos.removeAt(0);
      }

      await prefs.setStringList(_keyTemposResposta, temposRapidos);
    } else {
      // Resposta normal - reduzir booster gradualmente
      final boosterAtual = prefs.getInt(_keyBoosterAtivo) ?? 0;
      if (boosterAtual > 0) {
        await prefs.setInt(_keyBoosterAtivo,
            (boosterAtual - 1).clamp(0, double.infinity).toInt());
      }
    }
  }

  /// Calcula e retorna a dificuldade adaptiva baseada na performance do usuário
  static Future<String> calcularDificuldadeAdaptiva() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Analisar performance recente (últimas 10 respostas)
      final ultimasRespostas = prefs.getStringList(_keyUltimasRespostas) ?? [];

      if (ultimasRespostas.isEmpty) {
        return 'fácil'; // Começar com fácil para novos usuários
      }

      // Calcular taxa de acerto das últimas respostas
      int acertosRecentes = 0;
      for (final resposta in ultimasRespostas) {
        final partes = resposta.split('|');
        if (partes.isNotEmpty && partes[0] == '1') {
          acertosRecentes++;
        }
      }

      final taxaAcertoRecente = acertosRecentes / ultimasRespostas.length;

      // Obter sequências atuais
      final sequenciaAcertos = prefs.getInt(_keySequenciaAcertos) ?? 0;
      final sequenciaErros = prefs.getInt(_keySequenciaErros) ?? 0;

      // Obter dificuldade atual
      String dificuldadeAtual =
          prefs.getString(_keyDificuldadeAtual) ?? 'fácil';

      // Obter nível do booster
      final nivelBooster = prefs.getInt(_keyBoosterAtivo) ?? 0;

      // Lógica adaptativa baseada em múltiplos fatores incluindo booster
      String novaDificuldade = _calcularNovaDificuldade(
        taxaAcertoRecente,
        sequenciaAcertos,
        sequenciaErros,
        dificuldadeAtual,
        nivelBooster,
      );

      // Salvar nova dificuldade
      if (novaDificuldade != dificuldadeAtual) {
        await prefs.setString(_keyDificuldadeAtual, novaDificuldade);

        if (kDebugMode) {
          print(
              '🎯 Dificuldade ajustada: $dificuldadeAtual → $novaDificuldade');
          print(
              '   Taxa de acerto recente: ${(taxaAcertoRecente * 100).toStringAsFixed(1)}%');
          print('   Sequência de acertos: $sequenciaAcertos');
          print('   Sequência de erros: $sequenciaErros');
          print('   Nível do booster: $nivelBooster');
        }
      }

      return novaDificuldade;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao calcular dificuldade adaptiva: $e');
      }
      return 'fácil'; // Fallback seguro
    }
  }

  /// Lógica para calcular nova dificuldade baseada nos parâmetros
  static String _calcularNovaDificuldade(
    double taxaAcertoRecente,
    int sequenciaAcertos,
    int sequenciaErros,
    String dificuldadeAtual,
    int nivelBooster,
  ) {
    // Primeiro, aplicar booster de dificuldade se necessário
    String dificuldadeBase = dificuldadeAtual;
    if (nivelBooster >= 3) {
      // Booster forte - pular um nível
      switch (dificuldadeAtual) {
        case 'fácil':
          dificuldadeBase = 'difícil';
          break;
        case 'médio':
          dificuldadeBase = 'difícil';
          break;
      }
    } else if (nivelBooster >= 1) {
      // Booster moderado - aumentar um nível
      switch (dificuldadeAtual) {
        case 'fácil':
          dificuldadeBase = 'médio';
          break;
        case 'médio':
          dificuldadeBase = 'difícil';
          break;
      }
    }

    // Regras para aumentar dificuldade (aplicadas sobre a dificuldade base)
    if (taxaAcertoRecente >= 0.8 && sequenciaAcertos >= 3) {
      // Taxa alta de acerto e sequência de acertos - aumentar dificuldade
      switch (dificuldadeBase) {
        case 'fácil':
          return 'médio';
        case 'médio':
          return 'difícil';
        case 'difícil':
          return 'difícil'; // Já está no máximo
      }
    }

    // Regras para diminuir dificuldade
    if (taxaAcertoRecente <= 0.4 && sequenciaErros >= 2) {
      // Taxa baixa de acerto e sequência de erros - diminuir dificuldade
      switch (dificuldadeBase) {
        case 'difícil':
          return 'médio';
        case 'médio':
          return 'fácil';
        case 'fácil':
          return 'fácil'; // Já está no mínimo
      }
    }

    // Ajustes mais sutis baseados apenas na taxa de acerto
    if (taxaAcertoRecente >= 0.7) {
      // Performance boa - considerar aumentar
      switch (dificuldadeBase) {
        case 'fácil':
          return sequenciaAcertos >= 2 ? 'médio' : dificuldadeBase;
        case 'médio':
          return sequenciaAcertos >= 4 ? 'difícil' : dificuldadeBase;
        default:
          return dificuldadeBase;
      }
    } else if (taxaAcertoRecente <= 0.5) {
      // Performance ruim - considerar diminuir
      switch (dificuldadeBase) {
        case 'difícil':
          return 'médio';
        case 'médio':
          return sequenciaErros >= 2 ? 'fácil' : dificuldadeBase;
        default:
          return dificuldadeBase;
      }
    }

    // Manter dificuldade base se não há mudança necessária
    return dificuldadeBase;
  }

  /// Obtém a taxa de acerto geral do usuário
  static Future<double> obterTaxaAcerto() async {
    final prefs = await SharedPreferences.getInstance();
    final totalPerguntas = prefs.getInt(_keyTotalPerguntas) ?? 0;
    final totalAcertos = prefs.getInt(_keyTotalAcertos) ?? 0;

    if (totalPerguntas == 0) return 0.0;
    return (totalAcertos / totalPerguntas) * 100;
  }

  /// Obtém estatísticas detalhadas do usuário
  static Future<Map<String, dynamic>> obterEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();

    final totalPerguntas = prefs.getInt(_keyTotalPerguntas) ?? 0;
    final totalAcertos = prefs.getInt(_keyTotalAcertos) ?? 0;
    final totalErros = prefs.getInt(_keyTotalErros) ?? 0;
    final sequenciaAcertos = prefs.getInt(_keySequenciaAcertos) ?? 0;
    final sequenciaErros = prefs.getInt(_keySequenciaErros) ?? 0;
    final dificuldadeAtual = prefs.getString(_keyDificuldadeAtual) ?? 'fácil';
    final nivelBooster = prefs.getInt(_keyBoosterAtivo) ?? 0;

    // Calcular taxa de acerto das últimas respostas
    final ultimasRespostas = prefs.getStringList(_keyUltimasRespostas) ?? [];
    double taxaAcertoRecente = 0.0;
    if (ultimasRespostas.isNotEmpty) {
      int acertosRecentes = 0;
      for (final resposta in ultimasRespostas) {
        final partes = resposta.split('|');
        if (partes.isNotEmpty && partes[0] == '1') {
          acertosRecentes++;
        }
      }
      taxaAcertoRecente = (acertosRecentes / ultimasRespostas.length) * 100;
    }

    return {
      'total_perguntas': totalPerguntas,
      'total_acertos': totalAcertos,
      'total_erros': totalErros,
      'taxa_acerto_geral':
          totalPerguntas > 0 ? (totalAcertos / totalPerguntas) * 100 : 0.0,
      'taxa_acerto_recente': taxaAcertoRecente,
      'sequencia_acertos': sequenciaAcertos,
      'sequencia_erros': sequenciaErros,
      'dificuldade_atual': dificuldadeAtual,
      'nivel_booster': nivelBooster,
      'ultimas_respostas_count': ultimasRespostas.length,
    };
  }

  /// Obtém a dificuldade atual salva
  static Future<String> obterDificuldadeAtual() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDificuldadeAtual) ?? 'fácil';
  }

  /// Obtém o nível atual do booster
  static Future<int> obterNivelBooster() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBoosterAtivo) ?? 0;
  }

  /// Obtém informações detalhadas sobre tempos de resposta rápidos
  static Future<List<Map<String, dynamic>>> obterTemposRapidos() async {
    final prefs = await SharedPreferences.getInstance();
    final temposRapidos = prefs.getStringList(_keyTemposResposta) ?? [];

    List<Map<String, dynamic>> resultado = [];
    for (final tempo in temposRapidos) {
      final partes = tempo.split('|');
      if (partes.length >= 3) {
        resultado.add({
          'tempo_segundos': int.tryParse(partes[0]) ?? 0,
          'dificuldade': partes[1],
          'timestamp': int.tryParse(partes[2]) ?? 0,
        });
      }
    }

    return resultado;
  }

  /// Reset das estatísticas (APENAS PARA USO ADMINISTRATIVO/DESENVOLVIMENTO)
  /// Os alunos não têm acesso a esta funcionalidade através da interface
  static Future<void> resetarEstatisticas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTotalPerguntas);
    await prefs.remove(_keyTotalAcertos);
    await prefs.remove(_keyTotalErros);
    await prefs.remove(_keySequenciaAcertos);
    await prefs.remove(_keySequenciaErros);
    await prefs.remove(_keyDificuldadeAtual);
    await prefs.remove(_keyHistoricoPerformance);
    await prefs.remove(_keyUltimasRespostas);
    await prefs.remove(_keyTemposResposta);
    await prefs.remove(_keyBoosterAtivo);

    if (kDebugMode) {
      print('🔄 Estatísticas de performance resetadas (incluindo booster)');
    }
  }

  /// Obtém análise detalhada da performance por dificuldade
  static Future<Map<String, Map<String, int>>> obterAnaliseDetalhada() async {
    final prefs = await SharedPreferences.getInstance();
    final historico = prefs.getStringList(_keyHistoricoPerformance) ?? [];

    Map<String, Map<String, int>> analise = {
      'fácil': {'acertos': 0, 'erros': 0},
      'médio': {'acertos': 0, 'erros': 0},
      'difícil': {'acertos': 0, 'erros': 0},
    };

    for (final entrada in historico) {
      final partes = entrada.split('|');
      if (partes.length >= 4) {
        final acertou = partes[1] == '1';
        final dificuldade = partes[2];

        if (analise.containsKey(dificuldade)) {
          if (acertou) {
            analise[dificuldade]!['acertos'] =
                analise[dificuldade]!['acertos']! + 1;
          } else {
            analise[dificuldade]!['erros'] =
                analise[dificuldade]!['erros']! + 1;
          }
        }
      }
    }

    return analise;
  }
}
