import 'package:flutter/material.dart';
import '../services/ia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'quiz_complete_a_frase_screen.dart';
import 'configuracao_screen.dart';
import 'quiz_multipla_escolha_screen.dart';
import 'quiz_verdadeiro_falso_screen.dart';

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

  void _startTutoria() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizCompleteAFraseScreen(
          isOfflineMode: _isOfflineMode,
          exerciciosOffline: _exerciciosOffline,
        ),
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
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        children: [
          // Menu lateral esquerdo (estilo Ren'Py)
          Expanded(
            flex: 2,
            child: _buildLeftMenu(),
          ),
          const SizedBox(width: 40),
          // Informações à direita
          Expanded(
            flex: 3,
            child: _buildRightInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabletLayout(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 20,
        vertical: isTablet ? 40 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header principal
          _buildHeroSection(isTablet, false),
          SizedBox(height: isTablet ? 40 : 30),

          // Status do sistema
          _buildStatusSection(isTablet),
          SizedBox(height: isTablet ? 40 : 30),

          // Botões de ação principais
          _buildActionButtons(isTablet),
          SizedBox(height: isTablet ? 40 : 30),

          // Seção de recursos
          _buildFeaturesSection(isTablet),

          // Error display
          if (_error != null) ...[
            SizedBox(height: isTablet ? 30 : 20),
            _buildErrorSection(isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isTablet, bool isDesktop) {
    return ModernCard(
      hasGlow: true,
      child: Column(
        children: [
          Container(
            width: isDesktop ? 120 : (isTablet ? 100 : 80),
            height: isDesktop ? 120 : (isTablet ? 100 : 80),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOfflineMode
                    ? [
                        AppTheme.warningColor,
                        AppTheme.warningColor.withValues(alpha: 0.7)
                      ]
                    : [AppTheme.primaryColor, AppTheme.primaryLightColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isOfflineMode
                          ? AppTheme.warningColor
                          : AppTheme.primaryColor)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _isOfflineMode
                  ? Icons.wifi_off_rounded
                  : Icons.psychology_rounded,
              size: isDesktop ? 60 : (isTablet ? 50 : 40),
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            'MathQuest',
            style: (isDesktop ? AppTheme.displayMedium : AppTheme.headingLarge)
                .copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            _isOfflineMode
                ? 'Modo Offline Ativado'
                : 'Tutoria Inteligente de Matemática',
            style: (isTablet ? AppTheme.headingSmall : AppTheme.bodyLarge)
                .copyWith(
              color: _isOfflineMode
                  ? AppTheme.warningColor
                  : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            _isOfflineMode
                ? 'Aprenda matemática mesmo sem conexão! Temos exercícios pré-carregados para você.'
                : 'Desafie-se e melhore suas habilidades matemáticas com IA generativa adaptativa.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkTextSecondaryColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
          text: _isOfflineMode
              ? 'Quiz Complete a Frase'
              : 'Quiz Complete a Frase',
          icon:
              _isOfflineMode ? Icons.book_rounded : Icons.rocket_launch_rounded,
          onPressed: _startTutoria,
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
        SizedBox(height: isTablet ? 20 : 16),
        ModernButton(
          text: 'Configurações Avançadas',
          icon: Icons.settings_rounded,
          onPressed: _goToConfig,
          isPrimary: false,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(bool isTablet) {
    final features = [
      _FeatureItem(
        icon: Icons.trending_up_rounded,
        title: 'Exercícios Adaptativos',
        description: 'Dificuldade ajustada ao seu progresso',
        color: AppTheme.primaryColor,
      ),
      _FeatureItem(
        icon: Icons.psychology_rounded,
        title: 'Explicações com IA',
        description: 'Explicações detalhadas passo-a-passo',
        color: AppTheme.secondaryColor,
      ),
      _FeatureItem(
        icon: Icons.analytics_rounded,
        title: 'Progresso Detalhado',
        description: 'Acompanhe seu desempenho em tempo real',
        color: AppTheme.infoColor,
      ),
      _FeatureItem(
        icon: Icons.offline_bolt_rounded,
        title: 'Modo Offline',
        description: 'Aprenda sem conexão com a internet',
        color: AppTheme.warningColor,
      ),
      _FeatureItem(
        icon: Icons.quiz_rounded,
        title: 'Múltiplos Formatos',
        description: 'Múltipla escolha, V/F e completar frase',
        color: AppTheme.accentColor,
      ),
      _FeatureItem(
        icon: Icons.gamepad_rounded,
        title: 'Experiência Gamificada',
        description: 'Interface intuitiva e envolvente',
        color: AppTheme.highlightColor,
      ),
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recursos do MathQuest',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              childAspectRatio: isTablet ? 1.2 : 1.1,
              crossAxisSpacing: isTablet ? 20 : 16,
              mainAxisSpacing: isTablet ? 20 : 16,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) =>
                _buildFeatureCard(features[index], isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: feature.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        border: Border.all(
          color: feature.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              color: feature.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              feature.icon,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            feature.title,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            feature.description,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.darkTextSecondaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  // Menu lateral esquerdo estilo Ren'Py
  Widget _buildLeftMenu() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkSurfaceColor,
            AppTheme.darkCardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppTheme.strongShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu principal estilo Ren'Py
          _buildMenuButton(
            icon: Icons.rocket_launch_rounded,
            title: _isOfflineMode
                ? 'Iniciar Tutoria Offline'
                : 'Iniciar Tutoria IA',
            subtitle: _isOfflineMode
                ? 'Exercícios pré-definidos'
                : 'Com inteligência artificial',
            onPressed: _startTutoria,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          _buildMenuButton(
            icon: Icons.quiz_rounded,
            title: _isOfflineMode
                ? 'Quiz Múltipla Escolha'
                : 'Quiz Múltipla Escolha',
            subtitle: 'Múltipla escolha interativa',
            onPressed: _startQuiz,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          _buildMenuButton(
            icon: Icons.check_box_rounded,
            title: 'Quiz Verdadeiro/Falso',
            subtitle: 'Formato sim ou não',
            onPressed: _startQuizVerdadeiroFalso,
            isPrimary: true,
          ),

          const SizedBox(height: 20),

          _buildMenuButton(
            icon: Icons.settings_rounded,
            title: 'Configurações',
            subtitle: 'Personalizar experiência',
            onPressed: _goToConfig,
            isPrimary: false,
          ),

          const SizedBox(height: 20),

          _buildMenuButton(
            icon: Icons.help_outline_rounded,
            title: 'Ajuda & Tutorial',
            subtitle: 'Como usar o sistema',
            onPressed: () {
              // TODO: Implementar tela de ajuda
            },
            isPrimary: false,
          ),

          const Spacer(),
        ],
      ),
    );
  }

  // Botão de menu estilo Ren'Py
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                        AppTheme.primaryDarkColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isPrimary ? null : AppTheme.darkCardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPrimary
                    ? AppTheme.primaryColor.withValues(alpha: 0.4)
                    : AppTheme.darkBorderColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? AppTheme.primaryColor.withValues(alpha: 0.2)
                        : AppTheme.darkTextHintColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary
                        ? AppTheme.primaryColor
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
                        title,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPrimary
                              ? AppTheme.primaryColor
                              : AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isPrimary
                      ? AppTheme.primaryColor.withValues(alpha: 0.7)
                      : AppTheme.darkTextHintColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Painel de informações à direita
  Widget _buildRightInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de boas-vindas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppTheme.modernGradient2,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.mediumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo ao MathQuest!',
                style: AppTheme.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isOfflineMode
                    ? 'Modo offline ativo. Exercícios básicos disponíveis para prática.'
                    : 'Sistema de IA conectado. Experiência completa de aprendizado disponível.',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Recursos principais
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.darkCardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recursos Disponíveis',
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                  ),
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Column(
                    children: [
                      _buildFeatureCardDesktop(
                        Icons.trending_up_rounded,
                        'Exercícios Adaptativos',
                        'Dificuldade ajustada automaticamente',
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCardDesktop(
                        Icons.psychology_rounded,
                        'Explicações com IA',
                        'Passo-a-passo detalhado',
                        AppTheme.secondaryColor,
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCardDesktop(
                        Icons.analytics_rounded,
                        'Progresso Detalhado',
                        'Acompanhe seu desempenho',
                        AppTheme.infoColor,
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureCardDesktop(
                        Icons.quiz_rounded,
                        'Múltiplos Formatos',
                        'Diversos tipos de exercícios',
                        AppTheme.accentColor,
                      ),
                    ],
                  ),
                ),

                // Estatísticas rápidas
                if (!_isOfflineMode) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IA Generativa Ativa',
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                'Exercícios únicos gerados em tempo real',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.darkTextSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Card de recurso para desktop
  Widget _buildFeatureCardDesktop(
      IconData icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.replaceAll('\n', ' '),
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// Card de recurso para desktop
