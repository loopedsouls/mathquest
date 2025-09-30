import 'package:flutter/material.dart';
// removed unused SharedPreferences import
import '../services/ia_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_components.dart';
import 'configuracao_screen.dart';
import 'quiz_screen.dart';
import 'ajuda_screen.dart';
import 'modulos_screen.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';
import 'perfil_screen.dart';
import 'teste_personagem_3d_screen.dart';
import 'teste_firebase_ai_screen.dart';
import 'login_screen.dart';
import 'dart:io';

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
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isOfflineMode = false;
  List<Map<String, dynamic>> _exerciciosOffline = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Informações sobre a IA configurada
  bool _aiAvailable = false;
  bool _isUserLoggedIn = false;

  // Navegação
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
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
      icon: Icons.person,
      label: 'Meu Perfil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
    _checkAuthState();
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
    // Garantir que a animação seja parada e disposed corretamente
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _carregarExerciciosOffline();
      await _checkAIServices();

      // Verificar se o widget ainda está montado antes de atualizar o estado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      // Em caso de erro, ainda precisamos parar o loading se o widget estiver montado
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfflineMode = true;
          _aiAvailable = false;
        });
        _animationController.forward();
      }
    }
  }

  void _checkAuthState() {
    if (Platform.isWindows) {
      // No Windows, Firebase não está inicializado, assume não logado
      if (mounted) {
        setState(() {
          _isUserLoggedIn = false;
        });
      }
      return;
    }

    final user = _authService.currentUser;
    if (mounted) {
      setState(() {
        _isUserLoggedIn = user != null;
      });
    }
  }

  Future<void> _showLoginScreen() async {
    if (Platform.isWindows) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login não disponível no Windows (Firebase desabilitado)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true && mounted) {
      _checkAuthState();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        _checkAuthState();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout realizado com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      // Firebase AI é o único serviço disponível
      final geminiService = GeminiService();
      _aiAvailable = await geminiService.isServiceAvailable();

      if (mounted) {
        setState(() {
          _isOfflineMode = !_aiAvailable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOfflineMode = true;
          _aiAvailable = false;
        });
      }
    }
  }

  void _goToConfig() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const ConfiguracaoScreen(),
      ),
    )
        .then((_) {
      // Verificar se ainda está montado antes de verificar serviços de IA
      if (mounted) {
        _checkAIServices();
      }
    });
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

  void _goToTesteFirebaseAI() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TesteFirebaseAIScreen(),
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
        return const PerfilScreen();
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
      floatingActionButton: !_isLoading
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestePersonagem3DScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.person),
            )
          : null,
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 280, // Largura expandida para desktop
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        border: Border(
          right: BorderSide(
            color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da sidebar
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MathQuest',
                          style: TextStyle(
                            color: AppTheme.darkTextPrimaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isUserLoggedIn ? 'Usuário logado' : 'Modo convidado',
                          style: TextStyle(
                            color: _isUserLoggedIn
                                ? AppTheme.successColor
                                : AppTheme.darkTextSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Indicador de status da IA
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _aiAvailable
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _aiAvailable
                          ? AppTheme.successColor.withValues(alpha: 0.3)
                          : AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _aiAvailable
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _aiAvailable
                            ? 'IA Online'
                            : (_isOfflineMode
                                ? 'Modo Offline'
                                : 'IA Indisponível'),
                        style: TextStyle(
                          color: _aiAvailable
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navegação principal
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'NAVEGAÇÃO',
                      style: TextStyle(
                        color: AppTheme.darkTextSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...List.generate(_navigationItems.length, (index) {
                    final item = _navigationItems[index];
                    final isSelected = _selectedIndex == index;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onNavigationTap(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.darkTextSecondaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.darkTextPrimaryColor,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Footer da sidebar
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Botão de Login/Logout
                if (!_isUserLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showLoginScreen,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.login_rounded,
                                color: AppTheme.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fazer Login',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_isUserLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _signOut,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.warningColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppTheme.warningColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Fazer Logout',
                                style: TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        color: AppTheme.darkTextSecondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Precisa de ajuda?',
                        style: TextStyle(
                          color: AppTheme.darkTextSecondaryColor,
                          fontSize: 12,
                        ),
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
                      // Header + Card unificado com título e boas-vindas
                      ResponsiveHeader(
                        title: 'MathQuest',
                        subtitle: _isOfflineMode
                            ? 'Modo offline ativo • Exercícios básicos disponíveis'
                            : 'Sistema de IA conectado • Experiência completa disponível',
                        showBackButton: false,
                      ),
                      const SizedBox(height: 12),
                      ModernCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.primaryLightColor
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.waving_hand_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bem-vindo!',
                                          style: AppTheme.bodyLarge.copyWith(
                                            color:
                                                AppTheme.darkTextPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _isOfflineMode
                                              ? 'Continue seus estudos sem conexão.'
                                              : 'Aproveite toda a experiência com IA habilitada.',
                                          style: AppTheme.bodySmall.copyWith(
                                            color:
                                                AppTheme.darkTextSecondaryColor,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                                    ModernButton(
                                      text: 'Iniciar',
                                      onPressed: _goToModulos,
                                      isPrimary: true,
                                      height: buttonHeight,
                                    ),
                                    SizedBox(height: spacing),
                                    ModernButton(
                                      text: 'Modo Quiz',
                                      onPressed: _startQuizAlternado,
                                      isPrimary: false,
                                      height: buttonHeight,
                                    ),
                                    SizedBox(height: spacing),
                                    ModernButton(
                                      text: 'Configurações',
                                      onPressed: _goToConfig,
                                      isPrimary: false,
                                      height: buttonHeight,
                                    ),
                                    SizedBox(height: spacing),
                                    ModernButton(
                                      text: 'Relatórios',
                                      onPressed: _goToRelatorios,
                                      isPrimary: false,
                                      height: buttonHeight,
                                    ),
                                    SizedBox(height: spacing),
                                    ModernButton(
                                      text: 'Ajuda',
                                      onPressed: _goToAjuda,
                                      isPrimary: false,
                                      height: buttonHeight,
                                    ),
                                    SizedBox(height: spacing),
                                    ModernButton(
                                      text: 'Teste Firebase AI',
                                      onPressed: _goToTesteFirebaseAI,
                                      isPrimary: false,
                                      height: buttonHeight,
                                    ),
                                    if (!_isUserLoggedIn) ...[
                                      SizedBox(height: spacing),
                                      ModernButton(
                                        text: 'Fazer Login',
                                        icon: Icons.login_rounded,
                                        onPressed: _showLoginScreen,
                                        isPrimary: false,
                                        height: buttonHeight,
                                      ),
                                    ],
                                    if (_isUserLoggedIn) ...[
                                      SizedBox(height: spacing),
                                      ModernButton(
                                        text: 'Fazer Logout',
                                        icon: Icons.logout_rounded,
                                        onPressed: _signOut,
                                        isPrimary: false,
                                        height: buttonHeight,
                                      ),
                                    ],
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

  // ...existing code... (mobile buttons replaced by ModernButton)
}
