import 'package:flutter/material.dart';
import 'package:mathquest/data/models/course_model.dart';
import 'package:mathquest/app/theme/app_theme.dart';

/// Widget para exibir estatísticas de um curso
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            curso.cor.withValues(alpha: 0.1),
            curso.cor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: curso.cor.withValues(alpha: 0.2),
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
                  color: curso.cor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: curso.cor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  curso.icone,
                  size: 32,
                  color: Colors.white,
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
                        color: curso.cor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: curso.cor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.signal_cellular_alt, size: 16, color: curso.cor),
                          const SizedBox(width: 6),
                          Text(
                            curso.nivel,
                            style: AppTheme.bodySmall.copyWith(
                              color: curso.cor,
                              fontWeight: FontWeight.bold,
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
          // Barra de Progresso
          _buildProgressBar(),
          const SizedBox(height: 24),
          // Grid de Estatísticas
          _buildStatsGrid(),
          const SizedBox(height: 24),
          // Competências
          if (curso.competenciasDesenvolvidas.isNotEmpty) ...[
            Text(
              'Competências Desenvolvidas',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.darkTextPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: curso.competenciasDesenvolvidas
                  .map((c) => _buildCompetenciaChip(c))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progresso = progressoGeral ?? curso.progressoPercentual;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progresso Geral',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkTextSecondaryColor,
              ),
            ),
            Text(
              '${progresso.toStringAsFixed(0)}%',
              style: AppTheme.bodyMedium.copyWith(
                color: curso.cor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progresso / 100,
            backgroundColor: curso.cor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(curso.cor),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            Icons.library_books,
            '${curso.trilhas.length}',
            'Trilhas',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.view_module,
            '${curso.totalModulos}',
            'Módulos',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.access_time,
            curso.duracaoEstimada,
            'Duração',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.quiz,
            '${curso.totalAulas}',
            'Aulas',
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: curso.cor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.darkTextPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.darkTextSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCompetenciaChip(String competencia) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: curso.cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: curso.cor.withValues(alpha: 0.3)),
      ),
      child: Text(
        competencia,
        style: AppTheme.bodySmall.copyWith(
          color: curso.cor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Widget de Roadmap de Trilhas
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
            final isActive = trilha.id == trilhaAtiva;
            final isCompleted = trilha.completa;
            final isLast = index == trilhas.length - 1;

            return _buildTrilhaItem(
              trilha,
              isActive: isActive,
              isCompleted: isCompleted,
              showConnector: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrilhaItem(
    TrilhaAprendizado trilha, {
    required bool isActive,
    required bool isCompleted,
    required bool showConnector,
  }) {
    final statusColor = isCompleted
        ? AppTheme.successColor
        : isActive
            ? trilha.cor
            : AppTheme.darkTextHintColor;

    return InkWell(
      onTap: trilha.bloqueada ? null : () => onTrilhaTap(trilha),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? trilha.cor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? trilha.cor.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Ícone de Status
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check
                        : trilha.bloqueada
                            ? Icons.lock
                            : trilha.icone,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trilha.titulo,
                        style: AppTheme.headingSmall.copyWith(
                          color: trilha.bloqueada
                              ? AppTheme.darkTextHintColor
                              : AppTheme.darkTextPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trilha.descricao,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.darkTextSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.library_books,
                            size: 16,
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${trilha.aulas.length} aulas',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextSecondaryColor,
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
                            trilha.duracaoEstimada,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkTextSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (!trilha.bloqueada && !isCompleted) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: trilha.progressoPercentual / 100,
                            backgroundColor: trilha.cor.withValues(alpha: 0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(trilha.cor),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Seta
                if (!trilha.bloqueada)
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.darkTextSecondaryColor,
                  ),
              ],
            ),
          ),
          // Conector
          if (showConnector)
            Container(
              width: 2,
              height: 24,
              margin: const EdgeInsets.only(left: 39),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    statusColor,
                    AppTheme.darkTextHintColor,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget de Card de Trilha
class TrilhaCardWidget extends StatelessWidget {
  final TrilhaAprendizado trilha;
  final VoidCallback? onTap;

  const TrilhaCardWidget({
    super.key,
    required this.trilha,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: trilha.bloqueada ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: trilha.cor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      trilha.icone,
                      color: trilha.cor,
                      size: 24,
                    ),
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
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trilha.aulas.length} aulas • ${trilha.duracaoEstimada}',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.darkTextSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trilha.bloqueada)
                    const Icon(Icons.lock, color: Colors.grey)
                  else if (trilha.completa)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              if (!trilha.bloqueada) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: trilha.progressoPercentual / 100,
                    backgroundColor: trilha.cor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(trilha.cor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${trilha.progressoPercentual.toStringAsFixed(0)}% completo',
                  style: AppTheme.bodySmall.copyWith(
                    color: trilha.cor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
