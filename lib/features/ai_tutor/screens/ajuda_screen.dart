import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../../widgets/modern_components.dart';

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Ajuda & Tutorial',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.darkTextPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.darkSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.darkTextPrimaryColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bem-vindo ao MathQuest!',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Este aplicativo ajuda você a aprender matemática de forma interativa e adaptativa. Aqui está um guia rápido para começar.',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Seção de recursos disponíveis
                _buildFeaturesSection(),
                const SizedBox(height: 20),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Como Usar',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHelpItem(
                        icon: Icons.rocket_launch_rounded,
                        title: 'Iniciar Tutoria',
                        description:
                            'Clique para começar exercícios adaptativos. A dificuldade se ajusta ao seu progresso.',
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.quiz_rounded,
                        title: 'Quiz Múltipla Escolha',
                        description:
                            'Responda perguntas de múltipla escolha sobre diversos tópicos matemáticos.',
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.check_box_rounded,
                        title: 'Quiz Verdadeiro/Falso',
                        description:
                            'Avalie afirmações matemáticas respondendo verdadeiro ou falso.',
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.book_rounded,
                        title: 'Complete a Frase',
                        description:
                            'Preencha lacunas em frases matemáticas para testar seu conhecimento.',
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.settings_rounded,
                        title: 'Configurações',
                        description:
                            'Personalize o aplicativo, como modo offline ou configurações de IA.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modos Disponíveis',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHelpItem(
                        icon: Icons.wifi_rounded,
                        title: 'Modo Online',
                        description:
                            'Conectado à IA para exercícios gerados dinamicamente e explicações detalhadas.',
                      ),
                      const SizedBox(height: 12),
                      _buildHelpItem(
                        icon: Icons.wifi_off_rounded,
                        title: 'Modo Offline',
                        description:
                            'Use exercícios pré-carregados quando não houver conexão com a internet.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dicas para Melhorar',
                        style: AppTheme.headingMedium.copyWith(
                          color: AppTheme.darkTextPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '• Pratique regularmente para melhorar seu desempenho.\n'
                        '• Leia as explicações após cada resposta para entender melhor.\n'
                        '• Use o modo offline para praticar sem distrações.\n'
                        '• Ajuste as configurações conforme sua preferência.',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkTextPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkTextSecondaryColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Exercícios Adaptativos',
        'description': 'Dificuldade ajustada automaticamente ao seu progresso',
        'color': AppTheme.primaryColor,
      },
      {
        'icon': Icons.psychology_rounded,
        'title': 'Explicações com IA',
        'description': 'Passo-a-passo detalhado para cada exercício',
        'color': AppTheme.secondaryColor,
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Progresso Detalhado',
        'description': 'Acompanhe seu desempenho e evolução',
        'color': AppTheme.infoColor,
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'Múltiplos Formatos',
        'description': 'Diversos tipos de exercícios e quizzes',
        'color': AppTheme.accentColor,
      },
    ];

    return ModernCard(
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚀 Recursos Disponíveis',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...features.map((feature) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (feature['color']! as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (feature['color']! as Color).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: feature['color']! as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        feature['icon']! as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title']! as String,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkTextPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['description']! as String,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextSecondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
