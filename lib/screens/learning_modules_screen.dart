import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/core_modern_components_widget.dart';
import '../../../models/user_progress_model.dart';
import '../../../services/user_progresso_service.dart';

class ModulosScreen extends StatefulWidget {
  const ModulosScreen({super.key});

  @override
  State<ModulosScreen> createState() => _ModulosScreenState();
}

class _ModulosScreenState extends State<ModulosScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ProgressoUsuario? _progresso;
  bool _isLoading = true;

  // Lista de módulos/cursos disponíveis
  final List<Map<String, dynamic>> _cursosDisponiveis = [
    {
      'id': 'matematica_basica',
      'titulo': 'Matemática Básica',
      'descricao': 'Fundamentos da matemática para construir uma base sólida',
      'icon': Icons.calculate_rounded,
      'color': AppTheme.primaryColor,
      'disponivel': true,
      'nivel': 'Iniciante',
    },
    {
      'id': 'geometria',
      'titulo': 'Geometria',
      'descricao': 'Formas, figuras e propriedades espaciais',
      'icon': Icons.category_rounded,
      'color': Color(0xFF9C27B0),
      'disponivel': false,
      'nivel': 'Intermediário',
    },
    {
      'id': 'algebra',
      'titulo': 'Álgebra',
      'descricao': 'Expressões, equações e funções',
      'icon': Icons.functions_rounded,
      'color': AppTheme.secondaryColor,
      'disponivel': false,
      'nivel': 'Intermediário',
    },
    {
      'id': 'trigonometria',
      'titulo': 'Trigonometria',
      'descricao': 'Estudo de triângulos e funções trigonométricas',
      'icon': Icons.architecture_rounded,
      'color': Color(0xFFFF5722),
      'disponivel': false,
      'nivel': 'Avançado',
    },
    {
      'id': 'calculo',
      'titulo': 'Cálculo',
      'descricao': 'Limites, derivadas e integrais',
      'icon': Icons.auto_graph_rounded,
      'color': Color(0xFF00BCD4),
      'disponivel': false,
      'nivel': 'Avançado',
    },
    {
      'id': 'outros',
      'titulo': 'Outros',
      'descricao': 'Tópicos especiais e avançados',
      'icon': Icons.more_horiz_rounded,
      'color': Color(0xFF607D8B),
      'disponivel': false,
      'nivel': 'Variável',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarProgresso();
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

    _animationController.forward();
  }

  Future<void> _carregarProgresso() async {
    try {
      final progresso = await ProgressoServiceV2.carregarProgresso();
      setState(() {
        _progresso = progresso;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getNivelText() {
    if (_progresso == null) return 'Iniciante';
    return _progresso!.nivelUsuario.toString().split('.').last;
  }

  Color _getNivelColor(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'iniciante':
        return AppTheme.successColor;
      case 'intermediário':
        return AppTheme.warningColor;
      case 'avançado':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
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
              AppTheme.darkSurfaceColor.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                const ResponsiveHeader(
                  title: 'Módulos de Estudos',
                  subtitle: '',
                  showBackButton: false,
                ),

                // Conteúdo
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                            vertical: isDesktop ? 32 : (isTablet ? 24 : 16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Card de nível do usuário
                              ModernCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              AppTheme.primaryLightColor,
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.emoji_events_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nível: ${_getNivelText()}',
                                              style: AppTheme.headingMedium
                                                  .copyWith(
                                                color: AppTheme
                                                    .darkTextPrimaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: AppTheme.successColor,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Continue aprendendo!',
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                    color: AppTheme
                                                        .darkTextSecondaryColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Título da seção
                              Text(
                                'CURSOS DISPONÍVEIS',
                                style: TextStyle(
                                  color: AppTheme.darkTextSecondaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Lista de cursos
                              ..._cursosDisponiveis.map((curso) {
                                final disponivel = curso['disponivel'] as bool;
                                final color = curso['color'] as Color;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ModernCard(
                                    child: InkWell(
                                      onTap: disponivel
                                          ? () {
                                              // TODO: Navegar para tela específica do curso
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Curso "${curso['titulo']}" em desenvolvimento'),
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                              );
                                            }
                                          : null,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: disponivel
                                                    ? color.withValues(
                                                        alpha: 0.1)
                                                    : AppTheme.darkSurfaceColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                disponivel
                                                    ? curso['icon'] as IconData
                                                    : Icons.lock_rounded,
                                                color: disponivel
                                                    ? color
                                                    : AppTheme
                                                        .darkTextSecondaryColor,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    curso['titulo'] as String,
                                                    style: AppTheme
                                                        .headingMedium
                                                        .copyWith(
                                                      color: disponivel
                                                          ? AppTheme
                                                              .darkTextPrimaryColor
                                                          : AppTheme
                                                              .darkTextSecondaryColor,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    curso['descricao']
                                                        as String,
                                                    style: AppTheme.bodyMedium
                                                        .copyWith(
                                                      color: AppTheme
                                                          .darkTextSecondaryColor,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: _getNivelColor(
                                                                  curso['nivel']
                                                                      as String)
                                                              .withValues(
                                                                  alpha: 0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                        child: Text(
                                                          curso['nivel']
                                                              as String,
                                                          style: AppTheme
                                                              .bodySmall
                                                              .copyWith(
                                                            color: _getNivelColor(
                                                                curso['nivel']
                                                                    as String),
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      if (disponivel) ...[
                                                        const SizedBox(
                                                            width: 8),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: AppTheme
                                                                .successColor
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle_rounded,
                                                                color: AppTheme
                                                                    .successColor,
                                                                size: 12,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                'Disponível',
                                                                style: AppTheme
                                                                    .bodySmall
                                                                    .copyWith(
                                                                  color: AppTheme
                                                                      .successColor,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (disponivel)
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: AppTheme
                                                    .darkTextSecondaryColor,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 32),

                              // Informações sobre progresso
                              ModernCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            color: AppTheme.primaryColor,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Sobre os Módulos',
                                            style:
                                                AppTheme.headingMedium.copyWith(
                                              color:
                                                  AppTheme.darkTextPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Os módulos são organizados por nível de dificuldade. Complete os exercícios e desbloqueie novos conteúdos à medida que avança!',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color:
                                              AppTheme.darkTextSecondaryColor,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
