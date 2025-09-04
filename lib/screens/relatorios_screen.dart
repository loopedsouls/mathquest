import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/relatorio_service.dart';
import '../widgets/relatorio_charts.dart';
import '../widgets/modern_components.dart';
import '../services/explicacao_service.dart';
import '../models/conquista.dart';
import '../services/gamificacao_service.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen>
    with TickerProviderStateMixin {
  List<Conquista> conquistasDesbloqueadas = [];
  List<Conquista> conquistasBloqueadas = [];
  Map<String, dynamic> estatisticas = {};
  bool isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => isLoading = true);

    try {
      final desbloqueadas =
          await GamificacaoService.obterConquistasDesbloqueadas();
      final bloqueadas = await GamificacaoService.obterConquistasBloqueadas();
      final stats = await GamificacaoService.obterEstatisticas();

      setState(() {
        conquistasDesbloqueadas = desbloqueadas;
        conquistasBloqueadas = bloqueadas;
        estatisticas = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar conquistas: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Desbloqueadas'),
            Tab(icon: Icon(Icons.lock), text: 'Bloqueadas'),
            Tab(icon: Icon(Icons.analytics), text: 'Estatísticas'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConquistasDesbloqueadas(),
                _buildConquistasBloqueadas(),
                _buildEstatisticas(),
              ],
            ),
    );
  }

  Widget _buildConquistasDesbloqueadas() {
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Continue resolvendo exercícios para desbloquear suas primeiras conquistas!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupa conquistas por tipo
    final conquistasPorTipo = <TipoConquista, List<Conquista>>{};
    for (final conquista in conquistasDesbloqueadas) {
      conquistasPorTipo.putIfAbsent(conquista.tipo, () => []).add(conquista);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasPorTipo.length,
      itemBuilder: (context, index) {
        final tipo = conquistasPorTipo.keys.elementAt(index);
        final conquistas = conquistasPorTipo[tipo]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Text(
              _obterTituloTipo(tipo),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...conquistas
                .map((conquista) => _buildConquistaCard(conquista, true)),
          ],
        );
      },
    );
  }

  Widget _buildConquistasBloqueadas() {
    if (conquistasBloqueadas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Parabéns!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Você desbloqueou todas as conquistas disponíveis!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupa conquistas por tipo
    final conquistasPorTipo = <TipoConquista, List<Conquista>>{};
    for (final conquista in conquistasBloqueadas) {
      conquistasPorTipo.putIfAbsent(conquista.tipo, () => []).add(conquista);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasPorTipo.length,
      itemBuilder: (context, index) {
        final tipo = conquistasPorTipo.keys.elementAt(index);
        final conquistas = conquistasPorTipo[tipo]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 24),
            Text(
              _obterTituloTipo(tipo),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...conquistas
                .map((conquista) => _buildConquistaCard(conquista, false)),
          ],
        );
      },
    );
  }

  Widget _buildEstatisticas() {
    if (estatisticas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final conquistasDesbloqueadasCount =
        estatisticas['conquistas_desbloqueadas'] ?? 0;
    final conquistasTotais = estatisticas['conquistas_totais'] ?? 1;
    final porcentagem = (estatisticas['porcentagem_conquistas'] ?? 0.0) * 100;
    final streakAtual = estatisticas['streak_atual'] ?? 0;
    final melhorStreak = estatisticas['melhor_streak'] ?? 0;
    final pontosBonus = estatisticas['pontos_bonus'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progresso geral
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Progresso Geral',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$conquistasDesbloqueadasCount de $conquistasTotais conquistas',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      '${porcentagem.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: porcentagem / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Cards de estatísticas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Streak Atual',
                streakAtual.toString(),
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Melhor Streak',
                melhorStreak.toString(),
                Icons.whatshot,
                Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildStatCard(
          'Pontos Bônus',
          pontosBonus.toString(),
          Icons.stars,
          AppTheme.accentColor,
        ),

        const SizedBox(height: 24),

        // Dicas para desbloquear mais conquistas
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
                      'Dicas para Mais Conquistas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDica('🔥',
                    'Mantenha sequências de acertos para conquistas de streak'),
                _buildDica(
                    '⚡', 'Responda rapidamente para conquistas de velocidade'),
                _buildDica('🎯',
                    'Complete módulos com 100% de acerto para ser perfeccionista'),
                _buildDica('📚',
                    'Complete unidades inteiras para conquistas especiais'),
                _buildDica('🏆', 'Acumule pontos para conquistas de pontuação'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConquistaCard(Conquista conquista, bool desbloqueada) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: desbloqueada ? AppTheme.primaryColor : Colors.grey[400],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            _obterIconeConquista(conquista),
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          conquista.titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: desbloqueada ? null : Colors.grey[600],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conquista.descricao,
              style: TextStyle(
                color: desbloqueada ? null : Colors.grey[500],
              ),
            ),
            if (desbloqueada && conquista.dataConquista != null) ...[
              const SizedBox(height: 4),
              Text(
                'Desbloqueada em ${_formatarData(conquista.dataConquista!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: desbloqueada
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+${conquista.pontosBonus}',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'pontos',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ],
              )
            : Icon(
                Icons.lock,
                color: Colors.grey[400],
              ),
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: cor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              titulo,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDica(String emoji, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _obterTituloTipo(TipoConquista tipo) {
    switch (tipo) {
      case TipoConquista.moduloCompleto:
        return 'Módulos Completos';
      case TipoConquista.unidadeCompleta:
        return 'Unidades Completas';
      case TipoConquista.nivelAlcancado:
        return 'Níveis Alcançados';
      case TipoConquista.streakExercicios:
        return 'Sequências de Acertos';
      case TipoConquista.pontuacaoTotal:
        return 'Pontuação Total';
      case TipoConquista.tempoRecord:
        return 'Recordes de Tempo';
      case TipoConquista.perfeccionista:
        return 'Perfeccionista';
      case TipoConquista.persistente:
        return 'Persistência';
    }
  }

  IconData _obterIconeConquista(Conquista conquista) {
    switch (conquista.tipo) {
      case TipoConquista.moduloCompleto:
        return Icons.check_circle;
      case TipoConquista.unidadeCompleta:
        return Icons.library_books;
      case TipoConquista.nivelAlcancado:
        return Icons.trending_up;
      case TipoConquista.streakExercicios:
        return Icons.local_fire_department;
      case TipoConquista.pontuacaoTotal:
        return Icons.stars;
      case TipoConquista.tempoRecord:
        return Icons.speed;
      case TipoConquista.perfeccionista:
        return Icons.emoji_events;
      case TipoConquista.persistente:
        return Icons.calendar_today;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

class HistoricoExplicacoesScreen extends StatefulWidget {
  const HistoricoExplicacoesScreen({super.key});

  @override
  State<HistoricoExplicacoesScreen> createState() =>
      _HistoricoExplicacoesScreenState();
}

class _HistoricoExplicacoesScreenState extends State<HistoricoExplicacoesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Filtros
  String? _unidadeFiltro;
  String? _topicoFiltro;
  String _searchTerm = '';

  // Dados
  List<Map<String, dynamic>> _explicacoesPorUnidade = [];
  List<Map<String, dynamic>> _explicacoesPorTopico = [];
  List<Map<String, dynamic>> _pontosFracos = [];
  Map<String, dynamic> _estatisticas = {};

  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
      final estatisticas = await ExplicacaoService.obterEstatisticasPorTema();
      final pontosFracos = await ExplicacaoService.obterPontosFracos();

      setState(() {
        _estatisticas = estatisticas;
        _pontosFracos = pontosFracos;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      _mostrarErro('Erro ao carregar dados: $e');
    }
  }

  Future<void> _carregarExplicacoesPorUnidade(String unidade) async {
    try {
      final explicacoes = await ExplicacaoService.obterHistoricoPorUnidade(
        unidade: unidade,
      );

      setState(() {
        _explicacoesPorUnidade = explicacoes;
        _unidadeFiltro = unidade;
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar explicações: $e');
    }
  }

  Future<void> _carregarExplicacoesPorTopico(String topico) async {
    try {
      final explicacoes = await ExplicacaoService.obterHistoricoPorTopico(
        topico: topico,
      );

      setState(() {
        _explicacoesPorTopico = explicacoes;
        _topicoFiltro = topico;
      });
    } catch (e) {
      _mostrarErro('Erro ao carregar explicações: $e');
    }
  }

  Future<void> _buscarExplicacoes(String termo) async {
    if (termo.isEmpty) return;

    try {
      final resultados =
          await ExplicacaoService.buscarExplicacoes(termo: termo);

      setState(() {
        _explicacoesPorUnidade = resultados;
        _searchTerm = termo;
      });
    } catch (e) {
      _mostrarErro('Erro na busca: $e');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Histórico de Explicações',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Por Tema', icon: Icon(Icons.category, size: 20)),
            Tab(
                text: 'Pontos Fracos',
                icon: Icon(Icons.trending_down, size: 20)),
            Tab(text: 'Buscar', icon: Icon(Icons.search, size: 20)),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabPorTema(),
                _buildTabPontosFracos(),
                _buildTabBuscar(),
              ],
            ),
    );
  }

  Widget _buildTabPorTema() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstatisticasCard(),
          const SizedBox(height: 20),
          _buildUnidadesCard(),
          const SizedBox(height: 20),
          _buildTopicosCard(),
          if (_unidadeFiltro != null || _topicoFiltro != null) ...[
            const SizedBox(height: 20),
            _buildExplicacoesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabPontosFracos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Seus Pontos Fracos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tópicos onde você mais cometeu erros:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                if (_pontosFracos.isEmpty)
                  const Center(
                    child: Text(
                      'Parabéns! Você não tem pontos fracos significativos.',
                      style: TextStyle(color: Colors.green),
                    ),
                  )
                else
                  ..._pontosFracos.map((ponto) => _buildPontoFracoItem(ponto)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBuscar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ModernCard(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por pergunta, explicação ou tópico...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: _buscarExplicacoes,
                ),
                const SizedBox(height: 16),
                if (_searchTerm.isNotEmpty) ...[
                  Text(
                    'Resultados para: "$_searchTerm"',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
          if (_searchTerm.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildExplicacoesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildEstatisticasCard() {
    final errosRecentes = _estatisticas['erros_ultimos_7_dias'] ?? 0;
    final totalExplicacoes = _estatisticas['total_explicacoes'] ?? 0;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Estatísticas Gerais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total de Explicações',
                  totalExplicacoes.toString(),
                  Icons.library_books,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Erros Recentes (7 dias)',
                  errosRecentes.toString(),
                  Icons.error_outline,
                  errosRecentes > 5 ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUnidadesCard() {
    final errosPorUnidade =
        _estatisticas['erros_por_unidade'] as List<dynamic>? ?? [];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erros por Unidade Temática',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (errosPorUnidade.isEmpty)
            const Text('Nenhum erro registrado ainda.')
          else
            ...errosPorUnidade.map((item) => _buildUnidadeItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildTopicosCard() {
    final errosPorTopico =
        _estatisticas['erros_por_topico'] as List<dynamic>? ?? [];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Erros por Tópico Específico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (errosPorTopico.isEmpty)
            const Text('Nenhum erro registrado ainda.')
          else
            ...errosPorTopico
                .take(10)
                .map((item) => _buildTopicoItem(item))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildUnidadeItem(Map<String, dynamic> item) {
    final unidade = item['unidade'] as String;
    final totalErros = item['total_erros'] as int;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Text(
          totalErros.toString(),
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(unidade),
      subtitle: Text('$totalErros erros registrados'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _carregarExplicacoesPorUnidade(unidade),
    );
  }

  Widget _buildTopicoItem(Map<String, dynamic> item) {
    final topico = item['topico_especifico'] as String;
    final totalErros = item['total_erros'] as int;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        child: Text(
          totalErros.toString(),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(topico),
      subtitle: Text('$totalErros erros registrados'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _carregarExplicacoesPorTopico(topico),
    );
  }

  Widget _buildPontoFracoItem(Map<String, dynamic> ponto) {
    final topico = ponto['topico_especifico'] as String;
    final totalErros = ponto['total_erros'] as int;
    final ultimoErro = DateTime.parse(ponto['ultimo_erro'] as String);
    final unidade = ponto['unidade'] as String;
    final ano = ponto['ano'] as String;

    final formatDate =
        '${ultimoErro.day.toString().padLeft(2, '0')}/${ultimoErro.month.toString().padLeft(2, '0')}/${ultimoErro.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          child: Text(
            totalErros.toString(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          topico,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$unidade - $ano'),
            Text(
              'Último erro: $formatDate',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Icon(
          totalErros >= 5 ? Icons.priority_high : Icons.warning,
          color: totalErros >= 5 ? Colors.red : Colors.orange,
        ),
        onTap: () => _carregarExplicacoesPorTopico(topico),
      ),
    );
  }

  Widget _buildExplicacoesCard() {
    final explicacoes =
        _unidadeFiltro != null ? _explicacoesPorUnidade : _explicacoesPorTopico;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                _searchTerm.isNotEmpty
                    ? 'Resultados da Busca'
                    : 'Histórico de Explicações',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_unidadeFiltro != null ||
                  _topicoFiltro != null ||
                  _searchTerm.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _unidadeFiltro = null;
                    _topicoFiltro = null;
                    _searchTerm = '';
                    _explicacoesPorUnidade.clear();
                    _explicacoesPorTopico.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (explicacoes.isEmpty)
            const Text('Nenhuma explicação encontrada.')
          else
            ...explicacoes
                .map((explicacao) => _buildExplicacaoItem(explicacao)),
        ],
      ),
    );
  }

  Widget _buildExplicacaoItem(Map<String, dynamic> explicacao) {
    final pergunta = explicacao['pergunta'] as String;
    final respostaUsuario = explicacao['resposta_usuario'] as String;
    final respostaCorreta = explicacao['resposta_correta'] as String;
    final explicacaoTexto = explicacao['explicacao'] as String;
    final dataErro = DateTime.parse(explicacao['data_erro'] as String);
    final topico = explicacao['topico_especifico'] as String;

    final formatDate =
        '${dataErro.day.toString().padLeft(2, '0')}/${dataErro.month.toString().padLeft(2, '0')}/${dataErro.year} ${dataErro.hour.toString().padLeft(2, '0')}:${dataErro.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.quiz, color: AppTheme.primaryColor),
        title: Text(
          pergunta.length > 50 ? '${pergunta.substring(0, 50)}...' : pergunta,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tópico: $topico'),
            Text(
              formatDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pergunta:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(pergunta),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sua resposta:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(respostaUsuario),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resposta correta:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(respostaCorreta),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Explicação:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(explicacaoTexto),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen>
    with TickerProviderStateMixin {
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
    if (_relatorioCompleto == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final progressoGeral = _relatorioCompleto!['progresso_geral'];
    final estatisticasExercicios =
        _relatorioCompleto!['estatisticas_exercicios'];
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
                  subtitle:
                      '${progressoGeral['modulos_completos'] ?? 0} de ${progressoGeral['total_modulos'] ?? 20} módulos',
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
                  value:
                      '${progressoGeral['modulos_completos'] ?? 0}/${progressoGeral['total_modulos'] ?? 20}',
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
    final modulosCompletos =
        (progressoGeral['modulos_completos'] ?? 0).toDouble();
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
                _buildStatCard(
                    '$totalRespondidos', 'Respondidos', Icons.assignment),
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
    final conquistasDesbloqueadas =
        gamificacao['conquistas_desbloqueadas'] ?? 0;
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
                const Icon(Icons.emoji_events, color: Colors.orange),
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
                _buildStatCard('$conquistasDesbloqueadas/$conquistasTotais',
                    'Conquistas', Icons.emoji_events),
                _buildStatCard('$streakAtual', 'Streak Atual',
                    Icons.local_fire_department),
                _buildStatCard(
                    '$melhorStreak', 'Melhor Streak', Icons.whatshot),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child:
                  _buildStatCard('$pontosBonus', 'Pontos Bônus', Icons.stars),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalisePorUnidade() {
    if (_relatorioCompleto == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final analisePorUnidade =
        _relatorioCompleto!['analise_por_unidade'] as Map<String, dynamic>;

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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        RadialProgressWidget(
                          progress:
                              dadosUnidade['progresso_percentual'] / 100.0,
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
    if (_relatorioCompleto == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    final recomendacoes = _relatorioCompleto!['recomendacoes'] as List<dynamic>;
    final analiseDesempenho =
        _relatorioCompleto!['analise_desempenho'] as Map<String, dynamic>;

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
                  ...recomendacoes
                      .map((rec) => _buildRecomendacaoItem(rec))
                      .toList(),
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
            ...pontosFortes
                .map((ponto) => Text(
                      '• ${ponto['unidade']} (${ponto['progresso']}%)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ))
                .toList(),

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
            ...areasMelhoria
                .map((area) => Text(
                      '• ${area['unidade']} (${area['progresso']}%)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ))
                .toList(),

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
                  Icon(_getIconeEquilibrio(equilibrio),
                      color: _getCorEquilibrio(equilibrio)),
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
      case 'Números':
        return Colors.blue;
      case 'Álgebra':
        return Colors.purple;
      case 'Geometria':
        return Colors.green;
      case 'Grandezas e Medidas':
        return Colors.orange;
      case 'Probabilidade e Estatística':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'Completa':
        return Colors.green;
      case 'Quase Completa':
        return Colors.lightGreen;
      case 'Em Progresso':
        return Colors.orange;
      case 'Iniciada':
        return Colors.blue;
      case 'Não Iniciada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getCorPrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baixa':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconePrioridade(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return Icons.priority_high;
      case 'media':
        return Icons.warning;
      case 'baixa':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  Color _getCorEquilibrio(String equilibrio) {
    switch (equilibrio) {
      case 'Equilibrado':
        return Colors.green;
      case 'Levemente Desbalanceado':
        return Colors.orange;
      case 'Desbalanceado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconeEquilibrio(String equilibrio) {
    switch (equilibrio) {
      case 'Equilibrado':
        return Icons.balance;
      case 'Levemente Desbalanceado':
        return Icons.trending_neutral;
      case 'Desbalanceado':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}
