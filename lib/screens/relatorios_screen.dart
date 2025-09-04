import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/relatorio_service.dart';
import '../widgets/relatorio_charts.dart';
import '../widgets/modern_components.dart';
import '../services/explicacao_service.dart';
import '../models/conquista.dart';
import '../services/gamificacao_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen>
    with TickerProviderStateMixin {
  // Dados para Conquistas
  List<Conquista> conquistasDesbloqueadas = [];
  List<Conquista> conquistasBloqueadas = [];
  Map<String, dynamic> estatisticasConquistas = {};

  // Dados para Histórico de Explicações
  List<Map<String, dynamic>> _explicacoesPorUnidade = [];
  List<Map<String, dynamic>> _explicacoesPorTopico = [];
  List<Map<String, dynamic>> _pontosFracos = [];
  Map<String, dynamic> _estatisticasExplicacoes = {};

  // Filtros
  String? _unidadeFiltro;
  String? _topicoFiltro;
  String _searchTerm = '';

  // Dados para Relatórios Gerais
  Map<String, dynamic>? _relatorioCompleto;

  bool _carregando = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _carregarTodosDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarTodosDados() async {
    setState(() => _carregando = true);

    try {
      // Carrega dados de conquistas
      final desbloqueadas =
          await GamificacaoService.obterConquistasDesbloqueadas();
      final bloqueadas = await GamificacaoService.obterConquistasBloqueadas();
      final statsConquistas = await GamificacaoService.obterEstatisticas();

      // Carrega dados de explicações
      final estatisticasExp =
          await ExplicacaoService.obterEstatisticasPorTema();
      final pontosFracos = await ExplicacaoService.obterPontosFracos();

      // Carrega relatório completo
      final relatorio = await RelatorioService.gerarRelatorioCompleto();

      setState(() {
        conquistasDesbloqueadas = desbloqueadas;
        conquistasBloqueadas = bloqueadas;
        estatisticasConquistas = statsConquistas;
        _estatisticasExplicacoes = estatisticasExp;
        _pontosFracos = pontosFracos;
        _relatorioCompleto = relatorio;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
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
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
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

  // ===== MÉTODOS PARA CONQUISTAS =====

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

  Widget _buildEstatisticasConquistas() {
    if (estatisticasConquistas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final conquistasDesbloqueadasCount =
        estatisticasConquistas['conquistas_desbloqueadas'] ?? 0;
    final conquistasTotais = estatisticasConquistas['conquistas_totais'] ?? 1;
    final porcentagem =
        (estatisticasConquistas['porcentagem_conquistas'] ?? 0.0) * 100;
    final streakAtual = estatisticasConquistas['streak_atual'] ?? 0;
    final melhorStreak = estatisticasConquistas['melhor_streak'] ?? 0;
    final pontosBonus = estatisticasConquistas['pontos_bonus'] ?? 0;

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

  // ===== MÉTODOS PARA HISTÓRICO DE EXPLICAÇÕES =====

  Widget _buildHistoricoExplicacoes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstatisticasExplicacoesCard(),
          const SizedBox(height: 20),
          _buildUnidadesCard(),
          const SizedBox(height: 20),
          _buildTopicosCard(),
          if (_unidadeFiltro != null || _topicoFiltro != null) ...[
            const SizedBox(height: 20),
            _buildExplicacoesCard(),
          ],
          const SizedBox(height: 20),
          _buildBuscarCard(),
        ],
      ),
    );
  }

  Widget _buildEstatisticasExplicacoesCard() {
    final errosRecentes = _estatisticasExplicacoes['erros_ultimos_7_dias'] ?? 0;
    final totalExplicacoes = _estatisticasExplicacoes['total_explicacoes'] ?? 0;

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

  Widget _buildBuscarCard() {
    return ModernCard(
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
    );
  }

  Widget _buildPontosFracos() {
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

  Widget _buildRelatorioGeral() {
    if (_relatorioCompleto == null) {
      return const Center(child: Text('Erro ao carregar dados'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVisaoGeral(),
          const SizedBox(height: 16),
          _buildAnalisePorUnidade(),
          const SizedBox(height: 16),
          _buildRecomendacoes(),
        ],
      ),
    );
  }

  // ===== MÉTODOS AUXILIARES =====

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
        _estatisticasExplicacoes['erros_por_unidade'] as List<dynamic>? ?? [];

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
        _estatisticasExplicacoes['erros_por_topico'] as List<dynamic>? ?? [];

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

  // Métodos para relatório geral - simplificados
  Widget _buildVisaoGeral() {
    if (_relatorioCompleto == null) return const SizedBox();

    final progressoGeral = _relatorioCompleto!['progresso_geral'] ?? {};
    final estatisticasExercicios =
        _relatorioCompleto!['estatisticas_exercicios'] ?? {};

    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildAnalisePorUnidade() {
    if (_relatorioCompleto == null) return const SizedBox();

    final analisePorUnidade =
        _relatorioCompleto!['analise_por_unidade'] as Map<String, dynamic>? ??
            {};

    return Column(
      children: analisePorUnidade.entries.map((entry) {
        final unidade = entry.key;
        final dados = entry.value as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: _buildIconeUnidade(unidade),
            title: Text(unidade),
            subtitle: Text('${dados['progresso_percentual'] ?? 0}% completo'),
            trailing: Text('${dados['pontos_conquistados'] ?? 0} pts'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecomendacoes() {
    if (_relatorioCompleto == null) return const SizedBox();

    final recomendacoes =
        _relatorioCompleto!['recomendacoes'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                const Text(
                  'Recomendações',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recomendacoes.map((rec) => ListTile(
                  leading: const Icon(Icons.arrow_right),
                  title: Text(rec['titulo'] ?? ''),
                  subtitle: Text(rec['descricao'] ?? ''),
                )),
          ],
        ),
      ),
    );
  }

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
