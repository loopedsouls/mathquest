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
