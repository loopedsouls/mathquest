import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../app_theme.dart';

class LatexMarkdownWidget extends StatelessWidget {
  final String data;
  final bool isTablet;

  const LatexMarkdownWidget({
    super.key,
    required this.data,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    // Divide o texto em partes, separando LaTeX de texto normal
    final parts = _parseLatexAndMarkdown(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        if (part.isLatex) {
          return _buildLatexWidget(part.content);
        } else {
          return _buildMarkdownWidget(part.content);
        }
      }).toList(),
    );
  }

  Widget _buildLatexWidget(String latex) {
    try {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Math.tex(
            latex,
            textStyle: TextStyle(
              color: AppTheme.darkTextPrimaryColor,
              fontSize: isTablet ? 18 : 16,
            ),
            mathStyle: MathStyle.display,
          ),
        ),
      );
    } catch (e) {
      // Se houver erro no LaTeX, mostra como código
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          'LaTeX Error: $latex',
          style: TextStyle(
            color: AppTheme.errorColor,
            fontSize: isTablet ? 12 : 10,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
  }

  Widget _buildMarkdownWidget(String markdown) {
    if (markdown.trim().isEmpty) return const SizedBox.shrink();

    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          color: AppTheme.darkTextPrimaryColor,
          fontSize: isTablet ? 16 : 14,
          height: 1.5,
        ),
        h1: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: isTablet ? 24 : 20,
          fontWeight: FontWeight.bold,
        ),
        h2: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: isTablet ? 22 : 18,
          fontWeight: FontWeight.bold,
        ),
        h3: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: isTablet ? 20 : 16,
          fontWeight: FontWeight.w600,
        ),
        strong: TextStyle(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.bold,
        ),
        em: TextStyle(
          color: AppTheme.darkTextSecondaryColor,
          fontStyle: FontStyle.italic,
        ),
        code: TextStyle(
          backgroundColor: AppTheme.darkBackgroundColor,
          color: AppTheme.accentColor,
          fontFamily: 'monospace',
          fontSize: isTablet ? 14 : 12,
        ),
        codeblockDecoration: BoxDecoration(
          color: AppTheme.darkBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.darkBorderColor,
          ),
        ),
        codeblockPadding: EdgeInsets.all(isTablet ? 12 : 8),
        listBullet: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: isTablet ? 16 : 14,
        ),
        blockquote: TextStyle(
          color: AppTheme.darkTextSecondaryColor,
          fontSize: isTablet ? 15 : 13,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppTheme.primaryColor,
              width: 4,
            ),
          ),
        ),
      ),
      selectable: true,
    );
  }

  List<TextPart> _parseLatexAndMarkdown(String text) {
    final parts = <TextPart>[];

    // Expressões regulares para detectar LaTeX
    final blockLatexRegex = RegExp(r'\$\$([^$]+)\$\$'); // $$...$$

    int lastIndex = 0; // Primeiro processa blocos LaTeX ($$...$$)
    for (final match in blockLatexRegex.allMatches(text)) {
      // Adiciona texto antes do LaTeX
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          parts.addAll(_parseInlineLatex(beforeText));
        }
      }

      // Adiciona o LaTeX como bloco
      parts.add(TextPart(match.group(1)!, isLatex: true));
      lastIndex = match.end;
    }

    // Adiciona o texto restante
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        parts.addAll(_parseInlineLatex(remainingText));
      }
    }

    return parts;
  }

  List<TextPart> _parseInlineLatex(String text) {
    final parts = <TextPart>[];
    final inlineLatexRegex = RegExp(r'\$([^$]+)\$'); // $...$

    int lastIndex = 0;

    for (final match in inlineLatexRegex.allMatches(text)) {
      // Adiciona texto antes do LaTeX
      if (match.start > lastIndex) {
        final beforeText = text.substring(lastIndex, match.start);
        if (beforeText.isNotEmpty) {
          parts.add(TextPart(beforeText, isLatex: false));
        }
      }

      // Adiciona o LaTeX inline
      parts.add(TextPart(match.group(1)!, isLatex: true));
      lastIndex = match.end;
    }

    // Adiciona o texto restante
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      if (remainingText.isNotEmpty) {
        parts.add(TextPart(remainingText, isLatex: false));
      }
    }

    return parts;
  }
}

class TextPart {
  final String content;
  final bool isLatex;

  TextPart(this.content, {required this.isLatex});
}
