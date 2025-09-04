import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../services/explicacao_service.dart';

class HistoricoExplicacoesScreen extends StatefulWidget {
  const HistoricoExplicacoesScreen({super.key});

  @override
  State<HistoricoExplicacoesScreen> createState() => _HistoricoExplicacoesScreenState();
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
      final resultados = await ExplicacaoService.buscarExplicacoes(termo: termo);
      
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
            Tab(text: 'Pontos Fracos', icon: Icon(Icons.trending_down, size: 20)),
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
    final errosPorUnidade = _estatisticas['erros_por_unidade'] as List<dynamic>? ?? [];

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
    final errosPorTopico = _estatisticas['erros_por_topico'] as List<dynamic>? ?? [];

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
            ...errosPorTopico.take(10).map((item) => _buildTopicoItem(item)).toList(),
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

    final formatDate = '${ultimoErro.day.toString().padLeft(2, '0')}/${ultimoErro.month.toString().padLeft(2, '0')}/${ultimoErro.year}';

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
    final explicacoes = _unidadeFiltro != null 
        ? _explicacoesPorUnidade 
        : _explicacoesPorTopico;

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
              if (_unidadeFiltro != null || _topicoFiltro != null || _searchTerm.isNotEmpty)
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
            ...explicacoes.map((explicacao) => _buildExplicacaoItem(explicacao)),
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

    final formatDate = '${dataErro.day.toString().padLeft(2, '0')}/${dataErro.month.toString().padLeft(2, '0')}/${dataErro.year} ${dataErro.hour.toString().padLeft(2, '0')}:${dataErro.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.quiz, color: AppTheme.primaryColor),
        title: Text(
          pergunta.length > 50 
              ? '${pergunta.substring(0, 50)}...' 
              : pergunta,
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
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppTheme.primaryColor, size: 20),
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
