import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/ia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'quiz_complete_a_frase_screen.dart';
import 'configuracao_screen.dart';
import 'quiz_multipla_escolha_screen.dart';
import 'quiz_verdadeiro_falso_screen.dart';
import 'quiz_alternado_screen.dart';
import 'ajuda_screen.dart';
import 'modulos_screen.dart';
import 'relatorios_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  final GeminiService geminiService = GeminiService();
  bool _isLoading = true;
  String? _error;
  bool _isOfflineMode = false;
  List<Map<String, dynamic>> _exerciciosOffline = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _carregarExerciciosOffline();
    await _checkAIServices();
    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _carregarExerciciosOffline() async {
    // Exercícios pré-definidos para modo offline com vários tipos
    _exerciciosOffline = [
      // Quiz Múltipla Escolha - Frações
      {
        'tipo': 'multipla_escolha',
        'topico': 'Frações',
        'nivel': 'fácil',
        'pergunta': 'Quanto é 1/2 + 1/4?',
        'resposta_correta': '3/4',
        'explicacao':
            'Para somar frações com denominadores diferentes, primeiro encontramos o mínimo múltiplo comum (MMC) dos denominadores. MMC de 2 e 4 é 4. Convertemos 1/2 para 2/4 e somamos: 2/4 + 1/4 = 3/4.',
        'opcoes': ['3/4', '1/2', '1/4', '2/4']
      },
      // Quiz Verdadeiro/Falso - Geometria
      {
        'tipo': 'verdadeiro_falso',
        'topico': 'Geometria',
        'nivel': 'fácil',
        'pergunta': 'Um quadrado tem quatro lados iguais.',
        'resposta_correta': 'verdadeiro',
        'explicacao':
            'Por definição, um quadrado é um polígono com quatro lados de comprimento igual e quatro ângulos retos.',
        'opcoes': ['verdadeiro', 'falso']
      },
      // Quiz Completar Frase - Porcentagem
      {
        'tipo': 'completar_frase',
        'topico': 'Porcentagem',
        'nivel': 'médio',
        'pergunta': '20% de 150 é igual a _____.',
        'resposta_correta': '30',
        'explicacao':
            'Para calcular 20% de 150: (20/100) × 150 = 0,2 × 150 = 30.',
        'opcoes': []
      },
      // Adicionar mais exercícios...
    ];
  }

  Future<void> _checkAIServices() async {
    try {
      final geminiAvailable = await geminiService.isServiceAvailable();
      final ollamaService = OllamaService();
      final ollamaAvailable = await ollamaService.isServiceAvailable();

      setState(() {
        _isOfflineMode = !geminiAvailable && !ollamaAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isOfflineMode = true;
        _isLoading = false;
        _error = 'Erro ao verificar serviços de IA: $e';
      });
    }
  }

  void _startQuizCompleteFrase() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuizCompleteAFraseScreen(),
      ),
    );
  }

  void _goToConfig() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const ConfiguracaoScreen(),
          ),
        )
        .then((_) => _checkAIServices());
  }

  void _goToModulos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ModulosScreen(
          isOfflineMode: _isOfflineMode,
          exerciciosOffline: _exerciciosOffline,
        ),
      ),
    );
  }

  void _startQuiz() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizMultiplaEscolhaScreen(
          isOfflineMode: _isOfflineMode,
          topico: 'Matemática Geral',
          dificuldade: 'médio',
        ),
      ),
    );
  }

  void _startQuizVerdadeiroFalso() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizVerdadeiroFalsoScreen(
          isOfflineMode: _isOfflineMode,
          topico: 'Matemática Geral',
          dificuldade: 'médio',
        ),
      ),
    );
  }

  void _startQuizAlternado() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizAlternadoScreen(
          isOfflineMode: _isOfflineMode,
          topico: 'números e operações',
          dificuldade: 'médio',
        ),
      ),
    );
  }

  void _goToAjuda() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AjudaScreen(),
      ),
    );
  }

  void _goToRelatorios() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RelatoriosScreen(),
      ),
    );
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
          child: _isLoading
              ? _buildLoadingScreen()
              : _buildMainContent(isTablet, isDesktop),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: ModernCard(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Inicializando MathQuest...',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.darkTextPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando sua experiência de aprendizado',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isTablet, bool isDesktop) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: isDesktop
                ? _buildDesktopLayout()
                : _buildMobileTabletLayout(isTablet),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
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
      child: Row(
        children: [
          // Menu lateral esquerdo (estilo Visual Novel)
          SizedBox(
            width: 350,
            child: _buildLeftMenu(),
          ),
          // Linha divisória sutil
          Container(
            width: 1,
            color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
          ),
          // Informações à direita
          Expanded(
            child: _buildRightInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(bool isTablet) {
    return Stack(
      children: [
        // Fundo com decorações matemáticas (igual ao desktop)
        Positioned.fill(
          child: _buildMathematicalDecorations(),
        ),
        // Conteúdo principal
        SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 20,
            vertical: isTablet ? 40 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo matemática (igual ao desktop)
              _buildMathematicalLogo(),

              SizedBox(height: isTablet ? 40 : 30),

              // Seção de boas-vindas (igual ao desktop)
              _buildWelcomeSection(),

              SizedBox(height: isTablet ? 40 : 30),

              // Status do sistema
              _buildStatusSection(isTablet),
              
              SizedBox(height: isTablet ? 40 : 30),

              // Botões de ação principais
              _buildActionButtons(isTablet),

              // Error display
              if (_error != null) ...[
                SizedBox(height: isTablet ? 30 : 20),
                _buildErrorSection(isTablet),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isTablet) {
    return StatusIndicator(
      text: _isOfflineMode ? 'Modo Offline Ativo' : 'IA Conectada',
      icon: _isOfflineMode ? Icons.wifi_off_rounded : Icons.wifi_rounded,
      color: _isOfflineMode ? AppTheme.warningColor : AppTheme.successColor,
      isActive: true,
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Column(
      children: [
        ModernButton(
          text: '🎯 Módulos BNCC',
          icon: Icons.school_rounded,
          onPressed: _goToModulos,
          isPrimary: true,
          isFullWidth: true,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        ModernButton(
          text: _isOfflineMode
              ? 'Quiz Complete a Frase'
              : 'Quiz Complete a Frase',
          icon:
              _isOfflineMode ? Icons.book_rounded : Icons.rocket_launch_rounded,
          onPressed: _startQuizCompleteFrase,
          isPrimary: true,
          isFullWidth: true,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        ModernButton(
          text: _isOfflineMode
              ? 'Quiz Múltipla Escolha'
              : 'Quiz Múltipla Escolha',
          icon: Icons.quiz_rounded,
          onPressed: _startQuiz,
          isPrimary: true,
          isFullWidth: true,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        ModernButton(
          text: _isOfflineMode
              ? 'Quiz Verdadeiro/Falso'
              : 'Quiz Verdadeiro/Falso',
          icon: Icons.check_box_rounded,
          onPressed: _startQuizVerdadeiroFalso,
          isPrimary: true,
          isFullWidth: true,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        ModernButton(
          text: '🎲 Quiz Alternado (Todos os Tipos)',
          icon: Icons.shuffle_rounded,
          onPressed: _startQuizAlternado,
          isPrimary: true,
          isFullWidth: true,
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Row(
          children: [
            Expanded(
              child: ModernButton(
                text: 'Relatórios',
                icon: Icons.analytics,
                onPressed: _goToRelatorios,
                isPrimary: false,
                isFullWidth: true,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        ModernButton(
          text: 'Configurações',
          icon: Icons.settings_rounded,
          onPressed: _goToConfig,
          isPrimary: false,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildErrorSection(bool isTablet) {
    return ModernCard(
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              _error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menu lateral esquerdo estilo Visual Novel
  Widget _buildLeftMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card unificado com título e boas-vindas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.functions_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MathQuest',
                      style: AppTheme.displaySmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.waving_hand_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Bem-vindo!',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isOfflineMode
                      ? 'Modo offline ativo\nExercícios básicos disponíveis'
                      : 'Sistema de IA conectado\nExperiência completa disponível',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Menu principal estilo Visual Novel
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVisualNovelButton(
                    title: 'Iniciar',
                    onPressed: _goToModulos,
                  ),

                  const SizedBox(height: 20),
                  _buildVisualNovelButton(
                    title: 'Modo Quiz',
                    onPressed: _startQuizAlternado,
                  ),

                  const SizedBox(height: 20),

                  _buildVisualNovelButton(
                    title: 'Configurações',
                    onPressed: _goToConfig,
                  ),

                  const SizedBox(height: 20),

                  _buildVisualNovelButton(
                    title: 'Relatórios',
                    onPressed: _goToRelatorios,
                  ),

                  const SizedBox(height: 20),

                  _buildVisualNovelButton(
                    title: 'Ajuda',
                    onPressed: _goToAjuda,
                  ),

                  // Espaço extra para garantir que o último botão não fique colado no final
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Status indicator na parte inferior
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 20),
            child: Row(
              children: [
                Icon(
                  _isOfflineMode ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  color: _isOfflineMode
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _isOfflineMode ? 'Offline' : 'Online',
                  style: AppTheme.bodySmall.copyWith(
                    color: _isOfflineMode
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Botão estilo Visual Novel (simples e direto como DDLC)
  Widget _buildVisualNovelButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 280,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Text(
              title,
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkTextPrimaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Painel de informações à direita
  Widget _buildRightInfo() {
    return Stack(
      children: [
        // Fundo com decorações matemáticas
        Positioned.fill(
          child: _buildMathematicalDecorations(),
        ),
        // Conteúdo principal
        Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo principal com elementos matemáticos
              _buildMathematicalLogo(),
            ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMathematicalLogo() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Logo central
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.functions_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),

          // Elementos matemáticos orbitando
          ..._buildOrbitingMathElements(),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitingMathElements() {
    final mathElements = [
      {
        'text': 'π',
        'angle': 0.0,
        'radius': 100.0,
        'color': AppTheme.accentColor
      },
      {
        'text': '∑',
        'angle': 0.785,
        'radius': 120.0,
        'color': AppTheme.successColor
      },
      {
        'text': '√',
        'angle': 1.57,
        'radius': 110.0,
        'color': AppTheme.warningColor
      },
      {
        'text': '∞',
        'angle': 2.356,
        'radius': 105.0,
        'color': AppTheme.infoColor
      },
      {
        'text': '∫',
        'angle': 3.14,
        'radius': 115.0,
        'color': AppTheme.secondaryColor
      },
      {
        'text': 'α',
        'angle': 3.926,
        'radius': 95.0,
        'color': AppTheme.primaryColor
      },
      {
        'text': 'Δ',
        'angle': 4.712,
        'radius': 125.0,
        'color': AppTheme.errorColor
      },
      {
        'text': '≈',
        'angle': 5.497,
        'radius': 100.0,
        'color': AppTheme.accentColor
      },
    ];

    return mathElements.map((element) {
      final x = (element['radius']! as double) *
          math.cos(element['angle']! as double);
      final y = (element['radius']! as double) *
          math.sin(element['angle']! as double);

      return Positioned(
        left: 150 + x - 15,
        top: 150 + y - 15,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (element['color']! as Color).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: element['color']! as Color,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              element['text']! as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: element['color']! as Color,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: 32,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Bem-vindo ao MathQuest!',
            style: AppTheme.headingLarge.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isOfflineMode
                ? 'Modo offline ativo\nExercícios básicos disponíveis'
                : 'Sistema de IA conectado\nExperiência completa disponível',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMathematicalDecorations() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.03),
            AppTheme.secondaryColor.withValues(alpha: 0.02),
            AppTheme.accentColor.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Fórmulas matemáticas decorativas espalhadas
          Positioned(
            left: 60,
            top: 80,
            child: _buildMathFormula('E = mc²', AppTheme.primaryColor),
          ),
          Positioned(
            right: 80,
            top: 120,
            child: _buildMathFormula('a² + b² = c²', AppTheme.secondaryColor),
          ),
          Positioned(
            left: 100,
            top: 200,
            child: _buildMathFormula('∫f(x)dx', AppTheme.infoColor),
          ),
          Positioned(
            right: 60,
            top: 260,
            child: _buildMathFormula('lim→∞', AppTheme.accentColor),
          ),
          Positioned(
            left: 80,
            top: 320,
            child: _buildMathFormula('Σx²', AppTheme.warningColor),
          ),
          Positioned(
            right: 120,
            top: 380,
            child: _buildMathFormula('√(a+b)', AppTheme.successColor),
          ),
          Positioned(
            left: 140,
            top: 450,
            child: _buildMathFormula('∂f/∂x', AppTheme.primaryColor),
          ),
          Positioned(
            right: 100,
            top: 500,
            child: _buildMathFormula('φ = (1+√5)/2', AppTheme.secondaryColor),
          ),
          Positioned(
            left: 70,
            top: 560,
            child: _buildMathFormula('∞', AppTheme.infoColor),
          ),
          Positioned(
            right: 140,
            top: 600,
            child: _buildMathFormula('π ≈ 3.14', AppTheme.accentColor),
          ),

          // Ícones matemáticos grandes e sutis
          Positioned(
            right: 200,
            top: 150,
            child: Icon(
              Icons.calculate_rounded,
              size: 60,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: 150,
            top: 350,
            child: Icon(
              Icons.functions_rounded,
              size: 50,
              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            right: 150,
            top: 450,
            child: Icon(
              Icons.show_chart_rounded,
              size: 45,
              color: AppTheme.accentColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathFormula(String formula, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        formula,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
