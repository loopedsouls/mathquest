import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/relatorio_service.dart';
import '../widgets/relatorio_charts.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _relatorioCompleto;
  bool _carregando = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarRelatorio();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarRelatorio() async {
    setState(() => _carregando = true);
    
    try {
      final relatorio = await RelatorioService.gerarRelatorioCompleto();
      setState(() {
        _relatorioCompleto = relatorio;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar relatório: $e')),
        );
      }
    }
  }

  List<bool> _gerarUltimosDias() {
    // Simula atividade nos últimos 7 dias
    // Em uma implementação real, isso viria do serviço de relatórios
    return [true, false, true, true, false, true, true];
  }

  Widget _buildStatCard(String valor, String titulo, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Progresso'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.school), text: 'Por Unidade'),
            Tab(icon: Icon(Icons.trending_up), text: 'Recomendações'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisaoGeral(),
                _buildAnalisePorUnidade(),
                _buildRecomendacoes(),
              ],
            ),
    );
  }

  Widget _buildVisaoGeral() {
    if (_relatorioCompleto == null) return const Center(child: Text('Erro ao carregar dados'));

    final progressoGeral = _relatorioCompleto!['progresso_geral'];
    final estatisticasExercicios = _relatorioCompleto!['estatisticas_exercicios'];
    final gamificacao = _relatorioCompleto!['gamificacao'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cards de métricas principais
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Progresso Geral',
                  value: '${progressoGeral['percentual'] ?? 0}%',
                  subtitle: '${progressoGeral['modulos_completos'] ?? 0} de ${progressoGeral['total_modulos'] ?? 20} módulos',
                  icon: Icons.analytics,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricCard(
                  title: 'Exercícios',
                  value: '${estatisticasExercicios['total'] ?? 0}',
                  subtitle: '${estatisticasExercicios['acertos'] ?? 0} acertos',
                  icon: Icons.quiz,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress radial e streak
          Row(
            children: [
              Expanded(
                child: RadialProgressWidget(
                  progress: (progressoGeral['percentual'] ?? 0) / 100.0,
                  label: 'Módulos\nCompletos',
                  value: '${progressoGeral['modulos_completos'] ?? 0}/${progressoGeral['total_modulos'] ?? 20}',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StreakVisualizationWidget(
                  streakAtual: gamificacao['streak_atual'] ?? 0,
                  melhorStreak: gamificacao['melhor_streak'] ?? 0,
                  ultimosDias: _gerarUltimosDias(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Gráfico de pizza do progresso
          _buildGraficoProgressoPizza(progressoGeral),
          
          const SizedBox(height: 16),
          
          // Estatísticas de exercícios
          _buildCardEstatisticasExercicios(estatisticasExercicios),
          
          const SizedBox(height: 16),
          
          // Estatísticas de gamificação
          _buildCardGamificacao(gamificacao),
        ],
      ),
    );
  }

  Widget _buildGraficoProgressoPizza(Map<String, dynamic> progressoGeral) {
    final modulosCompletos = (progressoGeral['modulos_completos'] ?? 0).toDouble();
    final totalModulos = (progressoGeral['total_modulos'] ?? 20).toDouble();
    final modulosRestantes = totalModulos - modulosCompletos;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição dos Módulos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: modulosCompletos,
                      title: 'Completos\n${modulosCompletos.toInt()}',
                      color: AppTheme.primaryColor,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: modulosRestantes,
                      title: 'Restantes\n${modulosRestantes.toInt()}',
                      color: Colors.grey[400],
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardEstatisticasExercicios(Map<String, dynamic> estatisticas) {
    final totalRespondidos = estatisticas['total_respondidos'] ?? 0;
    final totalCorretos = estatisticas['total_corretos'] ?? 0;
    final taxaAcerto = estatisticas['taxa_acerto_geral'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas de Exercícios',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('$totalRespondidos', 'Respondidos', Icons.assignment),
                _buildStatCard('$totalCorretos', 'Corretos', Icons.check),
                _buildStatCard('$taxaAcerto%', 'Taxa de Acerto', Icons.percent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGamificacao(Map<String, dynamic> gamificacao) {
    final conquistasDesbloqueadas = gamificacao['conquistas_desbloqueadas'] ?? 0;
    final conquistasTotais = gamificacao['conquistas_totais'] ?? 18;
    final streakAtual = gamificacao['streak_atual'] ?? 0;
    final melhorStreak = gamificacao['melhor_streak'] ?? 0;
    final pontosBonus = gamificacao['pontos_bonus'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Gamificação',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('$conquistasDesbloqueadas/$conquistasTotais', 'Conquistas', Icons.emoji_events),
                _buildStatCard('$streakAtual', 'Streak Atual', Icons.local_fire_department),
                _buildStatCard('$melhorStreak', 'Melhor Streak', Icons.whatshot),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Center(
              child: _buildStatCard('$pontosBonus', 'Pontos Bônus', Icons.stars),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalisePorUnidade() {
    if (_relatorioCompleto == null) return const Center(child: Text('Erro ao carregar dados'));

    final analisePorUnidade = _relatorioCompleto!['analise_por_unidade'] as Map<String, dynamic>;
    
    // Criar dados para o gráfico de barras
    final dadosGrafico = <String, double>{};
    analisePorUnidade.forEach((unidade, dados) {
      final progresso = (dados['progresso_percentual'] ?? 0).toDouble() / 100.0;
      dadosGrafico[unidade] = progresso;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Gráfico de progresso por unidade
          ProgressChart(
            data: dadosGrafico,
            title: 'Progresso por Unidade Temática',
            primaryColor: AppTheme.primaryColor,
          ),
          
          const SizedBox(height: 16),
          
          // Cards detalhados por unidade
          ...analisePorUnidade.entries.map((entry) {
            final unidade = entry.key;
            final dadosUnidade = entry.value as Map<String, dynamic>;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildIconeUnidade(unidade),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            unidade,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        RadialProgressWidget(
                          progress: dadosUnidade['progresso_percentual'] / 100.0,
                          label: 'Completo',
                          value: '${dadosUnidade['progresso_percentual']}%',
                          color: _getCorUnidade(unidade),
                          size: 80,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          '${dadosUnidade['modulos_completos']}/${dadosUnidade['total_modulos']}',
                          'Módulos',
                          Icons.check_circle,
                        ),
                        _buildStatCard(
                          '${dadosUnidade['pontos_conquistados']}',
                          'Pontos',
                          Icons.stars,
                        ),
                        _buildStatCard(
                          '${dadosUnidade['taxa_acerto_media']}%',
                          'Taxa de Acerto',
                          Icons.percent,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Status: ${dadosUnidade['status']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getCorStatus(dadosUnidade['status']),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecomendacoes() {
    if (_relatorioCompleto == null) return const Center(child: Text('Erro ao carregar dados'));

    final recomendacoes = _relatorioCompleto!['recomendacoes'] as List<dynamic>;
    final analiseDesempenho = _relatorioCompleto!['analise_desempenho'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Análise de desempenho
          _buildCardAnaliseDesempenho(analiseDesempenho),
          
          const SizedBox(height: 16),
          
          // Recomendações
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: AppTheme.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Recomendações Personalizadas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ...recomendacoes.map((rec) => _buildRecomendacaoItem(rec)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAnaliseDesempenho(Map<String, dynamic> analise) {
    final pontosFortes = analise['pontos_fortes'] as List<dynamic>;
    final areasMelhoria = analise['areas_melhoria'] as List<dynamic>;
    final equilibrio = analise['equilibrio_geral'] as String;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Análise de Desempenho',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pontos fortes
            Text(
              '🎯 Pontos Fortes:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...pontosFortes.map((ponto) => Text(
              '• ${ponto['unidade']} (${ponto['progresso']}%)',
              style: Theme.of(context).textTheme.bodyMedium,
            )).toList(),
            
            const SizedBox(height: 16),
            
            // Áreas de melhoria
            Text(
              '📈 Áreas para Melhoria:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...areasMelhoria.map((area) => Text(
              '• ${area['unidade']} (${area['progresso']}%)',
              style: Theme.of(context).textTheme.bodyMedium,
            )).toList(),
            
            const SizedBox(height: 16),
            
            // Equilíbrio geral
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCorEquilibrio(equilibrio).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCorEquilibrio(equilibrio).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(_getIconeEquilibrio(equilibrio), color: _getCorEquilibrio(equilibrio)),
                  const SizedBox(width: 8),
                  Text(
                    'Equilíbrio Geral: $equilibrio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getCorEquilibrio(equilibrio),
                      fontWeight: FontWeight.w500,
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

  Widget _buildRecomendacaoItem(Map<String, dynamic> recomendacao) {
    final prioridade = recomendacao['prioridade'] as String;
    final titulo = recomendacao['titulo'] as String;
    final descricao = recomendacao['descricao'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCorPrioridade(prioridade).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getCorPrioridade(prioridade).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getIconePrioridade(prioridade), 
                color: _getCorPrioridade(prioridade), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _getCorPrioridade(prioridade),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCorPrioridade(prioridade),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  prioridade.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares para cores e ícones
  
  Widget _buildIconeUnidade(String unidade) {
    IconData icone;
    Color cor;
    
    switch (unidade) {
      case 'Números':
        icone = Icons.calculate;
        cor = Colors.blue;
        break;
      case 'Álgebra':
        icone = Icons.functions;
        cor = Colors.purple;
        break;
      case 'Geometria':
        icone = Icons.category;
        cor = Colors.green;
        break;
      case 'Grandezas e Medidas':
        icone = Icons.straighten;
        cor = Colors.orange;
        break;
      case 'Probabilidade e Estatística':
        icone = Icons.bar_chart;
        cor = Colors.red;
        break;
      default:
        icone = Icons.school;
        cor = AppTheme.primaryColor;
    }
    
    return Icon(icone, color: cor);
  }

  Color _getCorUnidade(String unidade) {
    switch (unidade) {
      case 'Números': return Colors.blue;
      case 'Álgebra': return Colors.purple;
      case 'Geometria': return Colors.green;
      case 'Grandezas e Medidas': return Colors.orange;
      case 'Probabilidade e Estatística': return Colors.red;
      default: return AppTheme.primaryColor;
    }
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'Completa': return Colors.green;
      case 'Quase Completa': return Colors.lightGreen;
      case 'Em Progresso': return Colors.orange;
      case 'Iniciada': return Colors.blue;
      case 'Não Iniciada': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getCorPrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta': return Colors.red;
      case 'media': return Colors.orange;
      case 'baixa': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getIconePrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta': return Icons.priority_high;
      case 'media': return Icons.warning;
      case 'baixa': return Icons.info;
      default: return Icons.help;
    }
  }

  Color _getCorEquilibrio(String equilibrio) {
    switch (equilibrio) {
      case 'Equilibrado': return Colors.green;
      case 'Levemente Desbalanceado': return Colors.orange;
      case 'Desbalanceado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getIconeEquilibrio(String equilibrio) {
    switch (equilibrio) {
      case 'Equilibrado': return Icons.balance;
      case 'Levemente Desbalanceado': return Icons.trending_neutral;
      case 'Desbalanceado': return Icons.warning;
      default: return Icons.help;
    }
  }

}
