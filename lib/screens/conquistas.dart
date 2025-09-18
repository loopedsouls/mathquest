import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/conquista.dart';
import '../services/gamificacao_service.dart';

class ConquistasScreen extends StatefulWidget {
  const ConquistasScreen({super.key});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen>
    with TickerProviderStateMixin {
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
      // Carrega conquistas reais do serviço de gamificação
      final conquistasDesbloqueadas =
          await GamificacaoService.obterConquistasDesbloqueadas();
      final conquistasBloqueadas =
          await GamificacaoService.obterConquistasBloqueadas();

      _conquistas = [
        ...conquistasDesbloqueadas,
        ...conquistasBloqueadas,
      ];

      setState(() => _carregando = false);
      _animationController.forward();
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar conquistas: $e'),
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
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhuma conquista desbloqueada ainda',
                style: TextStyle(
                  fontSize: 20,
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Continue estudando para desbloquear suas primeiras conquistas!\nCada exercício completado e meta alcançada te aproxima de novas recompensas.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkTextSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Continue praticando para desbloquear suas conquistas!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkTextSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasDesbloqueadas.length,
      itemBuilder: (context, index) {
        final conquista = conquistasDesbloqueadas[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                (index * 0.1) + 0.5,
                curve: Curves.easeOutCubic,
              ),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.15),
                      AppTheme.primaryLightColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.primaryLightColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                conquista.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conquista.titulo,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.darkTextPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  conquista.descricao,
                                  style: TextStyle(
                                    color: AppTheme.darkTextSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '+${conquista.pontosBonus} XP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (conquista.dataConquista != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatarData(conquista.dataConquista!),
                                  style: TextStyle(
                                    color: AppTheme.darkTextSecondaryColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.darkBorderColor,
                              ),
                            ),
                            child: Text(
                              _obterTipoConquista(conquista.tipo),
                              style: TextStyle(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Desbloqueada',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConquistasBloqueadas() {
    final conquistasBloqueadas =
        _conquistas.where((c) => !c.desbloqueada).toList();

    if (conquistasBloqueadas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 60,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Parabéns! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você desbloqueou todas as conquistas disponíveis!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkTextSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conquistasBloqueadas.length,
      itemBuilder: (context, index) {
        final conquista = conquistasBloqueadas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkBorderColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.grey[600],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conquista.titulo,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conquista.descricao,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${conquista.pontosBonus} XP',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _obterTipoConquista(conquista.tipo),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgresoConquista(conquista),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgresoConquista(Conquista conquista) {
    // Simula progresso baseado no tipo de conquista
    double progresso = 0.0;
    String textoProgresso = '';

    switch (conquista.tipo) {
      case TipoConquista.streakExercicios:
        final streakRequerida = (conquista.criterios['streak'] as int?) ?? 5;
        progresso = 0.3; // 30% de progresso simulado
        textoProgresso = 'Sequência: 2/$streakRequerida';
        break;
      case TipoConquista.moduloCompleto:
        final quantidadeRequerida =
            (conquista.criterios['quantidade'] as int?) ?? 3;
        progresso = 0.2;
        textoProgresso = 'Módulos: 2/$quantidadeRequerida';
        break;
      case TipoConquista.pontuacaoTotal:
        final pontosRequeridos =
            (conquista.criterios['pontos'] as int?) ?? 1000;
        progresso = 0.45;
        textoProgresso =
            'Pontos: ${(pontosRequeridos * 0.45).round()}/$pontosRequeridos';
        break;
      default:
        progresso = 0.0;
        textoProgresso = 'Não iniciado';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              textoProgresso,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  String _formatarData(DateTime data) {
    final agora = DateTime.now();
    final diferenca = agora.difference(data);

    if (diferenca.inDays == 0) {
      return 'Hoje';
    } else if (diferenca.inDays == 1) {
      return 'Ontem';
    } else if (diferenca.inDays < 7) {
      return '${diferenca.inDays} dias atrás';
    } else {
      return '${data.day}/${data.month}/${data.year}';
    }
  }

  String _obterTipoConquista(TipoConquista tipo) {
    switch (tipo) {
      case TipoConquista.moduloCompleto:
        return 'Módulo Completo';
      case TipoConquista.unidadeCompleta:
        return 'Unidade Completa';
      case TipoConquista.nivelAlcancado:
        return 'Nível Alcançado';
      case TipoConquista.streakExercicios:
        return 'Sequência';
      case TipoConquista.pontuacaoTotal:
        return 'Pontuação';
      case TipoConquista.tempoRecord:
        return 'Tempo Record';
      case TipoConquista.perfeccionista:
        return 'Perfeição';
      case TipoConquista.persistente:
        return 'Persistência';
    }
  }
}
