import '../services/personagem_service.dart';
import '../services/progresso_service.dart';

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
    // TODO: Implementar cálculo de streak baseado no progresso

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
    // TODO: Implementar quando sistema de medalhas estiver disponível
    // Por ora, retorna um valor baseado no progresso
    try {
      final progresso = await ProgressoService.carregarProgresso();
      return progresso.totalExerciciosCorretos ~/
          10; // 1 medalha a cada 10 acertos
    } catch (e) {
      return 0;
    }
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
