import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/core_modern_components_widget.dart';
import '../../../widgets/core_mixins_widget.dart';
import '../models/user_achievement_model.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen>
    with TickerProviderStateMixin, LoadingStateMixin {
  Map<String, dynamic> _dadosProgresso = {};
  List<Achievement> _conquistas = [];

  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    await executeWithLoadingAndError(() async {
      // Simula dados de progresso
      _dadosProgresso = {
        'nivel_atual': 15,
        'xp_total': 2340,
        'xp_proximo_nivel': 2500,
        'exercicios_completados': 128,
        'sequencia_dias': 7,
        'tempo_estudo_total': 45, // horas
        'pontuacao_media': 85.5,
        'topicos_dominados': 12,
        'topicos_total': 18,
      };

      // Simula conquistas
      _conquistas = [
        Achievement(
          id: '1',
          title: 'Primeiro Passo',
          description: 'Complete seu primeiro exercício',
          emoji: '⭐',
          type: AchievementType.moduleComplete,
          criteria: {'completar_primeiro_exercicio': true},
          bonusPoints: 50,
          unlockDate: DateTime.now().subtract(const Duration(days: 7)),
          unlocked: true,
        ),
        Achievement(
          id: '2',
          title: 'Dedicado',
          description: 'Estude por 7 dias consecutivos',
          emoji: '🔥',
          type: AchievementType.exerciseStreak,
          criteria: {'dias_consecutivos': 7},
          bonusPoints: 100,
          unlockDate: DateTime.now(),
          unlocked: true,
        ),
        Achievement(
          id: '3',
          title: 'Matemático',
          description: 'Domine 10 tópicos diferentes',
          emoji: '🎓',
          type: AchievementType.unitComplete,
          criteria: {'topicos_dominados': 10},
          bonusPoints: 200,
          unlockDate: DateTime.now().subtract(const Duration(days: 2)),
          unlocked: true,
        ),
        Achievement(
          id: '4',
          title: 'Perfeccionista',
          description: 'Obtenha 100% em 20 exercícios',
          emoji: '🏆',
          type: AchievementType.perfectionist,
          criteria: {'exercicios_100_porcento': 20},
          bonusPoints: 300,
          unlocked: false,
        ),
      ];

      _animationController.forward();
    }, 'Erro ao carregar dados');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Relatórios e Progresso',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
                text: 'Conquistas Desbloqueadas',
                icon: Icon(Icons.emoji_events, size: 20)),
            Tab(
                text: 'Conquistas Bloqueadas',
                icon: Icon(Icons.lock, size: 20)),
            Tab(
                text: 'Estatísticas Conquistas',
                icon: Icon(Icons.analytics, size: 20)),
            Tab(
                text: 'Histórico Explicações',
                icon: Icon(Icons.history, size: 20)),
            Tab(
                text: 'Pontos Fracos',
                icon: Icon(Icons.trending_down, size: 20)),
            Tab(
                text: 'Relatório Geral',
                icon: Icon(Icons.assessment, size: 20)),
          ],
        ),
      ),
      body: isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConquistasDesbloqueadas(),
                _buildConquistasBloqueadas(),
                _buildEstatisticasConquistas(),
                _buildHistoricoExplicacoes(),
                _buildPontosFracos(),
                _buildRelatorioGeral(),
              ],
            ),
    );
  }

  Widget _buildConquistasDesbloqueadas() {
    final conquistasDesbloqueadas =
        _conquistas.where((c) => c.unlocked).toList();

    if (conquistasDesbloqueadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma conquista desbloqueada ainda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue estudando para desbloquear suas primeiras conquistas!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasDesbloqueadas.length,
      itemBuilder: (context, index) {
        final conquista = conquistasDesbloqueadas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Text(
              conquista.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(
              conquista.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(conquista.description),
            trailing: Text(
              '+${conquista.bonusPoints} XP',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConquistasBloqueadas() {
    final conquistasBloqueadas =
        _conquistas.where((c) => !c.unlocked).toList();

    if (conquistasBloqueadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Todas as conquistas foram desbloqueadas!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasBloqueadas.length,
      itemBuilder: (context, index) {
        final conquista = conquistasBloqueadas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey[50],
          child: ListTile(
            leading: Icon(
              Icons.lock,
              color: Colors.grey[400],
              size: 32,
            ),
            title: Text(
              conquista.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              conquista.description,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstatisticasConquistas() {
    final conquistasDesbloqueadas =
        _conquistas.where((c) => c.unlocked).toList();
    final totalConquistas = _conquistas.length;
    final porcentagem = totalConquistas > 0
        ? (conquistasDesbloqueadas.length / totalConquistas) * 100
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estatísticas de Conquistas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Desbloqueadas',
                  conquistasDesbloqueadas.length.toString(),
                  Icons.emoji_events,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Totais',
                  totalConquistas.toString(),
                  Icons.stars,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Progresso',
            '${porcentagem.round()}%',
            Icons.trending_up,
            AppTheme.successColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String titulo, String valor, IconData icone, Color cor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoExplicacoes() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Histórico de Explicações',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em desenvolvimento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPontosFracos() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_down,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Análise de Pontos Fracos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em desenvolvimento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatorioGeral() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relatório Geral',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _buildProgressCard(),
          const SizedBox(height: 24),
          _buildPerformanceCard(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progresso Geral',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressItem(
                    'Nível',
                    _dadosProgresso['nivel_atual'].toString(),
                    Icons.grade,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    'XP Total',
                    _dadosProgresso['xp_total'].toString(),
                    Icons.flash_on,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProgressItem(
                    'Exercícios',
                    _dadosProgresso['exercicios_completados'].toString(),
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildProgressItem(
                    'Sequência',
                    '${_dadosProgresso['sequencia_dias']} dias',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Desempenho',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceItem(
                    'Pontuação Média',
                    '${_dadosProgresso['pontuacao_media']}%',
                    Icons.trending_up,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildPerformanceItem(
                    'Tópicos Dominados',
                    '${_dadosProgresso['topicos_dominados']}/${_dadosProgresso['topicos_total']}',
                    Icons.school,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
