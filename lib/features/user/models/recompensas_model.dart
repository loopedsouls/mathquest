import 'package:flutter/foundation.dart';
import '../services/personagem_service.dart';
import '../services/progresso_service.dart';
import '../../games/service/gamificacao_service.dart';

/// Helper class para integrar recompensas do personagem com o progresso do usuário
class RecompensasIntegration {
  static final PersonagemService _personagemService = PersonagemService();

  /// Processa recompensas quando o usuário completa um exercício
  static Future<void> processarRecompensaExercicio({
    required bool acertou,
    required String topico,
    required String dificuldade,
  }) async {
    if (!acertou) return;

    int xpGanho = 0;
    int moedasGanhas = 0;

    // Calcular recompensas baseado na dificuldade
    switch (dificuldade.toLowerCase()) {
      case 'fácil':
        xpGanho = 10;
        moedasGanhas = 2;
        break;
      case 'médio':
        xpGanho = 15;
        moedasGanhas = 3;
        break;
      case 'difícil':
        xpGanho = 25;
        moedasGanhas = 5;
        break;
      default:
        xpGanho = 10;
        moedasGanhas = 2;
    }

    // Bonus por sequência (streak)
    final progresso = await ProgressoService.carregarProgresso();
    final streakAtual = progresso.exerciciosCorretosConsecutivos[topico] ?? 0;
    final novoStreak = streakAtual + 1;

    // Atualizar streak no progresso
    progresso.exerciciosCorretosConsecutivos[topico] = novoStreak;
    await ProgressoService.salvarProgresso(progresso);

    // Calcular bonus baseado no streak
    int bonusStreakXP = 0;
    int bonusStreakMoedas = 0;

    if (novoStreak >= 5) {
      bonusStreakXP =
          (novoStreak ~/ 5) * 5; // +5 XP a cada 5 acertos consecutivos
      bonusStreakMoedas =
          (novoStreak ~/ 5) * 1; // +1 moeda a cada 5 acertos consecutivos
    }

    if (novoStreak == 10) {
      bonusStreakXP += 25; // Bonus especial por streak de 10
      bonusStreakMoedas += 5;
    } else if (novoStreak == 25) {
      bonusStreakXP += 50; // Bonus especial por streak de 25
      bonusStreakMoedas += 10;
    } else if (novoStreak == 50) {
      bonusStreakXP += 100; // Bonus especial por streak de 50
      bonusStreakMoedas += 25;
    } else if (novoStreak == 100) {
      bonusStreakXP += 200; // Bonus especial por streak de 100
      bonusStreakMoedas += 50;
    }

    // Aplicar bonus do streak
    xpGanho += bonusStreakXP;
    moedasGanhas += bonusStreakMoedas;

    // Aplicar recompensas
    await _personagemService.adicionarRecompensa(
      experiencia: xpGanho,
      moedas: moedasGanhas,
    );

    // Verificar novos desbloqueios
    final perfil = _personagemService.perfilAtual;
    if (perfil != null) {
      await _personagemService.verificarNovosDesbloqueios(
        nivel: perfil.nivel,
        problemasCorretos: await _contarProblemasCorretos(),
      );
    }
  }

  /// Processa recompensas quando o usuário completa um módulo
  static Future<void> processarRecompensaModulo({
    required String moduloId,
    required double pontuacao,
  }) async {
    int xpGanho = 50; // Base XP por módulo
    int moedasGanhas = 10;

    // Bonus baseado na pontuação
    if (pontuacao >= 90) {
      xpGanho += 25; // Bonus por excelência
      moedasGanhas += 5;
    } else if (pontuacao >= 70) {
      xpGanho += 15; // Bonus por bom desempenho
      moedasGanhas += 3;
    }

    // Aplicar recompensas
    await _personagemService.adicionarRecompensa(
      experiencia: xpGanho,
      moedas: moedasGanhas,
    );

    // Verificar novos desbloqueios
    final perfil = _personagemService.perfilAtual;
    if (perfil != null) {
      final modulosCompletos = await _contarModulosCompletos();
      await _personagemService.verificarNovosDesbloqueios(
        nivel: perfil.nivel,
        modulosCompletos: modulosCompletos,
        problemasCorretos: await _contarProblemasCorretos(),
      );
    }
  }

