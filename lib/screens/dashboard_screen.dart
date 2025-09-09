import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../models/conquista.dart';
import '../services/progresso_service.dart';
import '../models/progresso_usuario.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic> _dadosProgresso = {};
  List<Conquista> _conquistas = [];

  bool _carregando = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _carregarDados();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
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

      // Simula conquistas
      _conquistas = [
        Conquista(
          id: '1',
          titulo: 'Primeiro Passo',
          descricao: 'Complete seu primeiro exercício',
          emoji: '⭐',
          tipo: TipoConquista.moduloCompleto,
          criterios: {'completar_primeiro_exercicio': true},
          pontosBonus: 50,
          dataConquista: DateTime.now().subtract(const Duration(days: 7)),
          desbloqueada: true,
        ),
        Conquista(
          id: '2',
          titulo: 'Dedicado',
          descricao: 'Estude por 7 dias consecutivos',
          emoji: '🔥',
          tipo: TipoConquista.streakExercicios,
          criterios: {'dias_consecutivos': 7},
          pontosBonus: 100,
          dataConquista: DateTime.now(),
          desbloqueada: true,
        ),
        Conquista(
          id: '3',
          titulo: 'Matemático',
          descricao: 'Domine 10 tópicos diferentes',
          emoji: '🎓',
          tipo: TipoConquista.unidadeCompleta,
          criterios: {'topicos_dominados': 10},
          pontosBonus: 200,
          dataConquista: DateTime.now().subtract(const Duration(days: 2)),
          desbloqueada: true,
        ),
        Conquista(
          id: '4',
          titulo: 'Perfeccionista',
          descricao: 'Obtenha 100% em 20 exercícios',
          emoji: '🏆',
          tipo: TipoConquista.perfeccionista,
          criterios: {'exercicios_100_porcento': 20},
          pontosBonus: 300,
          desbloqueada: false,
        ),
      ];

      setState(() {
        _carregando = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkBackgroundColor,
              AppTheme.darkSurfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _carregando
              ? _buildLoadingScreen()
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card de Progresso Geral
                            _buildProgressoGeralCard(),
                            const SizedBox(height: 24),

                            // Card de Sequência
                            _buildStreakCard(),
                            const SizedBox(height: 24),

                            // Card de Conquistas
                            _buildConquistasCard(),
                            const SizedBox(height: 24),

                            // Card de Estatísticas
                            _buildEstatisticasCard(),
                            const SizedBox(height: 24),

                            // Cards de funcionalidades futuras
                            _buildFuncionalidadesCard(),
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

  Widget _buildFuncionalidadesCard() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ferramentas',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFuncionalidadeButton(
                    'Recomendações',
                    'Veja sugestões personalizadas',
                    Icons.lightbulb,
                    _mostrarRecomendacoes,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFuncionalidadeButton(
                    'Relatório Detalhado',
                    'Análise completa do progresso',
                    Icons.analytics,
                    _mostrarRelatorioDetalhado,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuncionalidadeButton(
      String titulo, String descricao, IconData icone, VoidCallback onPressed) {
    return ModernCard(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icone, color: AppTheme.primaryColor, size: 24),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressoGeralCard() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Seu Progresso',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildProgressMetric(
                    'Nível',
                    _dadosProgresso['nivel_atual'].toString(),
                    Icons.grade,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildProgressMetric(
                    'XP Total',
                    _dadosProgresso['xp_total'].toString(),
                    Icons.flash_on,
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildProgressMetric(
                    'Sequência',
                    '${_dadosProgresso['sequencia_dias']} dias',
                    Icons.local_fire_department,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _dadosProgresso['xp_total'] /
                  _dadosProgresso['xp_proximo_nivel'],
              backgroundColor: AppTheme.darkBorderColor,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              '${_dadosProgresso['xp_total']} / ${_dadosProgresso['xp_proximo_nivel']} XP para o próximo nível',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressMetric(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildConquistasCard() {
    final conquistasDesbloqueadas =
        _conquistas.where((c) => c.desbloqueada).toList();
    final conquistasBloqueadas =
        _conquistas.where((c) => !c.desbloqueada).toList();

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Conquistas',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estatísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildConquistaStat(
                    '${conquistasDesbloqueadas.length}',
                    'Desbloqueadas',
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildConquistaStat(
                    '${conquistasBloqueadas.length}',
                    'Bloqueadas',
                    AppTheme.darkTextSecondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildConquistaStat(
                    '${_conquistas.length}',
                    'Total',
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lista de conquistas recentes
            if (conquistasDesbloqueadas.isNotEmpty) ...[
              Text(
                'Conquistas Recentes',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...conquistasDesbloqueadas.take(3).map((conquista) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          conquista.emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conquista.titulo,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkTextPrimaryColor,
                                ),
                              ),
                              Text(
                                conquista.descricao,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.darkTextSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${conquista.pontosBonus}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConquistaStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildEstatisticasCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Estatísticas de Estudo',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildEstatisticaItem(
                    'Exercícios',
                    _dadosProgresso['exercicios_completados'].toString(),
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildEstatisticaItem(
                    'Pontuação Média',
                    '${_dadosProgresso['pontuacao_media']}%',
                    Icons.trending_up,
                    AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstatisticaItem(
                    'Tempo de Estudo',
                    '${_dadosProgresso['tempo_estudo_total']}h',
                    Icons.schedule,
                    AppTheme.secondaryColor,
                  ),
                ),
                Expanded(
                  child: _buildEstatisticaItem(
                    'Tópicos Dominados',
                    '${_dadosProgresso['topicos_dominados']}/${_dadosProgresso['topicos_total']}',
                    Icons.school,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticaItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
      ),
    );
  }

  void _mostrarRecomendacoes() async {
    final recomendacoes = await ProgressoService.obterRecomendacoes();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          '💡 Recomendações',
          style: TextStyle(color: AppTheme.darkTextPrimaryColor),
        ),
        content: recomendacoes.isEmpty
            ? Text(
                'Parabéns! Você está em dia com seus estudos.',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: recomendacoes
                    .map((rec) => ListTile(
                          leading: Icon(
                            rec['tipo'] == 'proximo_modulo'
                                ? Icons.arrow_forward_rounded
                                : Icons.refresh_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            rec['titulo']!,
                            style:
                                TextStyle(color: AppTheme.darkTextPrimaryColor),
                          ),
                          subtitle: Text(
                            rec['descricao']!,
                            style: TextStyle(
                                color: AppTheme.darkTextSecondaryColor),
                          ),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _mostrarRelatorioDetalhado() async {
    final relatorio = await ProgressoService.obterRelatorioGeral();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Text(
          '📊 Relatório Detalhado',
          style: TextStyle(color: AppTheme.darkTextPrimaryColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nível: ${(relatorio['nivel_usuario'] as NivelUsuario).nome}',
                style: TextStyle(
                    color: AppTheme.darkTextPrimaryColor,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Progresso Geral: ${(relatorio['progresso_geral'] * 100).round()}%',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor),
              ),
              Text(
                'Módulos: ${relatorio['modulos_completos']}/${relatorio['total_modulos']}',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor),
              ),
              Text(
                'Taxa de Acerto: ${(relatorio['taxa_acerto_geral'] * 100).round()}%',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor),
              ),
              Text(
                'Pontos Totais: ${relatorio['pontos_total']}',
                style: TextStyle(color: AppTheme.darkTextSecondaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Progresso por Unidade:',
                style: TextStyle(
                    color: AppTheme.darkTextPrimaryColor,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(relatorio['progresso_por_unidade'] as Map<String, double>)
                  .entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.key}: ${(entry.value * 100).round()}%',
                          style:
                              TextStyle(color: AppTheme.darkTextSecondaryColor),
                        ),
                      )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.accentColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sequência de Estudo',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.accentColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_dadosProgresso['sequencia_dias']} dias',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.accentColor,
                        ),
                      ),
                      Text(
                        'Sequência atual',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
