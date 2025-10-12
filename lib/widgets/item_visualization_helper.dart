import 'package:flutter/material.dart';
import '../features/theme/app_theme.dart';
import 'personagem_3d_widget.dart';

class ItemVisualizationHelper {
  // Cores por categoria
  static Color getCorCategoria(String categoria) {
    switch (categoria) {
      case 'cabeca':
        return Colors.orange;
      case 'corpo':
        return AppTheme.primaryColor;
      case 'pernas':
        return Colors.indigo;
      case 'acessorio':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Ícones por categoria
  static IconData getIconeCategoria(String categoria) {
    switch (categoria) {
      case 'cabeca':
        return Icons.face;
      case 'corpo':
        return Icons.checkroom;
      case 'pernas':
        return Icons.stairs;
      case 'acessorio':
        return Icons.star;
      default:
        return Icons.category;
    }
  }

  // Cores por raridade
  static Color getCorRaridade(String raridade) {
    switch (raridade) {
      case 'comum':
        return Colors.grey[400]!;
      case 'raro':
        return Colors.blue[400]!;
      case 'epico':
        return Colors.purple[400]!;
      case 'lendario':
        return Colors.orange[400]!;
      default:
        return Colors.white;
    }
  }

  // Widget para preview de item com cores e ícones
  static Widget buildItemPreview({
    required String categoria,
    required String raridade,
    String? itemId,
    double size = 48,
    bool showRarityGlow = true,
  }) {
    final cor = getCorCategoria(categoria);
    final icone = getIconeCategoria(categoria);
    final corRaridade = getCorRaridade(raridade);

    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.2),
        border: Border.all(
          color: showRarityGlow ? corRaridade : cor,
          width: 2,
        ),
        boxShadow: showRarityGlow && raridade != 'comum'
            ? [
                const BoxShadow(
                  color: Color.fromARGB(102, 0, 0, 0),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        icone,
        color: cor,
        size: size,
      ),
    );
  }

  // Widget para preview do personagem completo com visual 3D estilo Roblox
  static Widget buildPersonagemCompleto({
    required Map<String, String> itensEquipados,
    double width = 200,
    double height = 300,
    String? nome,
    bool interactive = true,
  }) {
    return Personagem3DWidget(
      itensEquipados: itensEquipados,
      width: width,
      height: height,
      interactive: interactive,
      nome: nome,
    );
  }

  // Gera uma cor representativa para um item específico baseado no ID
  static Color getCorPorItemId(String itemId) {
    final hash = itemId.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.6, 0.8).toColor();
  }

  // Widget card de item mais elaborado
  static Widget buildItemCard({
    required String nome,
    required String categoria,
    required String raridade,
    required int preco,
    required bool desbloqueado,
    required bool equipado,
    required bool possuido,
    required VoidCallback? onTap,
    String? condicaoDesbloqueio,
  }) {
    final corRaridade = getCorRaridade(raridade);

    return Card(
      color: AppTheme.darkSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: equipado
              ? AppTheme.primaryColor
              : (desbloqueado
                  ? corRaridade.withValues(alpha: 0.3)
                  : AppTheme.darkBorderColor),
          width: equipado ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: desbloqueado ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Preview do item
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      buildItemPreview(
                        categoria: categoria,
                        raridade: raridade,
                        size: 48,
                        showRarityGlow: desbloqueado,
                      ),
                      if (!desbloqueado)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Nome do item
              Text(
                nome,
                style: TextStyle(
                  color: desbloqueado
                      ? AppTheme.darkTextPrimaryColor
                      : AppTheme.darkTextSecondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // Raridade
              Text(
                raridade.toUpperCase(),
                style: TextStyle(
                  color: desbloqueado ? corRaridade : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Status/Ação
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: equipado
                      ? AppTheme.successColor
                      : (possuido
                          ? AppTheme.primaryColor
                          : (desbloqueado
                              ? AppTheme.accentColor
                              : AppTheme.darkBorderColor)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  equipado
                      ? 'EQUIPADO'
                      : (possuido
                          ? 'EQUIPAR'
                          : (desbloqueado ? '$preco 🪙' : 'BLOQUEADO')),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Condição de desbloqueio (se aplicável)
              if (!desbloqueado && condicaoDesbloqueio != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    condicaoDesbloqueio,
                    style: TextStyle(
                      color: AppTheme.darkTextHintColor,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
