import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ia_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'configuracao_screen.dart';
import 'quiz_alternado_screen.dart';
import 'ajuda_screen.dart';
import 'modulos_screen.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';

class NavigationItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  NavigationItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

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
  bool _aiAvailable = false;

  // Navegação
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.assessment_rounded,
      label: 'Progresso',
    ),
    NavigationItem(
      icon: Icons.play_arrow_rounded,
      label: 'Módulos',
    ),
    NavigationItem(
      icon: Icons.quiz_rounded,
      label: 'Quiz',
    ),
    NavigationItem(
      icon: Icons.chat_rounded,
      label: 'Chat',
    ),
    NavigationItem(
      icon: Icons.settings_rounded,
      label: 'Config',
    ),
  ];

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
      setState(() {
        _isLoading = false;
      });
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
          _aiAvailable = true;
        } else if (isConfigured && !isAvailable) {
          _aiAvailable = false;
        } else {
          _aiAvailable = false;
        }
      } else {
        // Ollama
        final ollamaService = OllamaService(defaultModel: modeloOllama);
        isAvailable = await ollamaService.isServiceAvailable();

        if (isAvailable) {
          _aiAvailable = true;
        } else {
          _aiAvailable = false;
        }
      }

      setState(() {
        _isOfflineMode = !_aiAvailable;
      });
    } catch (e) {
      setState(() {
        _isOfflineMode = true;
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
        builder: (context) => const DashboardScreen(),
      ),
    );
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getCurrentScreen(bool isTablet, bool isDesktop) {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return ModulosScreen(
          isOfflineMode: _isOfflineMode,
          exerciciosOffline: _exerciciosOffline,
        );
      case 2:
        return QuizAlternadoScreen(
          isOfflineMode: _isOfflineMode,
          topico: 'números e operações',
          dificuldade: 'médio',
        );
      case 3:
        return const ChatScreen(mode: ChatMode.general);
      case 4:
        return const ConfiguracaoScreen();
      default:
        return _buildMainContent(isTablet, isDesktop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      body: isDesktop
          ? Row(
              children: [
                _buildNavigationRail(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingScreen()
                      : _getCurrentScreen(isTablet, isDesktop),
                ),
              ],
            )
          : SafeArea(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _getCurrentScreen(isTablet, isDesktop),
            ),
      bottomNavigationBar:
          !isDesktop && !_isLoading ? _buildBottomNavigationBar() : null,
    );
  }

  Widget _buildNavigationRail() {
    return SizedBox(
      width: 80, // Largura fixa e compacta
      child: NavigationRail(
        backgroundColor: AppTheme.darkSurfaceColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavigationTap,
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(
          color: AppTheme.primaryColor,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: AppTheme.darkTextSecondaryColor,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppTheme.darkTextSecondaryColor,
        ),
        destinations: _navigationItems
            .map((item) => NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon),
                  ),
                  label: Text(item.label),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.darkBorderColor,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavigationTap,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.darkTextSecondaryColor,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Icon(item.icon, size: 24),
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, size: 24),
                  ),
                  label: item.label,
                ))
            .toList(),
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
              child: SizedBox(
                height: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : (isTablet ? 16 : 12),
                    vertical: isDesktop ? 24 : (isTablet ? 20 : 16),
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
                            final buttonHeight = isTablet ? 60.0 : 50.0;
                            final spacing = isTablet ? 16.0 : 12.0;

                            return SizedBox(
                              height: double.infinity,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                              _isOfflineMode
                                  ? Icons.wifi_off_rounded
                                  : Icons.wifi_rounded,
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
                ),
              ),
            ));
      },
    );
  }

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
}
