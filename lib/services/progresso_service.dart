import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progresso_usuario.dart';
import '../models/modulo_bncc.dart';
import 'gamificacao_service.dart';

class ProgressoService {
  static const String _progressoKey = 'progresso_usuario';
  static const String _estatisticasModuloKey = 'estatisticas_modulo';
  
  static ProgressoUsuario? _progressoCache;

  // Carrega o progresso do usuário
  static Future<ProgressoUsuario> carregarProgresso() async {
    if (_progressoCache != null) return _progressoCache!;

    final prefs = await SharedPreferences.getInstance();
    final progressoJson = prefs.getString(_progressoKey);
    
    if (progressoJson != null) {
      _progressoCache = ProgressoUsuario.fromJsonString(progressoJson);
    } else {
      _progressoCache = ProgressoUsuario();
      await salvarProgresso(_progressoCache!);
    }
    
    return _progressoCache!;
  }

  // Salva o progresso do usuário
  static Future<void> salvarProgresso(ProgressoUsuario progresso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressoKey, progresso.toJsonString());
    _progressoCache = progresso;
  }

  // Registra uma resposta correta
  static Future<void> registrarRespostaCorreta(String unidade, String ano) async {
    final progresso = await carregarProgresso();
    final chaveModulo = '${unidade}_$ano';
    
    // Incrementa exercícios corretos consecutivos
    progresso.exerciciosCorretosConsecutivos[chaveModulo] = 
        (progresso.exerciciosCorretosConsecutivos[chaveModulo] ?? 0) + 1;
    
    // Incrementa totais
    progresso.totalExerciciosRespondidos++;
    progresso.totalExerciciosCorretos++;
    
    // Atualiza taxa de acerto
    await _atualizarTaxaAcerto(unidade, ano, true);
    
    // Verifica se o módulo foi completado
    await _verificarCompletarModulo(unidade, ano);
    
    await salvarProgresso(progresso);
  }

  // Registra uma resposta incorreta
  static Future<void> registrarRespostaIncorreta(String unidade, String ano) async {
    final progresso = await carregarProgresso();
    final chaveModulo = '${unidade}_$ano';
    
    // Reseta exercícios corretos consecutivos
    progresso.exerciciosCorretosConsecutivos[chaveModulo] = 0;
    
    // Incrementa total de exercícios
    progresso.totalExerciciosRespondidos++;
    
    // Atualiza taxa de acerto
    await _atualizarTaxaAcerto(unidade, ano, false);
    
    await salvarProgresso(progresso);
  }

  // Atualiza taxa de acerto do módulo
  static Future<void> _atualizarTaxaAcerto(String unidade, String ano, bool correta) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveModulo = '${unidade}_$ano';
    final chaveEstatisticas = '${_estatisticasModuloKey}_$chaveModulo';
    
    // Carrega estatísticas existentes
    Map<String, int> stats = {
      'corretas': 0,
      'total': 0,
    };
    
    final statsJson = prefs.getString(chaveEstatisticas);
    if (statsJson != null) {
      final decoded = Map<String, dynamic>.from(
        Uri.splitQueryString(statsJson).map((k, v) => MapEntry(k, int.parse(v)))
      );
      stats['corretas'] = decoded['corretas'] ?? 0;
      stats['total'] = decoded['total'] ?? 0;
    }
    
    // Atualiza estatísticas
    stats['total'] = stats['total']! + 1;
    if (correta) {
      stats['corretas'] = stats['corretas']! + 1;
    }
    
    // Salva estatísticas
    final queryString = stats.entries.map((e) => '${e.key}=${e.value}').join('&');
    await prefs.setString(chaveEstatisticas, queryString);
    
    // Atualiza taxa no progresso
    final progresso = await carregarProgresso();
    progresso.taxaAcertoPorModulo[chaveModulo] = 
        stats['total']! > 0 ? stats['corretas']! / stats['total']! : 0.0;
  }

  // Verifica se um módulo deve ser completado
  static Future<void> _verificarCompletarModulo(String unidade, String ano) async {
    final progresso = await carregarProgresso();
    final chaveModulo = '${unidade}_$ano';
    
    // Se já estiver completo, não faz nada
    if (progresso.modulosCompletos[unidade]?[ano] == true) return;
    
    final modulo = ModulosBNCCData.obterModulo(unidade, ano);
    if (modulo == null) return;
    
    // Critérios para completar módulo
    final exerciciosConsecutivos = progresso.exerciciosCorretosConsecutivos[chaveModulo] ?? 0;
    final taxaAcerto = progresso.taxaAcertoPorModulo[chaveModulo] ?? 0.0;
    
    // Verifica se atende aos critérios
    bool criteriosAtendidos = exerciciosConsecutivos >= modulo.exerciciosNecessarios &&
                              taxaAcerto >= modulo.taxaAcertoMinima;
    
    if (criteriosAtendidos) {
      progresso.completarModulo(unidade, ano);
      
      // Verifica conquistas relacionadas ao módulo completo
      final novasConquistas = await GamificacaoService.verificarConquistasModuloCompleto(
        unidade,
        ano,
        taxaAcerto,
      );
      
      // Verifica conquistas de nível se houve mudança
      final nivelAnterior = progresso.nivelUsuario;
      if (progresso.nivelUsuario != nivelAnterior) {
        final conquistasNivel = await GamificacaoService.verificarConquistasNivel(progresso.nivelUsuario);
        novasConquistas.addAll(conquistasNivel);
      }
      
      // Notifica conclusão
      if (kDebugMode) {
        print('🎉 Módulo completado: $unidade - $ano');
        if (novasConquistas.isNotEmpty) {
          print('🏆 ${novasConquistas.length} nova(s) conquista(s) desbloqueada(s)!');
        }
      }
    }
  }

  // Obtém próximo módulo recomendado
  static Future<Map<String, String>?> obterProximoModulo() async {
    final progresso = await carregarProgresso();
    return progresso.obterProximoModulo();
  }

  // Obtém estatísticas de um módulo específico
  static Future<Map<String, dynamic>> obterEstatisticasModulo(String unidade, String ano) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveModulo = '${unidade}_$ano';
    final chaveEstatisticas = '${_estatisticasModuloKey}_$chaveModulo';
    
    final statsJson = prefs.getString(chaveEstatisticas);
    if (statsJson == null) {
      return {
        'corretas': 0,
        'total': 0,
        'taxa_acerto': 0.0,
        'exercicios_consecutivos': 0,
        'completo': false,
      };
    }
    
    final decoded = Map<String, dynamic>.from(
      Uri.splitQueryString(statsJson).map((k, v) => MapEntry(k, int.parse(v)))
    );
    
    final progresso = await carregarProgresso();
    final exerciciosConsecutivos = progresso.exerciciosCorretosConsecutivos[chaveModulo] ?? 0;
    final completo = progresso.modulosCompletos[unidade]?[ano] ?? false;
    
    return {
      'corretas': decoded['corretas'] ?? 0,
      'total': decoded['total'] ?? 0,
      'taxa_acerto': decoded['total'] > 0 ? (decoded['corretas'] / decoded['total']) : 0.0,
      'exercicios_consecutivos': exerciciosConsecutivos,
      'completo': completo,
    };
  }

  // Reseta o progresso (para testes)
  static Future<void> resetarProgresso() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove progresso
    await prefs.remove(_progressoKey);
    
    // Remove todas as estatísticas de módulos
    final keys = prefs.getKeys().where((key) => key.startsWith(_estatisticasModuloKey));
    for (String key in keys) {
      await prefs.remove(key);
    }
    
    _progressoCache = null;
    
    // Cria novo progresso
    await carregarProgresso();
  }

  // Obtém relatório geral de progresso
  static Future<Map<String, dynamic>> obterRelatorioGeral() async {
    final progresso = await carregarProgresso();
    
    int totalModulos = 0;
    int modulosCompletos = 0;
    Map<String, int> completosPorUnidade = {};
    Map<String, double> progressoPorUnidade = {};
    
    for (String unidade in ModulosBNCCData.obterUnidadesTematicas()) {
      int completosUnidade = 0;
      for (String ano in ModulosBNCCData.obterAnosEscolares()) {
        totalModulos++;
        if (progresso.modulosCompletos[unidade]?[ano] == true) {
          modulosCompletos++;
          completosUnidade++;
        }
      }
      completosPorUnidade[unidade] = completosUnidade;
      progressoPorUnidade[unidade] = progresso.calcularProgressoPorUnidade(unidade);
    }
    
    return {
      'progresso_geral': progresso.calcularProgressoGeral(),
      'nivel_usuario': progresso.nivelUsuario,
      'total_modulos': totalModulos,
      'modulos_completos': modulosCompletos,
      'completos_por_unidade': completosPorUnidade,
      'progresso_por_unidade': progressoPorUnidade,
      'total_exercicios': progresso.totalExerciciosRespondidos,
      'exercicios_corretos': progresso.totalExerciciosCorretos,
      'taxa_acerto_geral': progresso.totalExerciciosRespondidos > 0 
          ? progresso.totalExerciciosCorretos / progresso.totalExerciciosRespondidos 
          : 0.0,
      'pontos_total': progresso.pontosPorUnidade.values.fold(0, (a, b) => a + b),
      'ultima_atualizacao': progresso.ultimaAtualizacao,
    };
  }

  // Verifica se um módulo está desbloqueado
  static Future<bool> verificarModuloDesbloqueado(String unidade, String ano) async {
    final progresso = await carregarProgresso();
    return progresso.moduloDesbloqueado(unidade, ano);
  }

  // Força completar um módulo (para testes)
  static Future<void> forcarCompletarModulo(String unidade, String ano) async {
    final progresso = await carregarProgresso();
    progresso.completarModulo(unidade, ano);
    await salvarProgresso(progresso);
  }

  // Obtém recomendações baseadas no progresso
  static Future<List<Map<String, String>>> obterRecomendacoes() async {
    final progresso = await carregarProgresso();
    List<Map<String, String>> recomendacoes = [];
    
    // Próximo módulo na sequência
    final proximoModulo = progresso.obterProximoModulo();
    if (proximoModulo != null) {
      recomendacoes.add({
        'tipo': 'proximo_modulo',
        'titulo': 'Continue sua jornada',
        'descricao': 'Próximo módulo: ${proximoModulo['unidade']} - ${proximoModulo['ano']}',
        'unidade': proximoModulo['unidade']!,
        'ano': proximoModulo['ano']!,
      });
    }
    
    // Módulos com taxa de acerto baixa para revisão
    for (String unidade in progresso.taxaAcertoPorModulo.keys) {
      final partes = unidade.split('_');
      if (partes.length == 2) {
        final unidadeNome = partes[0];
        final ano = partes[1];
        final taxa = progresso.taxaAcertoPorModulo[unidade]!;
        
        if (taxa < 0.7 && progresso.modulosCompletos[unidadeNome]?[ano] != true) {
          recomendacoes.add({
            'tipo': 'revisao',
            'titulo': 'Revisar conceitos',
            'descricao': 'Taxa de acerto baixa em $unidadeNome - $ano (${(taxa * 100).round()}%)',
            'unidade': unidadeNome,
            'ano': ano,
          });
        }
      }
    }
    
    return recomendacoes;
  }
}
