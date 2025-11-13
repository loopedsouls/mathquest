import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../widgets/core_modern_components_widget.dart';
import '../../../models/ai_bncc_module_model.dart';

class ModulosBNCCScreen extends StatefulWidget {
  const ModulosBNCCScreen({super.key});

  @override
  State<ModulosBNCCScreen> createState() => _ModulosBNCCScreenState();
}

class _ModulosBNCCScreenState extends State<ModulosBNCCScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedAno = '';

  final List<String> _unidadesTematicas =
      ModulosBNCCData.obterUnidadesTematicas();
  final List<String> _anosEscolares = ModulosBNCCData.obterAnosEscolares();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Selecionar ano por padrão
    if (_anosEscolares.isNotEmpty) {
      _selectedAno = _anosEscolares.first;
    }
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getUnidadeIcon(String unidade) {
    switch (unidade) {
      case 'Números':
        return Icons.calculate_rounded;
      case 'Álgebra':
        return Icons.functions_rounded;
      case 'Geometria':
        return Icons.category_rounded;
      case 'Grandezas e Medidas':
        return Icons.straighten_rounded;
      case 'Probabilidade e Estatística':
        return Icons.bar_chart_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _getUnidadeColor(String unidade) {
    switch (unidade) {
      case 'Números':
        return AppTheme.primaryColor;
      case 'Álgebra':
        return AppTheme.secondaryColor;
      case 'Geometria':
        return const Color(0xFF9C27B0);
      case 'Grandezas e Medidas':
        return const Color(0xFFFF9800);
      case 'Probabilidade e Estatística':
        return const Color(0xFF4CAF50);
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getUnidadeDescricao(String unidade) {
    switch (unidade) {
      case 'Números':
        return 'Estudo dos números naturais, inteiros, racionais e reais, operações e propriedades.';
      case 'Álgebra':
        return 'Expressões algébricas, equações, funções e resolução de problemas.';
      case 'Geometria':
        return 'Figuras geométricas, medidas, transformações e propriedades espaciais.';
      case 'Grandezas e Medidas':
        return 'Unidades de medida, conversões e aplicações práticas.';
      case 'Probabilidade e Estatística':
        return 'Análise de dados, probabilidade e interpretação de informações.';
      default:
        return 'Conteúdo educacional estruturado.';
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
                // Header responsivo
                const ResponsiveHeader(
                  title: 'Módulos BNCC',
                  subtitle: 'Conteúdo educacional estruturado por ano escolar',
                  showBackButton: true,
                ), // Conteúdo principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
                      vertical: isDesktop ? 32 : (isTablet ? 24 : 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seletor de ano escolar
                        ModernCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecione o Ano Escolar',
                                style: AppTheme.headingMedium.copyWith(
                                  color: AppTheme.darkTextPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: _anosEscolares.map((ano) {
                                  final isSelected = _selectedAno == ano;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedAno = ano;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                                .withValues(alpha: 0.1)
                                            : AppTheme.darkSurfaceColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.darkBorderColor,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        ano,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.darkTextPrimaryColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Unidades temáticas
                        Text(
                          'Unidades Temáticas',
                          style: AppTheme.headingLarge.copyWith(
                            color: AppTheme.darkTextPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        ..._unidadesTematicas.map((unidade) {
                          final color = _getUnidadeColor(unidade);
                          final modulo = ModulosBNCCData.obterModulo(
                              unidade, _selectedAno);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ModernCard(
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navegar para tela de detalhes do módulo
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Módulo "$unidade" selecionado'),
                                      backgroundColor: color,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color:
                                                  color.withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getUnidadeIcon(unidade),
                                              color: color,
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
                                                  unidade,
                                                  style: AppTheme.headingMedium
                                                      .copyWith(
                                                    color: AppTheme
                                                        .darkTextPrimaryColor,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _getUnidadeDescricao(unidade),
                                                  style: AppTheme.bodyMedium
                                                      .copyWith(
                                                    color: AppTheme
                                                        .darkTextSecondaryColor,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color:
                                                AppTheme.darkTextSecondaryColor,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      if (modulo != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.darkSurfaceColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppTheme.darkBorderColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.info_outline_rounded,
                                                color: AppTheme
                                                    .darkTextSecondaryColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Código BNCC: ${modulo.codigoBNCC}',
                                                style:
                                                    AppTheme.bodySmall.copyWith(
                                                  color: AppTheme
                                                      .darkTextSecondaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warningColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppTheme.warningColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_rounded,
                                                color: AppTheme.warningColor,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Conteúdo em desenvolvimento',
                                                style:
                                                    AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.warningColor,
                                                  fontWeight: FontWeight.w500,
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
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 32),

                        // Informações sobre BNCC
                        ModernCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.school_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Sobre a BNCC',
                                      style: AppTheme.headingMedium.copyWith(
                                        color: AppTheme.darkTextPrimaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'A Base Nacional Comum Curricular (BNCC) define o conjunto de aprendizagens essenciais que todos os alunos devem desenvolver ao longo da Educação Básica. Ela organiza o currículo em áreas do conhecimento e define habilidades e competências que os estudantes devem desenvolver.',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Os módulos são organizados por unidade temática e ano escolar, seguindo as diretrizes da BNCC para garantir uma aprendizagem progressiva e significativa.',
                                          style: AppTheme.bodySmall.copyWith(
                                            color:
                                                AppTheme.darkTextPrimaryColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
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
