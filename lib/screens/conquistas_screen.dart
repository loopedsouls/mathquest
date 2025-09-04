import 'package:flutter/material.dart';
import '../models/conquista.dart';
import '../services/gamificacao_service.dart';
import '../theme/app_theme.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> with TickerProviderStateMixin {
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
      final desbloqueadas = await GamificacaoService.obterConquistasDesbloqueadas();
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
            ...conquistas.map((conquista) => _buildConquistaCard(conquista, true)),
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
            ...conquistas.map((conquista) => _buildConquistaCard(conquista, false)),
          ],
        );
      },
    );
  }

  Widget _buildEstatisticas() {
    if (estatisticas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final conquistasDesbloqueadasCount = estatisticas['conquistas_desbloqueadas'] ?? 0;
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
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
                _buildDica('🔥', 'Mantenha sequências de acertos para conquistas de streak'),
                _buildDica('⚡', 'Responda rapidamente para conquistas de velocidade'),
                _buildDica('🎯', 'Complete módulos com 100% de acerto para ser perfeccionista'),
                _buildDica('📚', 'Complete unidades inteiras para conquistas especiais'),
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

  Widget _buildStatCard(String titulo, String valor, IconData icone, Color cor) {
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
