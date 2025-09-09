import 'package:flutter/material.dart';
import '../models/matematica.dart';
import '../theme/app_theme.dart';

/// Exemplo simples de como usar a nova estrutura de cursos
class ExemploNovaEstrutura extends StatelessWidget {
  const ExemploNovaEstrutura({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text('📚 Nova Estrutura - Exemplo'),
        backgroundColor: AppTheme.darkSurfaceColor,
        foregroundColor: AppTheme.darkTextPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Estrutura Profissional de Cursos',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.darkTextPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Demonstração da nova arquitetura seguindo padrões UX/UI modernos',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Exemplo 1: Listando todos os cursos
            _buildSection(
              '1. Lista de Cursos Disponíveis',
              () {
                final cursos = Matematica.obterTodosCursos();
                return Column(
                  children: cursos.map((curso) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(curso.cor).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(curso.cor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(curso.icone,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  curso.titulo,
                                  style: AppTheme.headingSmall.copyWith(
                                    color: AppTheme.darkTextPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${curso.trilhas.length} trilhas • ${curso.totalModulos} módulos',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.darkTextSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Exemplo 2: Estatísticas gerais
            _buildSection(
              '2. Estatísticas da Plataforma',
              () {
                final stats = Matematica.obterEstatisticas();
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryLightColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                    children: [
                      _buildStatItem(
                        'Cursos',
                        '${stats['total_cursos']}',
                        Icons.school,
                        AppTheme.primaryColor,
                      ),
                      _buildStatItem(
                        'Trilhas',
                        '${stats['total_trilhas']}',
                        Icons.timeline,
                        AppTheme.successColor,
                      ),
                      _buildStatItem(
                        'Módulos',
                        '${stats['total_modulos']}',
                        Icons.book,
                        AppTheme.warningColor,
                      ),
                      _buildStatItem(
                        'Duração',
                        '${stats['duracao_total_dias']}d',
                        Icons.access_time,
                        AppTheme.errorColor,
                      ),
                    ],
                  ),
                );
              },
            ),

            // Exemplo 3: Trilhas do Fundamental Inicial
            _buildSection(
              '3. Trilhas do Fundamental Inicial',
              () {
                final trilhas =
                    Matematica.obterTrilhasDoCurso('fundamental_inicial');
                return Column(
                  children: trilhas.map((trilha) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(trilha.cor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      Color(trilha.cor).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(trilha.icone,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trilha.titulo,
                                      style: AppTheme.headingSmall.copyWith(
                                        color: AppTheme.darkTextPrimaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      trilha.descricao,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.darkTextSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Color(trilha.cor).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${trilha.ordem}ª',
                                  style: TextStyle(
                                    color: Color(trilha.cor),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Módulos (${trilha.modulos.length}):',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.darkTextPrimaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...trilha.modulos.map((modulo) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Color(modulo.dificuldade.cor)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        modulo.dificuldade.icone,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      modulo.titulo,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.darkTextSecondaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${modulo.estimativaTempo.inHours}h',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.darkTextSecondaryColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Exemplo 4: Busca de módulos
            _buildSection(
              '4. Busca por "frações"',
              () {
                final resultados = Matematica.buscarModulos('frações');
                if (resultados.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Nenhum resultado encontrado para "frações"',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                  );
                }

                return Column(
                  children: resultados.map((modulo) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(modulo.dificuldade.cor)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              modulo.dificuldade.icone,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  modulo.titulo,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkTextPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  modulo.descricao,
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
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String titulo, Widget Function() builder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        builder(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
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
    );
  }
}
