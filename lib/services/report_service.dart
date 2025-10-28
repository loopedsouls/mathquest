import 'dart:math';
import '../models/user_progress_model.dart';
import '../models/bncc_module_model.dart';
import 'progress_service.dart';
import 'gamification_service.dart';

class RelatorioService {
  // Gera relatório completo de progresso
  static Future<Map<String, dynamic>> gerarRelatorioCompleto() async {
    final progresso = await ProgressoService.carregarProgresso();
    final estatisticasGamificacao =
        await GamificacaoService.obterEstatisticas();

    // Cálculos gerais
    final progressoGeral = progresso.calcularProgressoGeral();
    final modulosCompletosTotal = _contarModulosCompletos(progresso);
    final unidadesCompletas = _contarUnidadesCompletas(progresso);

    // Análise por unidade
    final analisePorUnidade = await _analisarProgressoPorUnidade(progresso);

    // Recomendações
    final recomendacoes = await _gerarRecomendacoes(progresso);

    // Pontos fortes e fracos
    final analiseDesempenho = _analisarDesempenho(progresso);

    return {
      'data_geracao': DateTime.now().toIso8601String(),
      'progresso_geral': {
        'percentual': (progressoGeral * 100).round(),
        'modulos_completos': modulosCompletosTotal,
        'total_modulos': 20, // 5 unidades × 4 anos
        'unidades_completas': unidadesCompletas,
        'nivel_atual': progresso.nivelUsuario.name,
        'nivel_index': progresso.nivelUsuario.index,
      },
      'estatisticas_exercicios': {
        'total_respondidos': progresso.totalExerciciosRespondidos,
        'total_corretos': progresso.totalExerciciosCorretos,
        'taxa_acerto_geral': progresso.totalExerciciosRespondidos > 0
            ? (progresso.totalExerciciosCorretos /
                    progresso.totalExerciciosRespondidos *
                    100)
                .round()
            : 0,
      },
      'gamificacao': estatisticasGamificacao,
      'analise_por_unidade': analisePorUnidade,
      'recomendacoes': recomendacoes,
      'analise_desempenho': analiseDesempenho,
      'ultima_atualizacao': progresso.ultimaAtualizacao.toIso8601String(),
    };
  }

  // Gera relatório específico de uma unidade
  static Future<Map<String, dynamic>> gerarRelatorioUnidade(
      String unidade) async {
    final progresso = await ProgressoService.carregarProgresso();

    final progressoUnidade = progresso.calcularProgressoPorUnidade(unidade);

    // Estatísticas detalhadas por ano
    Map<String, Map<String, dynamic>> estatisticasPorAno = {};

    for (final ano in ['6º ano', '7º ano', '8º ano', '9º ano']) {
      final modulo = ModulosBNCCData.obterModulo(unidade, ano);
      if (modulo != null) {
        final chaveModulo = '${unidade}_$ano';
        final estatisticas =
            await ProgressoService.obterEstatisticasModulo(unidade, ano);

        estatisticasPorAno[ano] = {
          'modulo': modulo.toJson(),
          'completo': progresso.modulosCompletos[unidade]?[ano] ?? false,
          'taxa_acerto': progresso.taxaAcertoPorModulo[chaveModulo] ?? 0.0,
          'exercicios_consecutivos':
              progresso.exerciciosCorretosConsecutivos[chaveModulo] ?? 0,
          'pontos': progresso.pontosPorUnidade[unidade] ?? 0,
          'estatisticas_detalhadas': estatisticas,
        };
      }
    }

    return {
      'unidade': unidade,
      'progresso_percentual': (progressoUnidade * 100).round(),
      'data_geracao': DateTime.now().toIso8601String(),
      'estatisticas_por_ano': estatisticasPorAno,
      'proximos_passos': await _gerarProximosPassosUnidade(unidade, progresso),
    };
  }

  // Gera relatório de evolução temporal
  static Future<Map<String, dynamic>> gerarRelatorioEvolucao() async {
    // Este método pode ser expandido com dados históricos
    // Por simplicidade, vamos focar no estado atual
    final progresso = await ProgressoService.carregarProgresso();

    return {
      'data_geracao': DateTime.now().toIso8601String(),
      'evolucao_nivel': {
        'nivel_atual': progresso.nivelUsuario.name,
        'progresso_para_proximo': _calcularProgressoParaProximoNivel(progresso),
      },
      'tendencias': await _analisarTendencias(progresso),
      'metas_sugeridas': _gerarMetasSugeridas(progresso),
    };
  }

  // Métodos auxiliares privados

  static int _contarModulosCompletos(ProgressoUsuario progresso) {
    int total = 0;
    for (final unidade in progresso.modulosCompletos.values) {
      for (final completo in unidade.values) {
        if (completo) total++;
      }
    }
    return total;
  }

