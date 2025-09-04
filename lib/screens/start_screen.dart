import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'configuracao_screen.dart';
import 'quiz_alternado_screen.dart';
import 'ajuda_screen.dart';
import 'modulos_screen.dart';
import 'relatorios_screen.dart';
import 'chat_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  final GeminiService geminiService = GeminiService();
  bool _isLoading = true;
  bool _isOfflineMode = false;
  List<Map<String, dynamic>> _exerciciosOffline = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Informações sobre a IA configurada
  String _aiName = 'IA';
  bool _aiAvailable = false;

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
      final prefs = await SharedPreferences.getInstance();
      final selectedAI = prefs.getString('selected_ai') ?? 'gemini';
      final apiKey = prefs.getString('gemini_api_key');
      final modeloOllama = prefs.getString('modelo_ollama') ?? 'gemma3:1b';

      bool isConfigured = false;
      bool isAvailable = false;

      if (selectedAI == 'gemini') {
        // Verifica se tem API key configurada
        if (apiKey != null && apiKey.isNotEmpty) {
          final geminiService = GeminiService(apiKey: apiKey);
          isAvailable = await geminiService.isServiceAvailable();
          isConfigured = true;
        }

        if (isConfigured && isAvailable) {
          _aiName = 'Gemini';
          _aiAvailable = true;
        } else if (isConfigured && !isAvailable) {
          _aiName = 'Gemini (Offline)';
          _aiAvailable = false;
        } else {
          _aiName = 'Gemini (Não configurado)';
          _aiAvailable = false;
        }
      } else {
        // Ollama
        final ollamaService = OllamaService(defaultModel: modeloOllama);
        isAvailable = await ollamaService.isServiceAvailable();

        if (isAvailable) {
          _aiName = 'Ollama ($modeloOllama)';
          _aiAvailable = true;
        } else {
          _aiName = 'Ollama (Offline)';
          _aiAvailable = false;
        }
      }

      setState(() {
        _isOfflineMode = !_aiAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isOfflineMode = true;
        _isLoading = false;
        _aiName = 'IA (Erro)';
        _aiAvailable = false;
      });
    }
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

  void _goToAIChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChatScreen(
          mode: ChatMode.sidebar,
          isOfflineMode: false,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isTablet, bool isDesktop) {
    final size = isTablet ? 64.0 : 56.0;
    final iconSize = isTablet ? 28.0 : 24.0;

    return Tooltip(
      message: _aiAvailable
          ? 'Chat com $_aiName'
          : 'IA não disponível - Configure nas configurações',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _aiAvailable
                ? [AppTheme.primaryColor, AppTheme.primaryLightColor]
                : [AppTheme.darkBorderColor, AppTheme.darkBorderColor],
          ),
          shape: BoxShape.circle,
          boxShadow: _aiAvailable
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2),
            onTap: _aiAvailable ? _goToAIChat : null,
            child: SizedBox(
              width: size,
              height: size,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    color: _aiAvailable
                        ? Colors.white
                        : AppTheme.darkTextSecondaryColor,
                    size: iconSize,
                  ),
                  if (isTablet) ...[
                    const SizedBox(height: 2),
                    Text(
                      _aiAvailable ? _aiName : 'IA',
                      style: TextStyle(
                        color: _aiAvailable
                            ? Colors.white
                            : AppTheme.darkTextSecondaryColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
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
      floatingActionButton:
          _isLoading ? null : _buildFloatingActionButton(isTablet, isDesktop),
      floatingActionButtonLocation: isDesktop
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.endFloat,
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
      child: Stack(
        children: [
          // Conteúdo da direita como fundo
          Positioned.fill(
            child: _buildRightInfo(),
          ),

          // Camada de fade para não obfuscar o menu
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.darkBackgroundColor.withValues(alpha: 0.85),
                    AppTheme.darkBackgroundColor.withValues(alpha: 0.75),
                    AppTheme.darkBackgroundColor.withValues(alpha: 0.6),
                    AppTheme.darkBackgroundColor.withValues(alpha: 0.4),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Menu ocupando toda a tela no mobile
          Positioned.fill(
            child: _buildMobileFullMenu(isTablet),
          ),
        ],
      ),
    );
  }

  // Menu para mobile que ocupa toda a tela
  Widget _buildMobileFullMenu(bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 40 : 20,
        vertical: isTablet ? 60 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  AppTheme.primaryColor.withValues(alpha: 0.15),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MathQuest',
                  style: AppTheme.displaySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 32 : 28,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.waving_hand_rounded,
                      color: AppTheme.primaryColor,
                      size: isTablet ? 20 : 18,
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

          // Menu principal estilo Visual Novel - expandido
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonHeight =
                    isTablet ? 60.0 : 50.0; // Altura fixa para melhor controle
                final spacing = isTablet ? 16.0 : 12.0;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMobileVisualNovelButton(
                        title: 'Iniciar',
                        onPressed: _goToModulos,
                        height: buttonHeight,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: spacing),
                      _buildMobileVisualNovelButton(
                        title: 'Modo Quiz',
                        onPressed: _startQuizAlternado,
                        height: buttonHeight,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: spacing),
                      _buildMobileVisualNovelButton(
                        title: 'Configurações',
                        onPressed: _goToConfig,
                        height: buttonHeight,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: spacing),
                      _buildMobileVisualNovelButton(
                        title: 'Relatórios',
                        onPressed: _goToRelatorios,
                        height: buttonHeight,
                        isTablet: isTablet,
                      ),
                      SizedBox(height: spacing),
                      _buildMobileVisualNovelButton(
                        title: 'Ajuda',
                        onPressed: _goToAjuda,
                        height: buttonHeight,
                        isTablet: isTablet,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Status indicator na parte inferior
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

  // Botão estilo Visual Novel para mobile (expandido)
  Widget _buildMobileVisualNovelButton({
    required String title,
    required VoidCallback onPressed,
    required double height,
    required bool isTablet,
  }) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 20 : 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Menu lateral esquerdo estilo Visual Novel
  Widget _buildLeftMenu() {
    return Padding(
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final menuHeight = constraints.maxHeight;
                final buttonHeight =
                    menuHeight * 0.12; // 12% da altura disponível
                final spacing = menuHeight * 0.03; // 3% da altura disponível

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: spacing * 2), // Espaçamento inicial
                    SizedBox(
                      height: buttonHeight,
                      child: _buildVisualNovelButton(
                        title: 'Iniciar',
                        onPressed: _goToModulos,
                      ),
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      height: buttonHeight,
                      child: _buildVisualNovelButton(
                        title: 'Modo Quiz',
                        onPressed: _startQuizAlternado,
                      ),
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      height: buttonHeight,
                      child: _buildVisualNovelButton(
                        title: 'Configurações',
                        onPressed: _goToConfig,
                      ),
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      height: buttonHeight,
                      child: _buildVisualNovelButton(
                        title: 'Relatórios',
                        onPressed: _goToRelatorios,
                      ),
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      height: buttonHeight,
                      child: _buildVisualNovelButton(
                        title: 'Ajuda',
                        onPressed: _goToAjuda,
                      ),
                    ),
                  ],
                );
              },
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
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
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
                child:
                    _buildMathFormula('a² + b² = c²', AppTheme.secondaryColor),
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
                child:
                    _buildMathFormula('φ = (1+√5)/2', AppTheme.secondaryColor),
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
