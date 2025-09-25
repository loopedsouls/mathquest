import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/conquista.dart';
import '../models/progresso_usuario.dart';
import 'progresso_service.dart';

class GamificacaoService {
  static const String _conquistasKey = 'conquistas_desbloqueadas';
  static const String _streakAtualKey = 'streak_atual';
  static const String _melhorStreakKey = 'melhor_streak';
  static const String _ultimoExercicioKey = 'ultimo_exercicio_data';

  // Cache em memória
  static List<String> _conquistasDesbloqueadas = [];
  static int _streakAtual = 0;
  static int _melhorStreak = 0;

  // Carrega dados de gamificação
  static Future<void> carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Carrega conquistas desbloqueadas
    final conquistasJson = prefs.getStringList(_conquistasKey) ?? [];
    _conquistasDesbloqueadas = conquistasJson;

    // Carrega streaks
    _streakAtual = prefs.getInt(_streakAtualKey) ?? 0;
    _melhorStreak = prefs.getInt(_melhorStreakKey) ?? 0;
  }

  // Salva dados de gamificação
  static Future<void> salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(_conquistasKey, _conquistasDesbloqueadas);
    await prefs.setInt(_streakAtualKey, _streakAtual);
    await prefs.setInt(_melhorStreakKey, _melhorStreak);
  }

  // Registra resposta correta e verifica conquistas
  static Future<List<Conquista>> registrarRespostaCorreta({
    required String unidade,
    required String ano,
    required int tempoResposta,
  }) async {
    await carregarDados();

    List<Conquista> novasConquistas = [];

    // Incrementa streak
    _streakAtual++;
    if (_streakAtual > _melhorStreak) {
      _melhorStreak = _streakAtual;
    }

    // Marca data do último exercício
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _ultimoExercicioKey, DateTime.now().toIso8601String());

    // Verifica conquistas
    novasConquistas.addAll(await _verificarConquistasStreak());
    novasConquistas.addAll(await _verificarConquistasTempo(tempoResposta));
    novasConquistas.addAll(await _verificarConquistasGerais());

    await salvarDados();
    return novasConquistas;
  }

  // Registra resposta incorreta (quebra streak)
  static Future<void> registrarRespostaIncorreta() async {
    await carregarDados();
    _streakAtual = 0;
    await salvarDados();
  }

  // Verifica conquistas quando um módulo é completado
  static Future<List<Conquista>> verificarConquistasModuloCompleto(
    String unidade,
    String ano,
    double taxaAcerto,
  ) async {
    await carregarDados();

    List<Conquista> novasConquistas = [];

    // Conquistas por quantidade de módulos
    novasConquistas.addAll(await _verificarConquistasModulos());

    // Conquistas por unidade completa
    novasConquistas.addAll(await _verificarConquistasUnidade(unidade));

    // Conquista perfeccionista
    if (taxaAcerto >= 1.0) {
      novasConquistas.addAll(await _verificarConquistaPerfeccionista());
    }

    await salvarDados();
    return novasConquistas;
  }

  // Verifica conquistas quando nível muda
  static Future<List<Conquista>> verificarConquistasNivel(
      NivelUsuario nivel) async {
    await carregarDados();

    List<Conquista> novasConquistas = [];

    final conquistas =
        ConquistasData.obterConquistasPorTipo(TipoConquista.nivelAlcancado);

    for (final conquista in conquistas) {
      if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

      final nivelRequerido = conquista.criterios['nivel'] as int;
      if (nivel.index >= nivelRequerido) {
        await _desbloquearConquista(conquista.id);
        novasConquistas.add(conquista.copyWith(
          desbloqueada: true,
          dataConquista: DateTime.now(),
        ));
      }
    }

    await salvarDados();
    return novasConquistas;
  }

  // Verifica conquistas de streak
  static Future<List<Conquista>> _verificarConquistasStreak() async {
    List<Conquista> novasConquistas = [];

    final conquistas =
        ConquistasData.obterConquistasPorTipo(TipoConquista.streakExercicios);

    for (final conquista in conquistas) {
      if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

      final streakRequerida = conquista.criterios['streak'] as int;
      if (_streakAtual >= streakRequerida) {
        await _desbloquearConquista(conquista.id);
        novasConquistas.add(conquista.copyWith(
          desbloqueada: true,
          dataConquista: DateTime.now(),
        ));
      }
    }

    return novasConquistas;
  }

  // Verifica conquistas de tempo
  static Future<List<Conquista>> _verificarConquistasTempo(
      int tempoResposta) async {
    List<Conquista> novasConquistas = [];

    final conquistas =
        ConquistasData.obterConquistasPorTipo(TipoConquista.tempoRecord);

    for (final conquista in conquistas) {
      if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

      final tempoMaximo = conquista.criterios['tempo_maximo'] as int;
      if (tempoResposta <= tempoMaximo) {
        await _desbloquearConquista(conquista.id);
        novasConquistas.add(conquista.copyWith(
          desbloqueada: true,
          dataConquista: DateTime.now(),
        ));
      }
    }

    return novasConquistas;
  }

  // Verifica conquistas gerais (pontuação, etc.)
  static Future<List<Conquista>> _verificarConquistasGerais() async {
    List<Conquista> novasConquistas = [];

    final progresso = await ProgressoService.carregarProgresso();
    final pontosTotais =
        progresso.pontosPorUnidade.values.fold(0, (a, b) => a + b);

    // Conquistas por pontuação
    final conquistasPontos =
        ConquistasData.obterConquistasPorTipo(TipoConquista.pontuacaoTotal);

    for (final conquista in conquistasPontos) {
      if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

      final pontosRequeridos = conquista.criterios['pontos'] as int;
      if (pontosTotais >= pontosRequeridos) {
        await _desbloquearConquista(conquista.id);
        novasConquistas.add(conquista.copyWith(
          desbloqueada: true,
          dataConquista: DateTime.now(),
        ));
      }
    }

    return novasConquistas;
  }

  // Verifica conquistas por quantidade de módulos
  static Future<List<Conquista>> _verificarConquistasModulos() async {
    List<Conquista> novasConquistas = [];

    final progresso = await ProgressoService.carregarProgresso();

    // Conta módulos completos
    int modulosCompletos = 0;
    for (final unidade in progresso.modulosCompletos.values) {
      for (final completo in unidade.values) {
        if (completo) modulosCompletos++;
      }
    }

    final conquistas =
        ConquistasData.obterConquistasPorTipo(TipoConquista.moduloCompleto);

    for (final conquista in conquistas) {
      if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

      final quantidadeRequerida = conquista.criterios['quantidade'] as int;
      if (modulosCompletos >= quantidadeRequerida) {
        await _desbloquearConquista(conquista.id);
        novasConquistas.add(conquista.copyWith(
          desbloqueada: true,
          dataConquista: DateTime.now(),
        ));
      }
    }

    return novasConquistas;
  }

  // Verifica conquistas por unidade completa
  static Future<List<Conquista>> _verificarConquistasUnidade(
      String unidade) async {
    List<Conquista> novasConquistas = [];

    final progresso = await ProgressoService.carregarProgresso();

    // Verifica se a unidade está completa
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

    if (unidadeCompleta) {
      final conquistas =
          ConquistasData.obterConquistasPorTipo(TipoConquista.unidadeCompleta);

      for (final conquista in conquistas) {
        if (_conquistasDesbloqueadas.contains(conquista.id)) continue;

        final unidadeRequerida = conquista.criterios['unidade'] as String;
        if (unidade == unidadeRequerida) {
          await _desbloquearConquista(conquista.id);
          novasConquistas.add(conquista.copyWith(
            desbloqueada: true,
            dataConquista: DateTime.now(),
          ));
        }
      }
    }

    return novasConquistas;
  }

  // Verifica conquista perfeccionista
  static Future<List<Conquista>> _verificarConquistaPerfeccionista() async {
    List<Conquista> novasConquistas = [];

    final conquista = ConquistasData.obterConquistaPorId('perfeccionista');
    if (conquista != null && !_conquistasDesbloqueadas.contains(conquista.id)) {
      await _desbloquearConquista(conquista.id);
      novasConquistas.add(conquista.copyWith(
        desbloqueada: true,
        dataConquista: DateTime.now(),
      ));
    }

    return novasConquistas;
  }

  // Desbloqueia uma conquista
  static Future<void> _desbloquearConquista(String conquistaId) async {
    if (!_conquistasDesbloqueadas.contains(conquistaId)) {
      _conquistasDesbloqueadas.add(conquistaId);

      // Adiciona pontos bônus
      final conquista = ConquistasData.obterConquistaPorId(conquistaId);
      if (conquista != null && conquista.pontosBonus > 0) {
        // Aqui poderia implementar lógica para adicionar pontos bônus
        // Por simplicidade, vamos deixar para implementação futura
      }

      if (kDebugMode) {
        print('🏆 Conquista desbloqueada: ${conquista?.titulo}');
      }
    }
  }

  // Obtém conquistas desbloqueadas
  static Future<List<Conquista>> obterConquistasDesbloqueadas() async {
    await carregarDados();
    return ConquistasData.obterConquistasDesbloqueadas(
        _conquistasDesbloqueadas);
  }

  // Obtém conquistas bloqueadas
  static Future<List<Conquista>> obterConquistasBloqueadas() async {
    await carregarDados();
    return ConquistasData.obterConquistasBloqueadas(_conquistasDesbloqueadas);
  }

  // Obtém estatísticas de gamificação
  static Future<Map<String, dynamic>> obterEstatisticas() async {
    await carregarDados();

    final conquistasDesbloqueadas = await obterConquistasDesbloqueadas();
    final conquistasTotais = ConquistasData.obterTodasConquistas();

    final pontosBonus = conquistasDesbloqueadas.fold<int>(
        0, (total, conquista) => total + conquista.pontosBonus);

    return {
      'conquistas_desbloqueadas': conquistasDesbloqueadas.length,
      'conquistas_totais': conquistasTotais.length,
      'porcentagem_conquistas':
          conquistasDesbloqueadas.length / conquistasTotais.length,
      'streak_atual': _streakAtual,
      'melhor_streak': _melhorStreak,
      'pontos_bonus': pontosBonus,
    };
  }

  // Obtém streak atual
  static Future<int> obterStreakAtual() async {
    await carregarDados();
    return _streakAtual;
  }

  // Obtém melhor streak
  static Future<int> obterMelhorStreak() async {
    await carregarDados();
    return _melhorStreak;
  }

  // Reseta todas as conquistas (para testes)
  static Future<void> resetarConquistas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conquistasKey);
    await prefs.remove(_streakAtualKey);
    await prefs.remove(_melhorStreakKey);
    await prefs.remove(_ultimoExercicioKey);

    _conquistasDesbloqueadas.clear();
    _streakAtual = 0;
    _melhorStreak = 0;
  }

  // Força desbloquear uma conquista (para testes)
  static Future<void> forcarDesbloquearConquista(String conquistaId) async {
    await carregarDados();
    await _desbloquearConquista(conquistaId);
    await salvarDados();
  }
}