  /// Processa recompensas quando o usuário ganha uma conquista/medalha
  static Future<void> processarRecompensaConquista({
    required String conquistaId,
    required int pontosBonus,
  }) async {
    // Recompensa base por conquista
    int xpGanho = pontosBonus;
    int moedasGanhas = (pontosBonus * 0.1).round(); // 10% em moedas

    // Aplicar recompensas
    await _personagemService.adicionarRecompensa(
      experiencia: xpGanho,
      moedas: moedasGanhas,
    );

    // Verificar novos desbloqueios relacionados a medalhas
    final perfil = _personagemService.perfilAtual;
    if (perfil != null) {
      final medalhas = await _contarMedalhas();
      await _personagemService.verificarNovosDesbloqueios(
        nivel: perfil.nivel,
        medalhas: medalhas,
        modulosCompletos: await _contarModulosCompletos(),
        problemasCorretos: await _contarProblemasCorretos(),
      );
    }
  }

  /// Recompensas por login diário (streak)
  static Future<void> processarRecompensaLoginDiario({
    required int diasSequencia,
  }) async {
    int xpGanho = 5 + (diasSequencia * 2); // Aumenta com a sequência
    int moedasGanhas = 1 + (diasSequencia ~/ 7); // Bonus semanal

    // Bonus especiais para milestones
    if (diasSequencia == 7) {
      xpGanho += 20;
      moedasGanhas += 10;
    } else if (diasSequencia == 30) {
      xpGanho += 50;
      moedasGanhas += 25;
    } else if (diasSequencia == 100) {
      xpGanho += 100;
      moedasGanhas += 50;
    }

    await _personagemService.adicionarRecompensa(
      experiencia: xpGanho,
      moedas: moedasGanhas,
    );
  }

  // === Métodos auxiliares para contagem ===

  static Future<int> _contarProblemasCorretos() async {
    try {
      final progresso = await ProgressoService.carregarProgresso();
      return progresso.totalExerciciosCorretos;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _contarModulosCompletos() async {
    try {
      final progresso = await ProgressoService.carregarProgresso();
      int contador = 0;

      // Contar módulos completados
      progresso.modulosCompletos.forEach((unidade, anosCompletos) {
        anosCompletos.forEach((ano, completo) {
          if (completo) contador++;
        });
      });

      return contador;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> _contarMedalhas() async {
    try {
      // Carrega as conquistas desbloqueadas do sistema de gamificação
      await GamificacaoService.carregarDados();
      final conquistasDesbloqueadas =
          await GamificacaoService.obterConquistasDesbloqueadas();
      return conquistasDesbloqueadas.length;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao contar medalhas: $e');
      }
      // Fallback para cálculo baseado no progresso se o sistema de gamificação falhar
      try {
        final progresso = await ProgressoService.carregarProgresso();
        return progresso.totalExerciciosCorretos ~/
            10; // 1 medalha a cada 10 acertos
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Erro no fallback de contagem de medalhas: $fallbackError');
        }
        return 0;
      }
    }
  }

  /// Reseta o streak quando o usuário erra um exercício
  static Future<void> resetarStreak({
    required String topico,
  }) async {
    final progresso = await ProgressoService.carregarProgresso();
    progresso.exerciciosCorretosConsecutivos[topico] = 0;
    await ProgressoService.salvarProgresso(progresso);
  }

  /// Função conveniente para ser chamada após qualquer atividade significativa
  /// para verificar e processar recompensas pendentes
  static Future<List<String>> verificarTodasRecompensas() async {
    final perfil = _personagemService.perfilAtual;
    if (perfil == null) return [];

    final novosItens = await _personagemService.verificarNovosDesbloqueios(
      nivel: perfil.nivel,
      modulosCompletos: await _contarModulosCompletos(),
      problemasCorretos: await _contarProblemasCorretos(),
      medalhas: await _contarMedalhas(),
    );

    return novosItens.map((item) => item.nome).toList();
  }
}
