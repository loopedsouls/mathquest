import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../app_theme.dart';
import '../../../widgets/modern_components.dart';
import '../../../widgets/mixins.dart';
import '../../../services/progress_service.dart';
import '../models/achievement.dart';
import 'achievement_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, LoadingStateMixin, AnimationMixin {
  Map<String, dynamic> _dadosProgresso = {};
  List<Achievement> _conquistas = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await executeWithLoadingAndError(() async {
      // Carregar progresso do usuário
      final progresso = await ProgressoService.carregarProgresso();

      // Simula dados de progresso
      _dadosProgresso = {
        'nivel_atual': 15,
        'xp_total': progresso.pontosPorUnidade.values.fold(0, (a, b) => a + b),
        'xp_proximo_nivel': 2500,
        'exercicios_completados': progresso.totalExerciciosCorretos,
        'sequencia_dias': 7,
        'tempo_estudo_total': 45, // horas
        'pontuacao_media': 85.5,
        'topicos_dominados': 12,
        'topicos_total': 18,
      };

      // Carrega conquistas reais do ConquistasData
      final todasConquistas = AchievementsData.getAllAchievements();

      // Simula algumas conquistas desbloqueadas (3 primeiras)
      List<String> idsDesbloqueadas = [
        'primeiro_modulo',
        'dez_modulos',
        'nivel_intermediario'
      ];

      _conquistas = todasConquistas.map((c) {
        final desbloqueada = idsDesbloqueadas.contains(c.id);
        return c.copyWith(
          unlocked: desbloqueada,
          unlockDate: desbloqueada
              ? DateTime.now()
                  .subtract(Duration(days: idsDesbloqueadas.indexOf(c.id) * 2))
              : null,
        );
      }).toList();

      animationController.forward();
    }, 'Erro ao carregar dados');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
              AppTheme.darkBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? _buildLoadingScreen()
              : Column(
                  children: [
                    _buildGameHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildStreakCard(),
                            const SizedBox(height: 16),
                            _buildXPProgressCard(),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildAchievementCard(),
                            const SizedBox(height: 16),
                            _buildDailyGoalsCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            'Carregando seu progresso...',
            style: TextStyle(
              color: AppTheme.darkTextSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Gamified header like Duolingo
  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // User avatar with level ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                ),
                child: CircularProgressIndicator(
                  value: (_dadosProgresso['xp_total'] ?? 0) /
                      (_dadosProgresso['xp_proximo_nivel'] ?? 1),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível ${_dadosProgresso['nivel_atual'] ?? 0}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_dadosProgresso['xp_total'] ?? 0} XP',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracaoScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Streak card with flame effect
  Widget _buildStreakCard() {
    final streakDays = _dadosProgresso['sequencia_dias'] ?? 0;
    return ModernCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withValues(alpha: 0.1),
              Colors.red.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            // Flame icon with animation effect
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays dias seguidos! 🔥',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streakDays > 0
                        ? 'Continue assim para manter sua sequência!'
                        : 'Comece uma nova sequência hoje!',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // XP Progress card with level system
  Widget _buildXPProgressCard() {
    final currentXP = _dadosProgresso['xp_total'] ?? 0;
    final nextLevelXP = _dadosProgresso['xp_proximo_nivel'] ?? 1;
    final progress = currentXP / nextLevelXP;

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progresso XP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nível ${_dadosProgresso['nivel_atual'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // XP Progress Bar
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.darkBorderColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currentXP / $nextLevelXP XP',
              style: TextStyle(
                color: AppTheme.darkTextSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stats row with icons
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${_dadosProgresso['exercicios_completados'] ?? 0}',
            'Exercícios',
            Icons.quiz,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '${_dadosProgresso['tempo_estudo_total'] ?? 0}h',
            'Tempo',
            Icons.schedule,
            AppTheme.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '${(_dadosProgresso['pontuacao_media'] ?? 0).round()}%',
            'Precisão',
            Icons.track_changes,
            AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.darkTextSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConquistaIcon(String icone, {bool isLocked = false}) {
    if (icone.startsWith('assets/models/') && icone.endsWith('.svg')) {
      return SvgPicture.asset(
        icone,
        width: 36,
        height: 36,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(AppTheme.primaryColor, BlendMode.srcIn),
      );
    } else {
      // Fallback para emojis
      return Text(
        icone,
        style: TextStyle(
          fontSize: 36,
          color: isLocked ? Colors.grey[600] : null,
        ),
      );
    }
  }

  // Achievement section with detailed view
  Widget _buildAchievementCard() {
    final unlockedAchievements =
        _conquistas.where((c) => c.unlocked).toList();
    final lockedAchievements =
        _conquistas.where((c) => !c.unlocked).toList();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementScreen()),
        );
      },
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events,
                      color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text('Conquistas',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        '${unlockedAchievements.length}/${_conquistas.length}',
                        style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (unlockedAchievements.isNotEmpty) ...[
                const Text('Desbloqueadas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: unlockedAchievements.length,
                    itemBuilder: (context, index) {
                      final conquista = unlockedAchievements[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.2),
                                child: _buildConquistaIcon(conquista.emoji)),
                            const SizedBox(height: 8),
                            Text(conquista.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            Text('+${conquista.bonusPoints} XP',
                                style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (lockedAchievements.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Bloqueadas',
                    style: TextStyle(
                        color: AppTheme.darkTextSecondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: lockedAchievements.length,
                    itemBuilder: (context, index) {
                      final conquista = lockedAchievements[index];
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.darkBorderColor
                                    .withValues(alpha: 0.3),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: _buildConquistaIcon(
                                          conquista.emoji,
                                          isLocked: true),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[700],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.grey[400],
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                            const SizedBox(height: 8),
                            Text(conquista.title,
                                style: TextStyle(
                                    color: AppTheme.darkTextSecondaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Daily goals card
  Widget _buildDailyGoalsCard() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Metas Diárias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDailyGoal('Exercícios', 3, 5, Icons.quiz),
            const SizedBox(height: 12),
            _buildDailyGoal('Minutos de estudo', 15, 30, Icons.schedule),
            const SizedBox(height: 12),
            _buildDailyGoal('XP ganho', 100, 200, Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoal(String title, int current, int target, IconData icon) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isCompleted = current >= target;

    return Row(
      children: [
        Icon(
          icon,
          color: isCompleted
              ? AppTheme.successColor
              : AppTheme.darkTextSecondaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$current/$target',
                    style: TextStyle(
                      color: isCompleted
                          ? AppTheme.successColor
                          : AppTheme.darkTextSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCompleted) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 20,
          ),
        ],
      ],
    );
  }
}
