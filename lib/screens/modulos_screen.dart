import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import '../models/progresso_usuario.dart';
import '../models/modulo_bncc.dart';
import '../services/progresso_service.dart';
import '../screens/chat_screen.dart';

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

  // Estado para controlar visualização
  bool _mostrarChat = false;
  ModuloBNCC? _moduloSelecionado;

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
              : _mostrarChat
                  ? _buildChatView()
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
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unidades.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final unidade = unidades[index];
          final isSelected = unidade == _unidadeSelecionada;
          final progresso =
              _progresso?.calcularProgressoPorUnidade(unidade) ?? 0.0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _unidadeSelecionada = unidade;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLightColor
                        ],
                      )
                    : null,
                color: isSelected ? null : AppTheme.darkSurfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.5)
                      : AppTheme.darkBorderColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getUnidadeIcon(unidade),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        unidade,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.darkTextPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Barra de progresso mais elegante
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.3)
                          : AppTheme.darkBorderColor.withValues(alpha: 0.5),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color:
                              isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getUnidadeIcon(String unidade) {
    switch (unidade) {
      case 'Números':
        return '🔢';
      case 'Álgebra':
        return '📐';
      case 'Geometria':
        return '📏';
      case 'Grandezas e Medidas':
        return '📊';
      case 'Probabilidade e Estatística':
        return '📈';
      default:
        return '📚';
    }
  }

  Widget _buildModulosGrid() {
    final modulos = ModulosBNCCData.obterModulosPorUnidade(_unidadeSelecionada);

    // Agrupa módulos por ano escolar para melhor organização
    final modulosPorAno = <String, List<ModuloBNCC>>{};
    for (final modulo in modulos) {
      modulosPorAno.putIfAbsent(modulo.anoEscolar, () => []).add(modulo);
    }

    // Ordena os anos
    final anosOrdenados = modulosPorAno.keys.toList()
      ..sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
        return numA.compareTo(numB);
      });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: anosOrdenados.length,
        separatorBuilder: (context, index) => const SizedBox(height: 24),
        itemBuilder: (context, index) {
          final ano = anosOrdenados[index];
          final modulosDoAno = modulosPorAno[ano]!;

          return _buildAnoSection(ano, modulosDoAno);
        },
      ),
    );
  }

  Widget _buildAnoSection(String ano, List<ModuloBNCC> modulos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header do ano com progresso geral
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ano.replaceAll('º ano', '°'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$ano - $_unidadeSelecionada',
                      style: AppTheme.headingMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${modulos.length} ${modulos.length == 1 ? 'módulo' : 'módulos'} disponível${modulos.length == 1 ? '' : 'is'}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAnoProgressBadge(modulos),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Módulos do ano
        ...modulos.map((modulo) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildModuloCard(modulo),
            )),
      ],
    );
  }

  Widget _buildAnoProgressBadge(List<ModuloBNCC> modulos) {
    if (_progresso == null) return const SizedBox.shrink();

    int completedCount = 0;
    int unlockedCount = 0;

    for (final modulo in modulos) {
      final isCompleto = _progresso!.modulosCompletos[modulo.unidadeTematica]
              ?[modulo.anoEscolar] ??
          false;
      final isDesbloqueado = debugUnlockAllModules ||
          _progresso!
              .moduloDesbloqueado(modulo.unidadeTematica, modulo.anoEscolar);

      if (isCompleto) completedCount++;
      if (isDesbloqueado) unlockedCount++;
    }

    final progress = modulos.isEmpty ? 0.0 : completedCount / modulos.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: completedCount == modulos.length
            ? AppTheme.successColor
            : unlockedCount > 0
                ? AppTheme.primaryColor
                : AppTheme.darkBorderColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completedCount == modulos.length
                ? Icons.emoji_events_rounded
                : unlockedCount > 0
                    ? Icons.play_circle_outline_rounded
                    : Icons.lock_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '${(progress * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      child: InkWell(
        onTap: isDesbloqueado ? () => _iniciarModulo(modulo) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone de status
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompleto
                      ? Icons.emoji_events_rounded
                      : isDesbloqueado
                          ? Icons.play_circle_filled_rounded
                          : Icons.lock_rounded,
                  color: isDesbloqueado
                      ? Colors.white
                      : AppTheme.darkTextSecondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Conteúdo principal
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modulo.descricao,
                      style: AppTheme.bodySmall.copyWith(
                        fontSize: 12,
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Progresso se houver
                    if (isDesbloqueado &&
                        (_temProgressoAulas(modulo) || taxaAcerto > 0)) ...[
                      const SizedBox(height: 8),
                      if (_temProgressoAulas(modulo))
                        _buildProgressIndicator(
                          _progresso!.calcularProgressoAulas(
                              modulo.unidadeTematica, modulo.anoEscolar),
                          _obterLabelProgressoAulas(modulo),
                          isCompleto,
                        )
                      else
                        _buildProgressIndicator(
                          exerciciosConsecutivos / modulo.exerciciosNecessarios,
                          'Progresso (${(taxaAcerto * 100).round()}% acerto)',
                          isCompleto,
                        ),
                    ],
                  ],
                ),
              ),
              // Status badge
              if (isDesbloqueado) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleto
                        ? AppTheme.successColor.withValues(alpha: 0.2)
                        : AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleto
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isCompleto ? '✓ Completo' : 'Disponível',
                    style: TextStyle(
                      color: isCompleto
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.darkTextSecondaryColor,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double value, String label, bool isCompleto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCompleto
                          ? AppTheme.successColor
                          : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color:
                    isCompleto ? AppTheme.successColor : AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.darkTextSecondaryColor,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    if (_moduloSelecionado == null) {
      return _buildMobileLayout();
    }

    final prompt = _criarPromptParaModulo(_moduloSelecionado!);

    return ChatScreen(
      mode: ChatMode.module,
      modulo: _moduloSelecionado,
      progresso: _progresso,
      isOfflineMode: widget.isOfflineMode,
      promptPreconfigurado: prompt,
      onBackPressed: () {
        setState(() {
          _mostrarChat = false;
          _moduloSelecionado = null;
        });
      },
    );
  }

  void _iniciarModulo(ModuloBNCC modulo) {
    setState(() {
      _moduloSelecionado = modulo;
      _mostrarChat = true;
    });
  }

  String _criarPromptParaModulo(ModuloBNCC modulo) {
    return '''
Você é um tutor de matemática especializado na BNCC, especificamente no módulo "${modulo.titulo}" 
do ${modulo.anoEscolar}, unidade temática "${modulo.unidadeTematica}".

**Descrição do módulo:** ${modulo.descricao}

**Sua função:**
- Seja um tutor paciente e encorajador
- Use linguagem adequada para alunos de ${modulo.anoEscolar}
- Forneça explicações claras e exemplos práticos
- Foque nos conceitos específicos deste módulo
- Ajude o aluno a entender os exercícios e problemas relacionados

**Instruções importantes:**
- Sempre use formatação Markdown para organizar suas respostas
- Use LaTeX para fórmulas matemáticas quando necessário
- Seja específico sobre os conteúdos da BNCC para este módulo
- Incentive o aluno com mensagens positivas
- Adapte a complexidade das explicações ao nível do aluno

**Contexto adicional:**
- Este módulo faz parte da unidade temática: $_unidadeSelecionada
- O aluno está estudando conteúdos de ${modulo.anoEscolar}
- Foque em tornar o aprendizado prazeroso e acessível
''';
  }

  // Métodos auxiliares para progresso de aulas

  bool _temProgressoAulas(ModuloBNCC modulo) {
    final chaveModulo = '${modulo.unidadeTematica}_${modulo.anoEscolar}';
    return (_progresso!.totalAulasPorModulo[chaveModulo] ?? 0) > 0;
  }

  String _obterLabelProgressoAulas(ModuloBNCC modulo) {
    final chaveModulo = '${modulo.unidadeTematica}_${modulo.anoEscolar}';
    final totalAulas = _progresso!.totalAulasPorModulo[chaveModulo] ?? 0;
    final aulasCompletas =
        _progresso!.aulasComplementadasPorModulo[chaveModulo] ?? 0;
    final progresso = (aulasCompletas / totalAulas * 100).round();

    return 'Aulas: $aulasCompletas/$totalAulas ($progresso%)';
  }
}
