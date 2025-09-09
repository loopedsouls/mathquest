import 'package:flutter/material.dart';
import '../models/matematica.dart';
import '../theme/app_theme.dart';
import '../widgets/curso_widgets.dart';

/// Tela de demonstração da nova estrutura profissional de cursos
class DemonstracaoCursosScreen extends StatefulWidget {
  const DemonstracaoCursosScreen({super.key});

  @override
  State<DemonstracaoCursosScreen> createState() =>
      _DemonstracaoCursosScreenState();
}

class _DemonstracaoCursosScreenState extends State<DemonstracaoCursosScreen> {
  String _cursoSelecionado = 'fundamental_inicial';

  @override
  Widget build(BuildContext context) {
    final curso = Matematica.obterTodosCursos().firstWhere(
      (c) => c.id == _cursoSelecionado,
      orElse: () => null,
    );
    final estatisticas = Matematica.obterEstatisticas();

    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text('📚 Nova Estrutura de Cursos'),
        backgroundColor: AppTheme.darkSurfaceColor,
        foregroundColor: AppTheme.darkTextPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estatísticas gerais
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryLightColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Plataforma MathQuest',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.darkTextPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estrutura profissional seguindo padrões UX/UI modernos',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkTextSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildStatCard(
                        'Cursos',
                        '${estatisticas['total_cursos']}',
                        Icons.school,
                        AppTheme.primaryColor,
                      ),
                      _buildStatCard(
                        'Trilhas',
                        '${estatisticas['total_trilhas']}',
                        Icons.timeline,
                        AppTheme.successColor,
                      ),
                      _buildStatCard(
                        'Módulos',
                        '${estatisticas['total_modulos']}',
                        Icons.book,
                        AppTheme.warningColor,
                      ),
                      _buildStatCard(
                        'Duração',
                        '${estatisticas['duracao_total_dias']}d',
                        Icons.access_time,
                        AppTheme.errorColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Seletor de curso
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Cursos Disponíveis',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.darkTextPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Lista de cursos
            Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: Matematica.obterTodosCursos().length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final curso = Matematica.obterTodosCursos()[index];
                  final isSelected = curso.id == _cursoSelecionado;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _cursoSelecionado = curso.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  Color(curso.cor),
                                  Color(curso.cor).withValues(alpha: 0.7),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppTheme.darkSurfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Color(curso.cor).withValues(alpha: 0.5)
                              : AppTheme.darkBorderColor,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      Color(curso.cor).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            curso.icone,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            curso.titulo.split(' - ')[0],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.darkTextPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            curso.nivel.descricao,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppTheme.darkTextSecondaryColor,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Detalhes do curso selecionado
            if (curso != null) ...[
              CursoStatsWidget(
                curso: curso,
                progressoGeral: 0.3, // 30% de exemplo
              ),

              // Roadmap de trilhas
              TrilhaRoadmapWidget(
                trilhas: curso.trilhas.values.toList()
                  ..sort((a, b) => a.ordem.compareTo(b.ordem)),
                onTrilhaTap: (trilha) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trilha selecionada: ${trilha.titulo}'),
                      backgroundColor: Color(trilha.cor),
                    ),
                  );
                },
                trilhaAtiva: 'numeros_operacoes_basicas',
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTheme.headingMedium.copyWith(
                    color: AppTheme.darkTextPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
