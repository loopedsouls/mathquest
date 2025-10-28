import 'package:flutter/foundation.dart';

import '../screens/educational_content_arxiv_service_screen.dart';
import 'package:mathquest/services/ai_ollama_ai_service.dart';
import 'package:mathquest/services/ai_gemini_ai_service.dart';

class ExportService {
  static final OllamaService _ollamaService = OllamaService();
  static final GeminiService _geminiService = GeminiService();

  /// Define a chave da API do Gemini
  static void setGeminiApiKey(String apiKey) {
    _geminiService.setApiKey(apiKey);
  }

  /// Verifica se o Gemini está configurado
  static bool get hasGeminiConfigured => _geminiService.hasApiKey;

  /// Gera estado da arte usando IA com streaming - prioriza Gemini se configurado
  static Stream<String> generateAIStateOfArtStream(
      List<ArxivArticle> articles, String topic,
      {String? preferredService}) async* {
    try {
      // Determina qual serviço usar
      bool useGemini = false;

      if (preferredService == 'gemini' && _geminiService.hasApiKey) {
        useGemini = true;
      } else if (preferredService == 'ollama') {
        useGemini = false;
      } else {
        // Auto-detecta: prioriza Gemini se configurado
        if (_geminiService.hasApiKey) {
          final geminiWorking = await _geminiService.isGeminiWorking();
          useGemini = geminiWorking;
        }
      }

      if (useGemini) {
        // Tenta Gemini 2.0 Flash com fallback automático
        yield '🚀 Tentando gerar com Gemini 2.0 Flash...\n';

        try {
          await for (final chunk in _generateWithGemini(articles, topic)) {
            yield chunk;
          }
          return; // Sucesso com Gemini
        } catch (e) {
          if (e.toString().contains('Rate limit') ||
              e.toString().contains('429') ||
              e.toString().contains('quota') ||
              e.toString().contains('RATE_LIMIT_EXCEEDED')) {
            yield '\n⚠️ Gemini atingiu limite de taxa (rate limit). Alternando para Ollama...\n\n';
            yield '🔄 Configurando Ollama como fallback...\n';

            // Fallback automático para Ollama
            try {
              await for (final chunk in _generateWithOllama(articles, topic)) {
                yield chunk;
              }
              return;
            } catch (ollamaError) {
              yield '\n❌ Erro também com Ollama: $ollamaError\n';
              yield '\n📄 Gerando relatório básico...\n';
              yield _generateBasicStateOfArt(articles, topic);
              return;
            }
          } else {
            yield '\n❌ Erro com Gemini: $e\n';
            yield '🔄 Tentando com Ollama...\n\n';

            // Fallback para outros erros também
            try {
              await for (final chunk in _generateWithOllama(articles, topic)) {
                yield chunk;
              }
              return;
            } catch (ollamaError) {
              yield '\n❌ Erro também com Ollama: $ollamaError\n';
              yield '\n📄 Gerando relatório básico...\n';
              yield _generateBasicStateOfArt(articles, topic);
              return;
            }
          }
        }
      } else {
        // Usa Ollama diretamente
        try {
          await for (final chunk in _generateWithOllama(articles, topic)) {
            yield chunk;
          }
        } catch (e) {
          yield '\n❌ Erro com Ollama: $e\n';
          yield '\n📄 Gerando relatório básico...\n';
          yield _generateBasicStateOfArt(articles, topic);
        }
      }
    } catch (e) {
      yield '\n❌ Erro fatal: $e\n';
      yield '💡 Dica: Verifique se o Ollama está instalado ou a API key do Gemini está configurada.\n';
      yield '\n📄 Gerando relatório básico...\n';
      yield _generateBasicStateOfArt(articles, topic);
    }
  }

