import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../models/progresso_usuario.dart';
import '../models/modulo_bncc.dart';
import '../services/progresso_service.dart';
import 'chat_screen.dart';

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
                  child: _buildMobileLayout(),
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

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        _buildUnidadesSeletor(),
        Expanded(
          child: _buildModulosGrid(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
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
    );
  }

  Widget _buildMobileTabletLayout() {
    return Column(
      children: [
        _buildHeader(),
        _buildUnidadesSeletor(),
        Expanded(
          child: _buildModulosGrid(),
        ),
      ],
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Módulos de Estudos',
                style: AppTheme.headingLarge.copyWith(
                  fontSize: screenWidth > 1400 ? 20 : 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (_progresso != null)
                Text(
                  'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: screenWidth > 1400 ? 14 : 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
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

    // Usa toda a largura disponível para desktop
    const spacing = 16.0;
    final availableWidth =
        screenWidth - (spacing * 2); // Remove apenas espaçamento lateral

    // Calcula quantos cards cabem baseado na largura disponível
    // Permite mais flexibilidade para ocupar todo o espaço
    const minCardWidth =
        200.0; // Largura mínima reduzida para permitir mais cards
    final maxColumns = (availableWidth / (minCardWidth + spacing)).floor();
    final numColumns =
        maxColumns.clamp(1, 6); // Permite até 6 colunas para ocupar mais espaço

    // Calcula a largura real dos cards dividindo igualmente o espaço disponível
    final totalSpacing = spacing * (numColumns - 1);
    final cardWidth = (availableWidth - totalSpacing) / numColumns;

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

  Widget _buildHeader() {
    return Column(
      children: [
        ResponsiveHeader(
          title: 'Módulos de Estudos',
          subtitle: _progresso != null
              ? 'Nível: ${_progresso!.nivelUsuario.nome} ${_progresso!.nivelUsuario.emoji}'
              : 'Carregando...',
          showBackButton: true,
        ),
      ],
    );
  }

  Widget _buildUnidadesSeletor() {
    final unidades = ModulosBNCCData.obterUnidadesTematicas();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
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
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.darkSurfaceColor,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _unidadeSelecionada = unidade),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 30,
                        height: 3,
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

  Widget _buildModulosGrid() {
    final modulos = ModulosBNCCData.obterModulosPorUnidade(_unidadeSelecionada);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: ListView.builder(
        itemCount: modulos.length,
        itemBuilder: (context, index) {
          final modulo = modulos[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildModuloCard(modulo),
          );
        },
      ),
    );
  }

  Widget _buildModuloCard(ModuloBNCC modulo) {
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
          // Header do card
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modulo.anoEscolar,
                      style: AppTheme.headingSmall.copyWith(
                        fontSize: 14,
                        color: isDesbloqueado
                            ? AppTheme.darkTextPrimaryColor
                            : AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    if (isCompleto || exerciciosConsecutivos > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        isCompleto
                            ? 'Completo!'
                            : '$exerciciosConsecutivos/${modulo.exerciciosNecessarios} exercícios',
                        style: TextStyle(
                          color: isCompleto
                              ? AppTheme.successColor
                              : AppTheme.darkTextSecondaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Conteúdo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                modulo.titulo,
                style: AppTheme.headingMedium.copyWith(
                  fontSize: 14,
                  color: isDesbloqueado
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.darkTextSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                modulo.descricao,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppTheme.darkTextSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progresso e botão
          if (isDesbloqueado) ...[
            if (taxaAcerto > 0) ...[
              ModernProgressIndicator(
                value: exerciciosConsecutivos / modulo.exerciciosNecessarios,
                label: 'Progresso (${(taxaAcerto * 100).round()}% acerto)',
                color:
                    isCompleto ? AppTheme.successColor : AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
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
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.darkTextSecondaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bloqueado',
                    style: TextStyle(
                      color: AppTheme.darkTextSecondaryColor,
                      fontSize: 12,
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
        builder: (context) => ChatScreen(
          mode: ChatMode.module,
          modulo: modulo,
          progresso: _progresso!,
          isOfflineMode: widget.isOfflineMode,
        ),
      ),
    ).then((_) => _carregarProgresso()); // Recarrega progresso ao voltar
  }
}
