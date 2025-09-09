import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/matematica.dart';

class CursoStatsWidget extends StatelessWidget {
  final CursoMatematica curso;
  final double? progressoGeral;

  const CursoStatsWidget({
    super.key,
    required this.curso,
    this.progressoGeral,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _calcularEstatisticas();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(curso.cor).withValues(alpha: 0.1),
            Color(curso.cor).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(curso.cor).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(curso.cor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(curso.cor).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  curso.icone,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.titulo,
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.darkTextPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      curso.descricao,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.darkTextSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(curso.cor).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color(curso.cor).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            curso.nivel.icone,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            curso.nivel.nome,
                            style: TextStyle(
                              color: Color(curso.cor),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
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

          const SizedBox(height: 24),

          // Progresso geral (se disponível)
          if (progressoGeral != null) ...[
            Text(
              'Seu Progresso',
              style: AppTheme.headingMedium.copyWith(
                color: AppTheme.darkTextPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildProgressBar(),
            const SizedBox(height: 24),
          ],

          // Estatísticas
          Text(
            'Informações do Curso',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Grid de estatísticas
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildStatCard(
                'Trilhas',
                '${stats['trilhas']}',
                Icons.timeline,
                Color(curso.cor),
              ),
              _buildStatCard(
                'Módulos',
                '${stats['modulos']}',
                Icons.book,
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                'Duração',
                '${stats['duracao']} dias',
                Icons.access_time,
                AppTheme.warningColor,
              ),
              _buildStatCard(
                'Exercícios',
                '${stats['exercicios']}+',
                Icons.quiz,
                AppTheme.successColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Competências desenvolvidas
          Text(
            'Competências Desenvolvidas',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: curso.competenciasDesenvolvidas.map((competencia) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  competencia,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progresso = progressoGeral ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progresso * 100).toInt()}% concluído',
              style: AppTheme.bodyMedium.copyWith(
                color: Color(curso.cor),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_calcularModulosCompletos()}/${curso.totalModulos} módulos',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: AppTheme.darkBorderColor.withValues(alpha: 0.3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progresso,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    Color(curso.cor),
                    Color(curso.cor).withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
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
                    fontSize: 18,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkTextSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calcularEstatisticas() {
    int totalModulos = 0;
    int totalExercicios = 0;

    for (final trilha in curso.trilhas.values) {
      totalModulos += trilha.modulos.length;
      for (final modulo in trilha.modulos) {
        totalExercicios += modulo.avaliacao.exerciciosNecessarios;
      }
    }

    return {
      'trilhas': curso.trilhas.length,
      'modulos': totalModulos,
      'duracao': curso.duracaoEstimada.inDays,
      'exercicios': totalExercicios,
    };
  }

  int _calcularModulosCompletos() {
    // Implementar lógica real baseada no progresso do usuário
    return ((progressoGeral ?? 0.0) * curso.totalModulos).round();
  }
}

// Widget para mostrar trilhas em formato de roadmap
class TrilhaRoadmapWidget extends StatelessWidget {
  final List<TrilhaAprendizado> trilhas;
  final Function(TrilhaAprendizado) onTrilhaTap;
  final String? trilhaAtiva;

  const TrilhaRoadmapWidget({
    super.key,
    required this.trilhas,
    required this.onTrilhaTap,
    this.trilhaAtiva,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roadmap de Aprendizado',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.darkTextPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...trilhas.asMap().entries.map((entry) {
            final index = entry.key;
            final trilha = entry.value;
            final isAtiva = trilha.id == trilhaAtiva;
            final isCompleta = false; // Implementar lógica real
            final isProxima = index == 0; // Implementar lógica real

            return _buildTrilhaRoadmapItem(
              trilha,
              index,
              isAtiva,
              isCompleta,
              isProxima,
              index < trilhas.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrilhaRoadmapItem(
    TrilhaAprendizado trilha,
    int index,
    bool isAtiva,
    bool isCompleta,
    bool isProxima,
    bool showConnector,
  ) {
    Color corStatus = AppTheme.darkBorderColor;
    IconData iconeStatus = Icons.lock;

    if (isCompleta) {
      corStatus = AppTheme.successColor;
      iconeStatus = Icons.check_circle;
    } else if (isAtiva || isProxima) {
      corStatus = Color(trilha.cor);
      iconeStatus = Icons.play_circle;
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => onTrilhaTap(trilha),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Indicador de status
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: corStatus.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: corStatus,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    iconeStatus,
                    color: corStatus,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Informações da trilha
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isAtiva
                          ? Color(trilha.cor).withValues(alpha: 0.1)
                          : AppTheme.darkSurfaceColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAtiva
                            ? Color(trilha.cor).withValues(alpha: 0.3)
                            : AppTheme.darkBorderColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              trilha.icone,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trilha.titulo,
                                style: AppTheme.headingSmall.copyWith(
                                  color: AppTheme.darkTextPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(trilha.cor).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${trilha.ordem}ª',
                                style: TextStyle(
                                  color: Color(trilha.cor),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trilha.descricao,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              size: 16,
                              color: AppTheme.darkTextSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${trilha.modulos.length} módulos',
                              style: TextStyle(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: AppTheme.darkTextSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '~${trilha.duracaoEstimada.inDays} dias',
                              style: TextStyle(
                                color: AppTheme.darkTextSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Connector line
        if (showConnector)
          Container(
            margin: const EdgeInsets.only(left: 24),
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.darkBorderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
      ],
    );
  }
}