  /// Gera estado da arte usando Gemini
  static Stream<String> _generateWithGemini(
      List<ArxivArticle> articles, String topic) async* {
    try {
      yield '🔧 Configurando Gemini 2.0 Flash...\n';

      // Processa cada artigo
      List<String> processedTexts = [];

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        final articleTitle = article.title.length > 50
            ? "${article.title.substring(0, 50)}..."
            : article.title;

        yield '📄 Processando artigo ${i + 1}/${articles.length}: $articleTitle\n';

        try {
          final processed = await _geminiService.processArticle(article);
          processedTexts.add(processed);
        } catch (e) {
          yield '⚠️ Erro ao processar artigo: $e\n';
          // Fallback para o abstract original
          processedTexts.add('**RESUMO ORIGINAL:** ${article.summary}');
        }
      }

      // Gera síntese final com streaming
      yield* _geminiService.generateStateOfArtStreaming(processedTexts, topic);
    } catch (e) {
      yield '\n❌ Erro ao gerar estado da arte com Gemini: $e\n';
      rethrow;
    }
  }

  /// Gera estado da arte usando Ollama
  static Stream<String> _generateWithOllama(
      List<ArxivArticle> articles, String topic) async* {
    try {
      // 1. Verifica/instala Ollama se necessário
      yield '🔧 Configurando Ollama...\n';
      await _ollamaService.setupOllama();

      // 2. Processa cada artigo
      List<String> processedTexts = [];

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        final articleTitle = article.title.length > 50
            ? "${article.title.substring(0, 50)}..."
            : article.title;

        yield '📄 Processando artigo ${i + 1}/${articles.length}: $articleTitle\n';

        try {
          // Para PDFs do arXiv, usamos o abstract expandido
          String fullText = '''
Título: ${article.title}
Autores: ${article.authors}
Data: ${article.published.year}
Categorias: ${article.categories.join(', ')}
Resumo: ${article.summary}
''';

          // Gera resumo estruturado com Ollama
          yield '🤖 Analisando com IA...\n';
          final summary = await _ollamaService.generateSummary(fullText);
          processedTexts.add(summary);
        } catch (e) {
          yield '⚠️ Erro ao processar artigo: $e\n';
          // Fallback para o abstract original
          processedTexts.add('**RESUMO ORIGINAL:** ${article.summary}');
        }
      }

      // 3. Gera síntese final
      yield '🔄 Gerando síntese final...\n';

      // Stream da resposta do Ollama token por token
      await for (String token in _ollamaService.generateStateOfArtStreaming(
          processedTexts, topic)) {
        yield token;
      }
    } catch (e) {
      yield '\n❌ Erro ao gerar estado da arte com Ollama: $e\n';
      rethrow;
    }
  }

  /// Método de fallback básico
  static String _generateBasicStateOfArt(
      List<ArxivArticle> articles, String topic) {
    final buffer = StringBuffer();

    buffer.writeln('# ESTADO DA ARTE: $topic');
    buffer.writeln('*Gerado automaticamente pelo MathStateArt*\n');

    // Estatísticas gerais
    final totalArticles = articles.length;
    final uniqueAuthors = articles
        .map((a) => a.authors.split(', '))
        .expand((x) => x)
        .toSet()
        .length;

    buffer.writeln('## VISÃO GERAL');
    buffer.writeln('- **Total de artigos analisados:** $totalArticles');
    buffer.writeln('- **Autores únicos:** $uniqueAuthors');
    buffer.writeln();

    // Lista os artigos
    buffer.writeln('## ARTIGOS ANALISADOS');
    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];
      buffer.writeln('${i + 1}. **${article.title}**');
      buffer.writeln('   - Autores: ${article.authors}');
      buffer.writeln('   - Ano: ${article.published.year}');
      buffer.writeln('   - Categorias: ${article.categories.join(', ')}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Gera estado da arte usando análise de PDFs com Ollama
  static Future<String> generateAIStateOfArt(
      List<ArxivArticle> articles, String topic) async {
    try {
      // 1. Verifica/instala Ollama se necessário
      if (kDebugMode) {
        print('🔧 Configurando Ollama...');
      }
      await _ollamaService.setupOllama();

      // 2. Processa cada artigo
      List<String> processedTexts = [];

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        if (kDebugMode) {
          print(
              '📄 Processando artigo ${i + 1}/${articles.length}: ${article.title.length > 50 ? "${article.title.substring(0, 50)}..." : article.title}');
        }

        try {
          // Para PDFs do arXiv, usamos o abstract expandido
          // Em produção, aqui baixaríamos e extrairíamos o texto completo do PDF
          String fullText = '''
Título: ${article.title}
Autores: ${article.authors}
Data: ${article.published.year}
Categorias: ${article.categories.join(', ')}
Resumo: ${article.summary}
''';

          // Gera resumo estruturado com Ollama
          final summary = await _ollamaService.generateSummary(fullText);
          processedTexts.add(summary);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Erro ao processar artigo: $e');
          }
          // Fallback para o abstract original
          processedTexts.add('**RESUMO ORIGINAL:** ${article.summary}');
        }
      }

      // 3. Gera estado da arte consolidado
      if (kDebugMode) {
        print('🧠 Gerando estado da arte consolidado...');
      }
      final stateOfArt =
          await _ollamaService.generateStateOfArt(processedTexts, topic);

      return stateOfArt;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar estado da arte com IA: $e');
      }
      // Fallback para método tradicional
      return generateTraditionalStateOfArt(articles, topic);
    }
  }

  /// Gera estado da arte com streaming token por token
  static Stream<String> generateAIStateOfArtStreaming(
      List<ArxivArticle> articles, String topic) async* {
    try {
      // 1. Verifica/instala Ollama se necessário
      if (kDebugMode) {
        print('🔧 Configurando Ollama...');
      }
      yield '🔧 Configurando Ollama...\n\n';
      await _ollamaService.setupOllama();

      // 2. Processa cada artigo
      List<String> processedTexts = [];

      for (int i = 0; i < articles.length; i++) {
        final article = articles[i];
        final articleTitle = article.title.length > 50
            ? "${article.title.substring(0, 50)}..."
            : article.title;

        if (kDebugMode) {
          print(
              '📄 Processando artigo ${i + 1}/${articles.length}: $articleTitle');
        }
        yield '📄 Processando artigo ${i + 1}/${articles.length}: $articleTitle\n';

        try {
          // Para PDFs do arXiv, usamos o abstract expandido
          String fullText = '''
Título: ${article.title}
Autores: ${article.authors}
Data: ${article.published.year}
Categorias: ${article.categories.join(', ')}
Resumo: ${article.summary}
''';

          // Gera resumo estruturado com Ollama
          final summary = await _ollamaService.generateSummary(fullText);
          processedTexts.add(summary);
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Erro ao processar artigo: $e');
          }
          yield '⚠️ Erro ao processar artigo: $e\n';
          // Fallback para o abstract original
          processedTexts.add('**RESUMO ORIGINAL:** ${article.summary}');
        }
      }

      // 3. Gera estado da arte consolidado com streaming
      if (kDebugMode) {
        print('🧠 Gerando estado da arte consolidado...');
      }
      yield '\n🧠 Gerando estado da arte consolidado...\n\n';

      // Usa o método de streaming do Ollama
      await for (final token in _ollamaService.generateStateOfArtStreaming(
          processedTexts, topic)) {
        yield token;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao gerar estado da arte com IA: $e');
      }
      yield '\n❌ Erro ao gerar estado da arte com IA: $e\n';
      yield '\n📝 Gerando relatório tradicional como fallback...\n\n';
      yield generateTraditionalStateOfArt(articles, topic);
    }
  }

  /// Método tradicional sem IA (backup)
  static String generateTraditionalStateOfArt(
      List<ArxivArticle> articles, String topic) {
    final buffer = StringBuffer();

    buffer.writeln('# ESTADO DA ARTE: $topic');
    buffer.writeln('*Gerado automaticamente pelo MathStateArt*\n');

    // Estatísticas gerais
    final totalArticles = articles.length;
    final uniqueAuthors = articles
        .map((a) => a.authors.split(', '))
        .expand((x) => x)
        .toSet()
        .length;
    final dateRange = _getDateRange(articles);
    final categories = _getCategoryStats(articles);

    buffer.writeln('## VISÃO GERAL');
    buffer.writeln('- **Total de artigos analisados:** $totalArticles');
    buffer.writeln('- **Período coberto:** $dateRange');
    buffer.writeln('- **Autores únicos:** $uniqueAuthors');
    buffer.writeln(
        '- **Principais categorias:** ${categories.entries.take(5).map((e) => '${e.key} (${e.value})').join(', ')}');
    buffer.writeln();

    // Artigos por ano
    buffer.writeln('## DISTRIBUIÇÃO TEMPORAL');
    final yearStats = _getYearStats(articles);
    for (var entry in yearStats.entries) {
      buffer.writeln('- **${entry.key}:** ${entry.value} artigos');
    }
    buffer.writeln();

    // Principais autores
    buffer.writeln('## PESQUISADORES DESTACADOS');
    final authorStats = _getAuthorStats(articles);
    for (var entry in authorStats.entries.take(10)) {
      buffer.writeln('- **${entry.key}:** ${entry.value} publicações');
    }
    buffer.writeln();

    return buffer.toString();
  }

  /// Gera referências em formato BibTeX para uma lista de artigos
  static String generateBibTeX(List<ArxivArticle> articles) {
    final buffer = StringBuffer();

    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];
      final key = _generateBibKey(article, i);

      buffer.writeln('@article{$key,');
      buffer.writeln('  title = {${_escapeBibTeX(article.title)}},');
      buffer
          .writeln('  author = {${_formatAuthorsForBibTeX(article.authors)}},');
      buffer.writeln('  journal = {arXiv preprint},');
      buffer.writeln('  year = {${article.published.year}},');
      buffer.writeln('  month = {${article.published.month}},');
      buffer.writeln('  url = {${article.link}},');
      buffer.writeln('  archivePrefix = {arXiv},');
      buffer.writeln('  eprint = {${_extractArxivId(article.id)}},');
      buffer.writeln(
          '  primaryClass = {${article.categories.isNotEmpty ? article.categories.first : 'math'}},');
      buffer.writeln('  abstract = {${_escapeBibTeX(article.summary)}},');
      buffer.writeln('  note = {Categories: ${article.categories.join(', ')}}');
      buffer.writeln('}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Gera documento LaTeX com estado da arte estruturado
  static String generateStateOfArtLatex(
      List<ArxivArticle> articles, String topic) {
    final buffer = StringBuffer();

    // Cabeçalho LaTeX
    buffer.writeln(r'\documentclass[12pt,a4paper]{article}');
    buffer.writeln(r'\usepackage[utf8]{inputenc}');
    buffer.writeln(r'\usepackage[brazilian]{babel}');
    buffer.writeln(r'\usepackage{geometry}');
    buffer.writeln(r'\usepackage{cite}');
    buffer.writeln(r'\usepackage{url}');
    buffer.writeln(r'\geometry{margin=2.5cm}');
    buffer.writeln();
    buffer.writeln(r'\title{Estado da Arte: ${_escapeLatex(topic)}}');
    buffer.writeln(r'\author{MathStateArt - Gerado Automaticamente}');
    buffer.writeln(r'\date{\today}');
    buffer.writeln();
    buffer.writeln(r'\begin{document}');
    buffer.writeln(r'\maketitle');
    buffer.writeln();

    // Resumo executivo
    buffer.writeln(r'\section{Resumo Executivo}');
    buffer.writeln(
        'Este documento apresenta um estado da arte sobre ${_escapeLatex(topic)}, ');
    buffer.writeln(
        'baseado em ${articles.length} artigos científicos do repositório arXiv. ');
    buffer.writeln(
        'A análise foi realizada automaticamente pelo sistema MathStateArt.');
    buffer.writeln();

    // Estatísticas gerais
    final years = articles.map((a) => a.published.year).toSet().toList()
      ..sort();
    final categories = <String, int>{};
    for (var article in articles) {
      for (var cat in article.categories) {
        categories[cat] = (categories[cat] ?? 0) + 1;
      }
    }

    buffer.writeln(r'\section{Análise Quantitativa}');
    buffer.writeln(r'\begin{itemize}');
    buffer.writeln('  \\item Total de artigos analisados: ${articles.length}');
    buffer.writeln('  \\item Período coberto: ${years.first} - ${years.last}');
    buffer.writeln(
        '  \\item Principais categorias: ${categories.entries.take(5).map((e) => "${e.key} (${e.value})").join(", ")}');
    buffer.writeln(r'\end{itemize}');
    buffer.writeln();

    // Análise por categorias
    buffer.writeln(r'\section{Análise por Tópicos}');

    final topicGroups = <String, List<ArxivArticle>>{};
    for (var article in articles) {
      for (var category in article.categories) {
        topicGroups.putIfAbsent(category, () => []).add(article);
      }
    }

    for (var entry in topicGroups.entries.take(5)) {
      final category = entry.key;
      final categoryArticles = entry.value;

      buffer.writeln('\\subsection{${_escapeLatex(category)}}');
      buffer.writeln('Total de artigos: ${categoryArticles.length}');
      buffer.writeln();

      // Principais trabalhos desta categoria
      for (var article in categoryArticles.take(3)) {
        buffer.writeln('\\paragraph{${_escapeLatex(article.title)}}');
        buffer.writeln('\\textbf{Autores:} ${_escapeLatex(article.authors)}');
        buffer.writeln();
        buffer.writeln(
            '\\textbf{Resumo:} ${_escapeLatex(article.summary.length > 300 ? "${article.summary.substring(0, 300)}..." : article.summary)}');
        buffer.writeln();
        buffer.writeln('\\textbf{Link:} \\url{${article.link}}');
        buffer.writeln();
      }
    }

    // Tendências temporais
    buffer.writeln(r'\section{Tendências Temporais}');
    final yearlyCount = <int, int>{};
    for (var article in articles) {
      yearlyCount[article.published.year] =
          (yearlyCount[article.published.year] ?? 0) + 1;
    }

    buffer.writeln(r'\begin{itemize}');
    for (var entry in yearlyCount.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key))) {
      buffer.writeln('  \\item ${entry.key}: ${entry.value} artigos');
    }
    buffer.writeln(r'\end{itemize}');
    buffer.writeln();

    // Bibliografia
    buffer.writeln(r'\section{Referências}');
    buffer.writeln(r'\begin{thebibliography}{99}');

    for (int i = 0; i < articles.length; i++) {
      final article = articles[i];
      buffer.writeln('\\bibitem{${_generateBibKey(article, i)}}');
      buffer.writeln('${_escapeLatex(article.authors)}.');
      buffer.writeln('\\textit{${_escapeLatex(article.title)}}.');
      buffer.writeln(
          'arXiv preprint ${_extractArxivId(article.id)} (${article.published.year}).');
      buffer.writeln('\\url{${article.link}}');
      buffer.writeln();
    }

    buffer.writeln(r'\end{thebibliography}');
    buffer.writeln();
    buffer.writeln(r'\end{document}');

    return buffer.toString();
  }

  /// Gera relatório estruturado em formato texto
  static String generateStructuredReport(
      List<ArxivArticle> articles, String topic) {
    final buffer = StringBuffer();

    buffer.writeln('ESTADO DA ARTE: ${topic.toUpperCase()}');
    buffer.writeln('=' * 60);
    buffer.writeln('Gerado automaticamente pelo MathStateArt');
    buffer
        .writeln('Data: ${DateTime.now().toLocal().toString().split(' ')[0]}');
    buffer.writeln();

    // 1. Objetivo
    buffer.writeln('1. OBJETIVO');
    buffer.writeln('-' * 20);
    buffer.writeln(
        'Esta análise tem como objetivo mapear o estado atual da pesquisa em');
    buffer.writeln(
        '$topic, identificando principais tendências, metodologias e resultados');
    buffer.writeln(
        'relevantes baseados em ${articles.length} artigos recentes do arXiv.');
    buffer.writeln();

    // 2. Método
    buffer.writeln('2. METODOLOGIA');
    buffer.writeln('-' * 20);
    buffer.writeln('• Fonte: Repositório arXiv (export.arxiv.org)');
    buffer.writeln('• Termo de busca: "$topic"');
    buffer.writeln(
        '• Período: ${articles.map((a) => a.published.year).reduce((a, b) => a < b ? a : b)} - ${articles.map((a) => a.published.year).reduce((a, b) => a > b ? a : b)}');
    buffer.writeln(
        '• Critérios: Relevância por palavra-chave e data de publicação');
    buffer.writeln(
        '• Processamento: Agrupamento automático por categorias do arXiv');
    buffer.writeln();

    // 3. Resultados
    buffer.writeln('3. PRINCIPAIS RESULTADOS');
    buffer.writeln('-' * 20);

    // Análise temporal
    final yearlyCount = <int, int>{};
    for (var article in articles) {
      yearlyCount[article.published.year] =
          (yearlyCount[article.published.year] ?? 0) + 1;
    }

    buffer.writeln('3.1 Evolução Temporal:');
    for (var entry in yearlyCount.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key))) {
      buffer.writeln('   • ${entry.key}: ${entry.value} publicações');
    }
    buffer.writeln();

    // Análise por categorias
    final categories = <String, int>{};
    for (var article in articles) {
      for (var cat in article.categories) {
        categories[cat] = (categories[cat] ?? 0) + 1;
      }
    }

    buffer.writeln('3.2 Principais Áreas de Concentração:');
    var sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sortedCategories.take(5)) {
      buffer.writeln(
          '   • ${entry.key}: ${entry.value} artigos (${(entry.value / articles.length * 100).toStringAsFixed(1)}%)');
    }
    buffer.writeln();

    // Principais autores
    final authors = <String, int>{};
    for (var article in articles) {
      for (var author in article.authors.split(', ')) {
        if (author.trim().isNotEmpty) {
          authors[author.trim()] = (authors[author.trim()] ?? 0) + 1;
        }
      }
    }

    buffer.writeln('3.3 Principais Pesquisadores:');
    var sortedAuthors = authors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var entry in sortedAuthors.take(5)) {
      buffer.writeln('   • ${entry.key}: ${entry.value} publicações');
    }
    buffer.writeln();

    // 4. Implicações
    buffer.writeln('4. IMPLICAÇÕES E TENDÊNCIAS');
    buffer.writeln('-' * 20);

    final recentArticles = articles
        .where((a) => DateTime.now().difference(a.published).inDays <= 365)
        .length;

    buffer.writeln(
        '• Atividade recente: $recentArticles artigos publicados no último ano');
    buffer.writeln('• Área mais ativa: ${sortedCategories.first.key}');
    buffer.writeln('• Tendência de crescimento: ${_analyzeTrend(yearlyCount)}');
    buffer.writeln(
        '• Diversificação: ${categories.length} subcategorias identificadas');
    buffer.writeln();

    // Lista de artigos mais relevantes
    buffer.writeln('5. ARTIGOS MAIS RELEVANTES');
    buffer.writeln('-' * 20);

    final recentSortedArticles = articles.toList()
      ..sort((a, b) => b.published.compareTo(a.published));

    for (int i = 0; i < recentSortedArticles.take(10).length; i++) {
      final article = recentSortedArticles[i];
      buffer.writeln('[${i + 1}] ${article.title}');
      buffer.writeln('    Autores: ${article.authors}');
      buffer.writeln(
          '    Data: ${article.published.toLocal().toString().split(' ')[0]}');
      buffer.writeln('    Categorias: ${article.categories.join(', ')}');
      buffer.writeln('    Link: ${article.link}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Métodos auxiliares
  static String _generateBibKey(ArxivArticle article, int index) {
    final firstAuthor = article.authors
        .split(',')
        .first
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toLowerCase();
    return '$firstAuthor${article.published.year}_$index';
  }

  static String _escapeBibTeX(String text) {
    return text
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('&', '\\&')
        .replaceAll('%', '\\%')
        .replaceAll('\$', '\\\$')
        .replaceAll('#', '\\#')
        .replaceAll('^', '\\textasciicircum{}')
        .replaceAll('_', '\\_');
  }

  static String _escapeLatex(String text) {
    return text
        .replaceAll('\\', '\\textbackslash{}')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('&', '\\&')
        .replaceAll('%', '\\%')
        .replaceAll('\$', '\\\$')
        .replaceAll('#', '\\#')
        .replaceAll('^', '\\textasciicircum{}')
        .replaceAll('_', '\\_')
        .replaceAll('~', '\\textasciitilde{}');
  }

  static String _formatAuthorsForBibTeX(String authors) {
    return authors.split(', ').map((author) => author.trim()).join(' and ');
  }

  static String _extractArxivId(String fullId) {
    // Extrai apenas o ID do arXiv da URL completa
    final parts = fullId.split('/');
    return parts.last;
  }

  static String _analyzeTrend(Map<int, int> yearlyCount) {
    if (yearlyCount.length < 2) return 'Dados insuficientes';

    final years = yearlyCount.keys.toList()..sort();
    final recent = yearlyCount[years.last] ?? 0;
    final previous = yearlyCount[years[years.length - 2]] ?? 0;

    if (recent > previous * 1.2) return 'Crescimento acelerado';
    if (recent > previous) return 'Crescimento moderado';
    if (recent < previous * 0.8) return 'Declínio';
    return 'Estável';
  }

  // Funções auxiliares para análise estatística
  static String _getDateRange(List<ArxivArticle> articles) {
    if (articles.isEmpty) return 'N/A';

    final dates = articles.map((a) => a.published).toList()..sort();
    final start = dates.first;
    final end = dates.last;

    return '${start.year}-${start.month.toString().padLeft(2, '0')} a ${end.year}-${end.month.toString().padLeft(2, '0')}';
  }

  static Map<String, int> _getCategoryStats(List<ArxivArticle> articles) {
    final categories = <String, int>{};
    for (var article in articles) {
      for (var cat in article.categories) {
        categories[cat] = (categories[cat] ?? 0) + 1;
      }
    }
    return Map.fromEntries(categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
  }

  static Map<int, int> _getYearStats(List<ArxivArticle> articles) {
    final years = <int, int>{};
    for (var article in articles) {
      years[article.published.year] = (years[article.published.year] ?? 0) + 1;
    }
    return Map.fromEntries(
        years.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  static Map<String, int> _getAuthorStats(List<ArxivArticle> articles) {
    final authors = <String, int>{};
    for (var article in articles) {
      for (var author in article.authors.split(', ')) {
        if (author.trim().isNotEmpty) {
          authors[author.trim()] = (authors[author.trim()] ?? 0) + 1;
        }
      }
    }
    return Map.fromEntries(
        authors.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}
