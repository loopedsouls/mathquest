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

              // Logo matemática unificada com boas-vindas
              _buildUnifiedLogoWelcome(isTablet),

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
        Center(
          child: _buildMathematicalLogo(),
        ),
      ],
    );
  }

  Widget _buildUnifiedLogoWelcome(bool isTablet) {
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
          // Logo compacta
          Container(
            width: isTablet ? 100 : 80,
            height: isTablet ? 100 : 80,
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
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.functions_rounded,
              size: isTablet ? 45 : 35,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          
          // Título e boas-vindas integrados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.waving_hand_rounded,
                size: isTablet ? 28 : 24,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'MathQuest',
                style: (isTablet ? AppTheme.headingLarge : AppTheme.headingMedium).copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            _isOfflineMode
                ? 'Modo offline ativo • Exercícios básicos disponíveis'
                : 'Sistema de IA conectado • Experiência completa disponível',
            style: (isTablet ? AppTheme.bodyMedium : AppTheme.bodySmall).copyWith(
              color: AppTheme.darkTextSecondaryColor,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMathematicalLogo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final logoSize = (screenWidth * 0.25).clamp(200.0, 350.0);
        final centralLogoSize = logoSize * 0.4;
        final iconSize = centralLogoSize * 0.5;
        
        return Container(
          width: logoSize,
          height: logoSize,
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
                width: centralLogoSize,
                height: centralLogoSize,
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
                child: Icon(
                  Icons.functions_rounded,
                  size: iconSize,
                  color: Colors.white,
                ),
              ),

              // Elementos matemáticos orbitando
              ..._buildOrbitingMathElements(logoSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitingMathElements(double logoSize) {
    final scaleFactor = logoSize / 300.0; // 300 era o tamanho original
    final center = logoSize / 2;
    final elementSize = (30 * scaleFactor).clamp(20.0, 40.0);
    final fontSize = (16 * scaleFactor).clamp(12.0, 20.0);
    
    final mathElements = [
      {
        'text': 'π',
        'angle': 0.0,
        'radius': 100.0 * scaleFactor,
        'color': AppTheme.accentColor
      },
      {
        'text': '∑',
        'angle': 0.785,
        'radius': 120.0 * scaleFactor,
        'color': AppTheme.successColor
      },
      {
        'text': '√',
        'angle': 1.57,
        'radius': 110.0 * scaleFactor,
        'color': AppTheme.warningColor
      },
      {
        'text': '∞',
        'angle': 2.356,
        'radius': 105.0 * scaleFactor,
        'color': AppTheme.infoColor
      },
      {
        'text': '∫',
        'angle': 3.14,
        'radius': 115.0 * scaleFactor,
        'color': AppTheme.secondaryColor
      },
      {
        'text': 'α',
        'angle': 3.926,
        'radius': 95.0 * scaleFactor,
        'color': AppTheme.primaryColor
      },
      {
        'text': 'Δ',
        'angle': 4.712,
        'radius': 125.0 * scaleFactor,
        'color': AppTheme.errorColor
      },
      {
        'text': '≈',
        'angle': 5.497,
        'radius': 100.0 * scaleFactor,
        'color': AppTheme.accentColor
      },
    ];

    return mathElements.map((element) {
      final x = (element['radius']! as double) *
          math.cos(element['angle']! as double);
      final y = (element['radius']! as double) *
          math.sin(element['angle']! as double);

      return Positioned(
        left: center + x - (elementSize / 2),
        top: center + y - (elementSize / 2),
        child: Container(
          width: elementSize,
          height: elementSize,
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
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: element['color']! as Color,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMathematicalDecorations() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Calculando posições proporcionais
        final leftMargin = screenWidth * 0.1;
        final rightMargin = screenWidth * 0.1;
        final topOffset = screenHeight * 0.1;
        final spacing = screenHeight * 0.08;
        
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
              // Fórmulas matemáticas decorativas com posições proporcionais
              Positioned(
                left: leftMargin,
                top: topOffset,
                child: _buildMathFormula('E = mc²', AppTheme.primaryColor),
              ),
              Positioned(
                right: rightMargin,
                top: topOffset + spacing * 0.5,
                child: _buildMathFormula('a² + b² = c²', AppTheme.secondaryColor),
              ),
              Positioned(
                left: leftMargin * 1.5,
                top: topOffset + spacing * 1.5,
                child: _buildMathFormula('∫f(x)dx', AppTheme.infoColor),
              ),
              Positioned(
                right: rightMargin * 0.8,
                top: topOffset + spacing * 2.2,
                child: _buildMathFormula('lim→∞', AppTheme.accentColor),
              ),
              Positioned(
                left: leftMargin * 1.2,
                top: topOffset + spacing * 3,
                child: _buildMathFormula('Σx²', AppTheme.warningColor),
              ),
              Positioned(
                right: rightMargin * 1.5,
                top: topOffset + spacing * 3.8,
                child: _buildMathFormula('√(a+b)', AppTheme.successColor),
              ),
              Positioned(
                left: leftMargin * 2,
                top: topOffset + spacing * 4.8,
                child: _buildMathFormula('∂f/∂x', AppTheme.primaryColor),
              ),
              Positioned(
                right: rightMargin * 1.2,
                top: topOffset + spacing * 5.5,
                child: _buildMathFormula('φ = (1+√5)/2', AppTheme.secondaryColor),
              ),
              Positioned(
                left: leftMargin * 0.8,
                top: topOffset + spacing * 6.5,
                child: _buildMathFormula('∞', AppTheme.infoColor),
              ),
              Positioned(
                right: rightMargin * 1.8,
                top: topOffset + spacing * 7,
                child: _buildMathFormula('π ≈ 3.14', AppTheme.accentColor),
              ),

              // Ícones matemáticos grandes e sutis com posições proporcionais
              Positioned(
                right: screenWidth * 0.25,
                top: screenHeight * 0.2,
                child: Icon(
                  Icons.calculate_rounded,
                  size: screenWidth * 0.08,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                left: screenWidth * 0.2,
                top: screenHeight * 0.45,
                child: Icon(
                  Icons.functions_rounded,
                  size: screenWidth * 0.06,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                ),
              ),
              Positioned(
                right: screenWidth * 0.2,
                top: screenHeight * 0.6,
                child: Icon(
                  Icons.show_chart_rounded,
                  size: screenWidth * 0.05,
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        );
      },
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
