import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../widgets/streak_widget.dart';
import '../models/progresso_usuario.dart';
import '../models/modulo_bncc.dart';
import '../services/progresso_service.dart';
import 'chat/chat_with_sidebar_screen.dart';

// Configuração para o programador - definir como false na produção
// ATENÇÃO: Manter como 'false' em produção para respeitar o sistema de progressão
// Definir como 'true' apenas durante desenvolvimento/testes
const bool debugUnlockAllModules = true;

class ModulosScreen extends StatefulWidget {
  final bool isOfflineMode;
  final List<Map<String, dynamic>> exerciciosOffline;

  const ModulosScreen({
    super.key,
    required this.isOfflineMode,
    required this.exerciciosOffline,
  });

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen>
    with TickerProviderStateMixin {
  ProgressoUsuario? _progresso;
  String _unidadeSelecionada = 'Números';
  bool _carregando = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarProgresso();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarProgresso() async {
    try {
      final progresso = await ProgressoService.carregarProgresso();
      setState(() {
        _progresso = progresso;
        _carregando = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar progresso: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

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
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileTabletLayout(isTablet, isDesktop),
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

  Widget _buildDesktopLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02, // 2% of screen width
        vertical: screenHeight * 0.02, // 2% of screen height
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar esquerdo - Informações e progresso
          Expanded(
            flex: 1,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.35, // Max 35% of screen width
                maxHeight: screenHeight * 0.9, // Max 90% of screen height
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    _buildDesktopHeader(),
                    SizedBox(height: screenHeight * 0.02),
                    _buildDesktopProgressCard(),
                    SizedBox(height: screenHeight * 0.02),
                    _buildDesktopStreakCard(),
                    SizedBox(height: screenHeight * 0.02),
                    _buildDesktopStatsCard(),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: screenWidth * 0.02), // 2% spacing

          // Área principal - Módulos
          Expanded(
            flex: 2,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.6, // Max 60% of screen width
                maxHeight: screenHeight * 0.9, // Max 90% of screen height
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopModulesHeader(),
                  SizedBox(height: screenHeight * 0.02),
                  _buildDesktopUnidadesSelector(),
                  SizedBox(height: screenHeight * 0.02),
                  Expanded(
                    child: _buildDesktopModulosGrid(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(bool isTablet, bool isDesktop) {
    return Column(
      children: [
        _buildHeader(isTablet),
        _buildProgressoGeral(isTablet),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 8 : 6,
          ),
          child: const StreakWidget(),
        ),
        _buildUnidadesSeletor(isTablet),
        Expanded(
          child: _buildModulosGrid(isTablet, isDesktop),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Módulos BNCC',
                      style: AppTheme.headingLarge.copyWith(
                        fontSize: screenWidth > 1400 ? 18 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _progresso != null
                          ? 'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}'
                          : 'Carregando...',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
                tooltip: 'Voltar',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ModernButton(
                  text: 'Dicas',
                  onPressed: _mostrarRecomendacoes,
                  isPrimary: false,
                  icon: Icons.lightbulb_outline_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ModernButton(
                  text: 'Relatório',
                  onPressed: _mostrarRelatorioDetalhado,
                  isPrimary: false,
                  icon: Icons.analytics_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProgressCard() {
    if (_progresso == null) return const SizedBox.shrink();

    final progressoGeral = _progresso!.calcularProgressoGeral();
    final screenWidth = MediaQuery.of(context).size.width;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progresso Geral',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: screenWidth > 1400 ? 16 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.primaryLightColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  top: 8,
                  child: Text(
                    '${(progressoGeral * 100).round()}%',
                    style: AppTheme.headingLarge.copyWith(
                      fontSize: screenWidth > 1400 ? 24 : 20,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 8,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Módulos Completos',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      ModernProgressIndicator(
                        value: progressoGeral,
                        label: '',
                        color: AppTheme.primaryColor,
                      ),
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

  Widget _buildDesktopStreakCard() {
    final screenWidth = MediaQuery.of(context).size.width;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sequência',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: screenWidth > 1400 ? 16 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const StreakWidget(),
        ],
      ),
    );
  }

  Widget _buildDesktopStatsCard() {
    if (_progresso == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estatísticas',
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: screenWidth > 1400 ? 16 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDesktopStatItem(
            '${_progresso!.totalExerciciosCorretos}',
            'Exercícios Corretos',
            Icons.check_circle_outline,
            AppTheme.successColor,
          ),
          const SizedBox(height: 8),
          _buildDesktopStatItem(
            '${_progresso!.pontosPorUnidade.values.fold(0, (a, b) => a + b)}',
            'Pontos Totais',
            Icons.stars_rounded,
            AppTheme.accentColor,
          ),
          const SizedBox(height: 8),
          _buildDesktopStatItem(
            '${_progresso!.modulosCompletos.values.fold(0, (map, count) => map + count.values.where((v) => v).length)}',
            'Módulos Completos',
            Icons.school_rounded,
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatItem(
      String value, String label, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: screenWidth > 1400 ? 14 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopModulesHeader() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Icon(
          Icons.dashboard_customize_rounded,
          color: AppTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Módulos de Estudo',
            style: AppTheme.headingLarge.copyWith(
              fontSize: screenWidth > 1400 ? 20 : 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopUnidadesSelector() {
    final unidades = ModulosBNCCData.obterUnidadesTematicas();
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: unidades.length,
        itemBuilder: (context, index) {
          final unidade = unidades[index];
          final isSelected = unidade == _unidadeSelecionada;
          final progresso =
              _progresso?.calcularProgressoPorUnidade(unidade) ?? 0.0;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.darkSurfaceColor,
              elevation: isSelected ? 2 : 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _unidadeSelecionada = unidade),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  constraints: BoxConstraints(
                    minWidth: screenWidth * 0.08,
                    maxWidth: screenWidth * 0.15,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        unidade,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.darkTextPrimaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progresso,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopModulosGrid() {
    final modulos = ModulosBNCCData.obterModulosPorUnidade(_unidadeSelecionada);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calcula largura do card baseado no número de colunas
    final numColumns = screenWidth > 1600 ? 3 : 2;
    const spacing = 16.0;
    final availableWidth = screenWidth * 0.6 - (spacing * (numColumns + 1));
    final cardWidth = availableWidth / numColumns;

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children:
                _buildDesktopCardRows(modulos, cardWidth, spacing, numColumns),
          );
        },
      ),
    );
  }

  List<Widget> _buildDesktopCardRows(
      List<dynamic> modulos, double cardWidth, double spacing, int numColumns) {
    List<Widget> rows = [];

    for (int i = 0; i < modulos.length; i += numColumns) {
      final rowModulos = modulos.skip(i).take(numColumns).toList();

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int j = 0; j < rowModulos.length; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _buildDesktopModuloCard(rowModulos[j]),
                ),
              ],
              // Preenche espaço restante se a linha não estiver completa
              if (rowModulos.length < numColumns) Expanded(child: Container()),
            ],
          ),
        ),
      );

      // Adiciona espaçamento entre linhas (exceto após a última)
      if (i + numColumns < modulos.length) {
        rows.add(SizedBox(height: spacing));
      }
    }

    return rows;
  }

  Widget _buildDesktopModuloCard(ModuloBNCC modulo) {
    if (_progresso == null) return const SizedBox.shrink();

    final isCompleto = _progresso!.modulosCompletos[modulo.unidadeTematica]
            ?[modulo.anoEscolar] ??
        false;
    final isDesbloqueado = debugUnlockAllModules ||
        _progresso!
            .moduloDesbloqueado(modulo.unidadeTematica, modulo.anoEscolar);
    final chaveModulo = '${modulo.unidadeTematica}_${modulo.anoEscolar}';
    final exerciciosConsecutivos =
        _progresso!.exerciciosCorretosConsecutivos[chaveModulo] ?? 0;
    final taxaAcerto = _progresso!.taxaAcertoPorModulo[chaveModulo] ?? 0.0;

    return ModernCard(
      hasGlow: isDesbloqueado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header expandido para desktop
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleto
                        ? [
                            AppTheme.successColor,
                            AppTheme.successColor.withValues(alpha: 0.7)
                          ]
                        : isDesbloqueado
                            ? [
                                AppTheme.primaryColor,
                                AppTheme.primaryLightColor
                              ]
                            : [
                                AppTheme.darkBorderColor,
                                AppTheme.darkBorderColor
                              ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleto
                      ? Icons.check_circle_rounded
                      : isDesbloqueado
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                  color: isDesbloqueado
                      ? Colors.white
                      : AppTheme.darkTextSecondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.anoEscolar,
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 16,
                        color: isDesbloqueado
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    if (isCompleto || exerciciosConsecutivos > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        isCompleto
                            ? 'Completo!'
                            : '$exerciciosConsecutivos/${modulo.exerciciosNecessarios} exercícios',
                        style: TextStyle(
                          color: isCompleto
                              ? AppTheme.successColor
                              : AppTheme.darkTextSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Conteúdo que se expande para preencher espaço disponível
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modulo.titulo,
                  style: AppTheme.headingMedium.copyWith(
                    fontSize: 16,
                    color: isDesbloqueado
                        ? AppTheme.darkTextPrimaryColor
                        : AppTheme.darkTextSecondaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    modulo.descricao,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppTheme.darkTextSecondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12), // Progresso e ações
          if (isDesbloqueado) ...[
            if (taxaAcerto > 0) ...[
              ModernProgressIndicator(
                value: exerciciosConsecutivos / modulo.exerciciosNecessarios,
                label: 'Progresso (${(taxaAcerto * 100).round()}% acerto)',
                color:
                    isCompleto ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ModernButton(
                text: isCompleto ? 'Revisar' : 'Começar',
                onPressed: () => _iniciarModulo(modulo),
                isPrimary: !isCompleto,
                icon: isCompleto
                    ? Icons.refresh_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.darkTextSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bloqueado',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      children: [
        ResponsiveHeader(
          title: 'Módulos BNCC',
          subtitle: _progresso != null
              ? 'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}'
              : 'Carregando...',
          showBackButton: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _mostrarRecomendacoes,
                icon: const Icon(Icons.lightbulb_outline_rounded),
                tooltip: 'Recomendações',
              ),
              IconButton(
                onPressed: _mostrarRelatorioDetalhado,
                icon: const Icon(Icons.analytics_outlined),
                tooltip: 'Relatório Detalhado',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressoGeral(bool isTablet) {
    if (_progresso == null) return const SizedBox.shrink();

    final progressoGeral = _progresso!.calcularProgressoGeral();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: ModernCard(
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.primaryColor,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    'Progresso Geral',
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ),
                Text(
                  '${(progressoGeral * 100).round()}%',
                  style: AppTheme.headingLarge.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            ModernProgressIndicator(
              value: progressoGeral,
              label: 'Módulos Completos',
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  '${_progresso!.totalExerciciosCorretos}',
                  'Exercícios Corretos',
                  Icons.check_circle_outline,
                  isTablet,
                ),
                _buildStatChip(
                  '${_progresso!.pontosPorUnidade.values.fold(0, (a, b) => a + b)}',
                  'Pontos Totais',
                  Icons.stars_rounded,
                  isTablet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
      String value, String label, IconData icon, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: isTablet ? 16 : 14,
          ),
          SizedBox(width: isTablet ? 6 : 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.darkTextSecondaryColor,
                  fontSize: isTablet ? 10 : 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnidadesSeletor(bool isTablet) {
    final unidades = ModulosBNCCData.obterUnidadesTematicas();

    return Container(
      height: isTablet ? 60 : 50,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 12 : 8,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: unidades.length,
        itemBuilder: (context, index) {
          final unidade = unidades[index];
          final isSelected = unidade == _unidadeSelecionada;
          final progresso =
              _progresso?.calcularProgressoPorUnidade(unidade) ?? 0.0;

          return Container(
            margin: EdgeInsets.only(right: isTablet ? 12 : 8),
            child: Material(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.darkSurfaceColor,
              child: InkWell(
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                onTap: () => setState(() => _unidadeSelecionada = unidade),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 12 : 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        unidade,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.darkTextPrimaryColor,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Container(
                        width: isTablet ? 40 : 30,
                        height: isTablet ? 4 : 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progresso,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModulosGrid(bool isTablet, bool isDesktop) {
    final modulos = ModulosBNCCData.obterModulosPorUnidade(_unidadeSelecionada);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      child: isDesktop
          ? IntrinsicHeight(
              child: Wrap(
                spacing: isTablet ? 20 : 16,
                runSpacing: isTablet ? 20 : 16,
                children: modulos.map((modulo) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width -
                            (isTablet ? 88 : 72)) /
                        2,
                    child: IntrinsicHeight(
                      child: _buildModuloCard(modulo, isTablet),
                    ),
                  );
                }).toList(),
              ),
            )
          : ListView.builder(
              itemCount: modulos.length,
              itemBuilder: (context, index) {
                final modulo = modulos[index];
                return Container(
                  margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                  child: _buildModuloCard(modulo, isTablet),
                );
              },
            ),
    );
  }

  Widget _buildModuloCard(ModuloBNCC modulo, bool isTablet) {
    if (_progresso == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isCompleto = _progresso!.modulosCompletos[modulo.unidadeTematica]
            ?[modulo.anoEscolar] ??
        false;
    final isDesbloqueado = debugUnlockAllModules ||
        _progresso!
            .moduloDesbloqueado(modulo.unidadeTematica, modulo.anoEscolar);
    final chaveModulo = '${modulo.unidadeTematica}_${modulo.anoEscolar}';
    final exerciciosConsecutivos =
        _progresso!.exerciciosCorretosConsecutivos[chaveModulo] ?? 0;
    final taxaAcerto = _progresso!.taxaAcertoPorModulo[chaveModulo] ?? 0.0;

    return ModernCard(
      hasGlow: isDesbloqueado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do card
          Row(
            children: [
              Container(
                width: isTablet ? 40 : 32,
                height: isTablet ? 40 : 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleto
                        ? [
                            AppTheme.successColor,
                            AppTheme.successColor.withValues(alpha: 0.7)
                          ]
                        : isDesbloqueado
                            ? [
                                AppTheme.primaryColor,
                                AppTheme.primaryLightColor
                              ]
                            : [
                                AppTheme.darkBorderColor,
                                AppTheme.darkBorderColor
                              ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleto
                      ? Icons.check_circle_rounded
                      : isDesbloqueado
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_outline_rounded,
                  color: isDesbloqueado
                      ? Colors.white
                      : AppTheme.darkTextSecondaryColor,
                  size: isTablet ? 20 : 16,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.anoEscolar,
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: isTablet ? 16 : 14,
                        color: isDesbloqueado
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    if (isCompleto || exerciciosConsecutivos > 0) ...[
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        isCompleto
                            ? 'Completo!'
                            : '$exerciciosConsecutivos/${modulo.exerciciosNecessarios} exercícios',
                        style: TextStyle(
                          color: isCompleto
                              ? AppTheme.successColor
                              : AppTheme.darkTextSecondaryColor,
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 12 : 10),

          // Conteúdo que se expande no desktop/tablet com Wrap
          isDesktop
              ? Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        modulo.titulo,
                        style: AppTheme.headingMedium.copyWith(
                          fontSize: isTablet ? 16 : 14,
                          color: isDesbloqueado
                              ? AppTheme.darkTextPrimaryColor
                              : AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Expanded(
                        child: Text(
                          modulo.descricao,
                          style: AppTheme.bodySmall.copyWith(
                            fontSize: isTablet ? 12 : 11,
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.titulo,
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: isTablet ? 16 : 14,
                        color: isDesbloqueado
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      modulo.descricao,
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: isTablet ? 12 : 11,
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

          SizedBox(height: isTablet ? 12 : 10),

          // Progresso e botão
          if (isDesbloqueado) ...[
            if (taxaAcerto > 0) ...[
              ModernProgressIndicator(
                value: exerciciosConsecutivos / modulo.exerciciosNecessarios,
                label: 'Progresso (${(taxaAcerto * 100).round()}% acerto)',
                color:
                    isCompleto ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              SizedBox(height: isTablet ? 12 : 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ModernButton(
                text: isCompleto ? 'Revisar' : 'Começar',
                onPressed: () => _iniciarModulo(modulo),
                isPrimary: !isCompleto,
                icon: isCompleto
                    ? Icons.refresh_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 12 : 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.darkTextSecondaryColor,
                    size: isTablet ? 16 : 14,
                  ),
                  SizedBox(width: isTablet ? 8 : 6),
                  Text(
                    'Bloqueado',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _iniciarModulo(ModuloBNCC modulo) {
    // Navega diretamente para o tutor de IA com sidebar
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatWithSidebarScreen(
          modulo: modulo,
          progresso: _progresso!,
          isOfflineMode: widget.isOfflineMode,
        ),
      ),
    ).then((_) => _carregarProgresso()); // Recarrega progresso ao voltar
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
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _unidadeSelecionada = rec['unidade']!;
                            });
                          },
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
}