  static int _contarUnidadesCompletas(ProgressoUsuario progresso) {
    int unidadesCompletas = 0;

    for (final unidade in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ]) {
      bool unidadeCompleta = true;
      if (progresso.modulosCompletos.containsKey(unidade)) {
        for (final completo in progresso.modulosCompletos[unidade]!.values) {
          if (!completo) {
            unidadeCompleta = false;
            break;
          }
        }
      } else {
        unidadeCompleta = false;
      }

      if (unidadeCompleta) unidadesCompletas++;
    }

    return unidadesCompletas;
  }

  static Future<Map<String, dynamic>> _analisarProgressoPorUnidade(
      ProgressoUsuario progresso) async {
    Map<String, dynamic> analise = {};

    for (final unidade in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ]) {
      final progressoUnidade = progresso.calcularProgressoPorUnidade(unidade);
      final pontos = progresso.pontosPorUnidade[unidade] ?? 0;

      // Conta módulos completos nesta unidade
      int modulosCompletos = 0;
      if (progresso.modulosCompletos.containsKey(unidade)) {
        modulosCompletos =
            progresso.modulosCompletos[unidade]!.values.where((v) => v).length;
      }

      // Calcula taxa de acerto média da unidade
      double taxaAcertoMedia = 0.0;
      int contadorModulos = 0;
      for (final ano in ['6º ano', '7º ano', '8º ano', '9º ano']) {
        final chaveModulo = '${unidade}_$ano';
        if (progresso.taxaAcertoPorModulo.containsKey(chaveModulo)) {
          taxaAcertoMedia += progresso.taxaAcertoPorModulo[chaveModulo]!;
          contadorModulos++;
        }
      }
      if (contadorModulos > 0) {
        taxaAcertoMedia = taxaAcertoMedia / contadorModulos;
      }

      analise[unidade] = {
        'progresso_percentual': (progressoUnidade * 100).round(),
        'modulos_completos': modulosCompletos,
        'total_modulos': 4,
        'pontos_conquistados': pontos,
        'taxa_acerto_media': (taxaAcertoMedia * 100).round(),
        'status': _obterStatusUnidade(progressoUnidade),
      };
    }

    return analise;
  }

  static String _obterStatusUnidade(double progresso) {
    if (progresso >= 1.0) return 'Completa';
    if (progresso >= 0.75) return 'Quase Completa';
    if (progresso >= 0.5) return 'Em Progresso';
    if (progresso >= 0.25) return 'Iniciada';
    return 'Não Iniciada';
  }

  static Future<List<Map<String, dynamic>>> _gerarRecomendacoes(
      ProgressoUsuario progresso) async {
    List<Map<String, dynamic>> recomendacoes = [];

    // Recomendação de próximo módulo
    final proximoModulo = progresso.obterProximoModulo();
    if (proximoModulo != null) {
      recomendacoes.add({
        'tipo': 'proximo_modulo',
        'titulo': 'Continue sua jornada',
        'descricao':
            'Próximo módulo recomendado: ${proximoModulo['unidade']} - ${proximoModulo['ano']}',
        'prioridade': 'alta',
        'acao': 'estudar_modulo',
        'dados': proximoModulo,
      });
    }

    // Recomendações baseadas em desempenho
    final unidadeComMenorProgresso =
        _encontrarUnidadeComMenorProgresso(progresso);
    if (unidadeComMenorProgresso != null) {
      recomendacoes.add({
        'tipo': 'revisar_unidade',
        'titulo': 'Fortaleça seus conhecimentos',
        'descricao': 'Considere revisar a unidade: $unidadeComMenorProgresso',
        'prioridade': 'media',
        'acao': 'revisar_unidade',
        'dados': {'unidade': unidadeComMenorProgresso},
      });
    }

    // Recomendação para manter streak
    final streakAtual = await GamificacaoService.obterStreakAtual();
    if (streakAtual > 0) {
      recomendacoes.add({
        'tipo': 'manter_streak',
        'titulo': 'Mantenha o ritmo!',
        'descricao':
            'Você tem $streakAtual respostas corretas consecutivas. Continue assim!',
        'prioridade': 'baixa',
        'acao': 'continuar_exercicios',
        'dados': {'streak_atual': streakAtual},
      });
    }

    return recomendacoes;
  }

  static String? _encontrarUnidadeComMenorProgresso(
      ProgressoUsuario progresso) {
    String? unidadeMenorProgresso;
    double menorProgresso = 1.0;

    for (final unidade in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ]) {
      final progressoUnidade = progresso.calcularProgressoPorUnidade(unidade);
      if (progressoUnidade < menorProgresso && progressoUnidade > 0) {
        menorProgresso = progressoUnidade;
        unidadeMenorProgresso = unidade;
      }
    }

    return unidadeMenorProgresso;
  }

  static Map<String, dynamic> _analisarDesempenho(ProgressoUsuario progresso) {
    // Identifica pontos fortes e fracos
    Map<String, double> desempenhoPorUnidade = {};

    for (final unidade in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ]) {
      desempenhoPorUnidade[unidade] =
          progresso.calcularProgressoPorUnidade(unidade);
    }

    // Ordena por desempenho
    final unidadesOrdenadas = desempenhoPorUnidade.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'pontos_fortes': unidadesOrdenadas
          .take(2)
          .map((e) => {
                'unidade': e.key,
                'progresso': (e.value * 100).round(),
              })
          .toList(),
      'areas_melhoria': unidadesOrdenadas.reversed
          .take(2)
          .map((e) => {
                'unidade': e.key,
                'progresso': (e.value * 100).round(),
              })
          .toList(),
      'equilibrio_geral': _calcularEquilibrioGeral(desempenhoPorUnidade),
    };
  }

  static String _calcularEquilibrioGeral(Map<String, double> desempenho) {
    final valores = desempenho.values.toList();
    final media = valores.fold(0.0, (a, b) => a + b) / valores.length;
    final variancia = valores.fold(
            0.0, (sum, value) => sum + ((value - media) * (value - media))) /
        valores.length;
    final desvioPadrao = sqrt(variancia);

    if (desvioPadrao < 0.1) return 'Equilibrado';
    if (desvioPadrao < 0.2) return 'Levemente Desbalanceado';
    return 'Desbalanceado';
  }

  static Future<List<String>> _gerarProximosPassosUnidade(
      String unidade, ProgressoUsuario progresso) async {
    List<String> passos = [];

    final progressoUnidade = progresso.calcularProgressoPorUnidade(unidade);

    if (progressoUnidade == 0.0) {
      passos.add('Comece pelos módulos do 6º ano desta unidade');
      passos.add('Familiarize-se com os conceitos básicos');
    } else if (progressoUnidade < 0.5) {
      passos.add('Continue praticando os módulos em andamento');
      passos.add('Revise conceitos que ainda geram dúvidas');
    } else if (progressoUnidade < 1.0) {
      passos.add('Finalize os módulos restantes desta unidade');
      passos.add('Pratique exercícios mais desafiadores');
    } else {
      passos.add('Parabéns! Unidade completa');
      passos.add('Considere revisar periodicamente para manter o conhecimento');
    }

    return passos;
  }

  static double _calcularProgressoParaProximoNivel(ProgressoUsuario progresso) {
    final nivelAtual = progresso.nivelUsuario.index;
    final maxNivel = NivelUsuario.values.length - 1;

    if (nivelAtual >= maxNivel) return 1.0; // Já no nível máximo

    // Calcula progresso baseado em módulos completos
    final modulosCompletos = _contarModulosCompletos(progresso);
    final modulosNecessariosParaProximo = (nivelAtual + 2) * 5; // Aproximação

    return (modulosCompletos / modulosNecessariosParaProximo).clamp(0.0, 1.0);
  }

  static Future<Map<String, dynamic>> _analisarTendencias(
      ProgressoUsuario progresso) async {
    // Por simplicidade, retorna tendências baseadas no estado atual
    // Em uma implementação completa, usaria dados históricos
    return {
      'tendencia_geral': 'Em crescimento',
      'unidade_favorita': _encontrarUnidadeFavorita(progresso),
      'ritmo_aprendizado': 'Consistente',
    };
  }

  static String _encontrarUnidadeFavorita(ProgressoUsuario progresso) {
    String? unidadeFavorita;
    double maiorProgresso = 0.0;

    for (final unidade in [
      'Números',
      'Álgebra',
      'Geometria',
      'Grandezas e Medidas',
      'Probabilidade e Estatística'
    ]) {
      final progressoUnidade = progresso.calcularProgressoPorUnidade(unidade);
      if (progressoUnidade > maiorProgresso) {
        maiorProgresso = progressoUnidade;
        unidadeFavorita = unidade;
      }
    }

    return unidadeFavorita ?? 'Números';
  }

  static List<Map<String, dynamic>> _gerarMetasSugeridas(
      ProgressoUsuario progresso) {
    List<Map<String, dynamic>> metas = [];

    final modulosCompletos = _contarModulosCompletos(progresso);

    // Meta de curto prazo
    metas.add({
      'periodo': 'Próximos 7 dias',
      'objetivo': 'Completar 1 módulo adicional',
      'meta_numerica': modulosCompletos + 1,
      'tipo': 'modulos',
    });

    // Meta de médio prazo
    metas.add({
      'periodo': 'Próximo mês',
      'objetivo': 'Completar uma unidade completa',
      'meta_numerica': 4, // 4 módulos por unidade
      'tipo': 'unidade',
    });

    // Meta de longo prazo
    metas.add({
      'periodo': 'Próximos 3 meses',
      'objetivo': 'Avançar para o próximo nível',
      'meta_numerica': progresso.nivelUsuario.index + 1,
      'tipo': 'nivel',
    });

    return metas;
  }
}
