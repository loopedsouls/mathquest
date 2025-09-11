import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/conquista.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen>
    with SingleTickerProviderStateMixin {
  List<Conquista> _conquistas = [];

  bool _carregando = true;
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() => _carregando = true);

    try {
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

      setState(() => _carregando = false);
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Conquistas',
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
            Tab(text: 'Desbloqueadas'),
            Tab(text: 'Bloqueadas'),
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
              ],
            ),
    );
  }

  Widget _buildConquistasDesbloqueadas() {
    final conquistasDesbloqueadas =
        _conquistas.where((c) => c.desbloqueada).toList();

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
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child:
                  Text(conquista.emoji, style: const TextStyle(fontSize: 20)),
            ),
            title: Text(
              conquista.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(conquista.descricao),
            trailing: Text(
              '+${conquista.pontosBonus} XP',
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
        _conquistas.where((c) => !c.desbloqueada).toList();

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
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[100],
              child: Icon(Icons.lock, color: Colors.grey[400], size: 20),
            ),
            title: Text(
              conquista.titulo,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              conquista.descricao,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        );
      },
    );
  }
}
