import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ArxivArticle {
  final String id;
  final String title;
  final String summary;
  final String authors;
  final String link;
  final DateTime published;
  final List<String> categories;

  ArxivArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.authors,
    required this.link,
    required this.published,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'authors': authors,
        'link': link,
        'published': published.toIso8601String(),
        'categories': categories,
      };

  factory ArxivArticle.fromJson(Map<String, dynamic> json) => ArxivArticle(
        id: json['id'],
        title: json['title'],
        summary: json['summary'],
        authors: json['authors'],
        link: json['link'],
        published: DateTime.parse(json['published']),
        categories: List<String>.from(json['categories']),
      );
}

class ArxivService {
  static const String _baseUrl = 'http://export.arxiv.org/api/query';

  ArxivService() {
    // Configurar para aceitar certificados SSL não verificados
    HttpOverrides.global = _MyHttpOverrides();
  }

  Future<List<ArxivArticle>> searchArticles(String query,
      {int maxResults = 20}) async {
    try {
      final url =
          '$_baseUrl?search_query=all:${Uri.encodeComponent(query)}&start=0&max_results=$maxResults&sortBy=submittedDate&sortOrder=descending';

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MathStateArt/1.0',
          'Accept': 'application/atom+xml',
        },
      ).timeout(const Duration(seconds: 30));

      client.close();

      if (response.statusCode == 200) {
        final xmlDoc = XmlDocument.parse(response.body);
        final entries = xmlDoc.findAllElements('entry');
        return entries.map((entry) {
          final title = entry
                  .getElement('title')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final summary = entry
                  .getElement('summary')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final authors = entry
              .findElements('author')
              .map((a) => a.getElement('name')!.value?.trim() ?? '')
              .join(', ');
          final id = entry.getElement('id')!.value?.trim() ?? '';
          final pdfLink = entry
                  .findElements('link')
                  .firstWhere(
                    (l) => l.getAttribute('title') == 'pdf',
                    orElse: () => entry.findElements('link').first,
                  )
                  .getAttribute('href') ??
              id;

          // Parse published date
          final publishedStr =
              entry.getElement('published')!.value?.trim() ?? '';
          DateTime published;
          try {
            published = DateTime.parse(publishedStr);
          } catch (e) {
            published = DateTime.now();
          }

          // Parse categories
          final categories = entry
              .findElements('category')
              .map((cat) => cat.getAttribute('term') ?? '')
              .where((term) => term.isNotEmpty)
              .toList();

          return ArxivArticle(
            id: id,
            title: title,
            summary: summary,
            authors: authors,
            link: pdfLink,
            published: published,
            categories: categories,
          );
        }).toList();
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na busca: $e');
      }
      return [];
    }
  }

  Future<List<ArxivArticle>> getRecentArticles({int maxResults = 10}) async {
    try {
      final url =
          '$_baseUrl?search_query=cat:math*&start=0&max_results=$maxResults&sortBy=submittedDate&sortOrder=descending';

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MathStateArt/1.0',
          'Accept': 'application/atom+xml',
        },
      ).timeout(const Duration(seconds: 30));

      client.close();

      if (response.statusCode == 200) {
        final xmlDoc = XmlDocument.parse(response.body);
        final entries = xmlDoc.findAllElements('entry');
        return entries.map((entry) {
          final title = entry
                  .getElement('title')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final summary = entry
                  .getElement('summary')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final authors = entry
              .findElements('author')
              .map((a) => a.getElement('name')!.value?.trim() ?? '')
              .join(', ');
          final id = entry.getElement('id')!.value?.trim() ?? '';
          final pdfLink = entry
                  .findElements('link')
                  .firstWhere(
                    (l) => l.getAttribute('title') == 'pdf',
                    orElse: () => entry.findElements('link').first,
                  )
                  .getAttribute('href') ??
              id;

          // Parse published date
          final publishedStr =
              entry.getElement('published')!.value?.trim() ?? '';
          DateTime published;
          try {
            published = DateTime.parse(publishedStr);
          } catch (e) {
            published = DateTime.now();
          }

          // Parse categories
          final categories = entry
              .findElements('category')
              .map((cat) => cat.getAttribute('term') ?? '')
              .where((term) => term.isNotEmpty)
              .toList();

          return ArxivArticle(
            id: id,
            title: title,
            summary: summary,
            authors: authors,
            link: pdfLink,
            published: published,
            categories: categories,
          );
        }).toList();
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar artigos recentes: $e');
      }
      return [];
    }
  }

  /// Busca artigos com filtros avançados
  Future<List<ArxivArticle>> searchArticlesAdvanced({
    required String query,
    int maxResults = 20,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    String sortBy =
        'submittedDate', // submittedDate, lastUpdatedDate, relevance
    String sortOrder = 'descending', // ascending, descending
  }) async {
    try {
      String searchQuery = 'all:${Uri.encodeComponent(query)}';

      // Adicionar filtros de categoria se especificados
      if (categories != null && categories.isNotEmpty) {
        final categoryFilter = categories.map((cat) => 'cat:$cat').join(' OR ');
        searchQuery += ' AND ($categoryFilter)';
      }

      final url =
          '$_baseUrl?search_query=$searchQuery&start=0&max_results=$maxResults&sortBy=$sortBy&sortOrder=$sortOrder';

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MathStateArt/1.0',
          'Accept': 'application/atom+xml',
        },
      ).timeout(const Duration(seconds: 30));

      client.close();

      if (response.statusCode == 200) {
        final xmlDoc = XmlDocument.parse(response.body);
        final entries = xmlDoc.findAllElements('entry');

        List<ArxivArticle> articles = entries.map((entry) {
          final title = entry
                  .getElement('title')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final summary = entry
                  .getElement('summary')!
                  .value
                  ?.trim()
                  .replaceAll('\n', ' ')
                  .replaceAll(RegExp(r'\s+'), ' ') ??
              '';
          final authors = entry
              .findElements('author')
              .map((a) => a.getElement('name')!.value?.trim() ?? '')
              .join(', ');
          final id = entry.getElement('id')!.value?.trim() ?? '';
          final pdfLink = entry
                  .findElements('link')
                  .firstWhere(
                    (l) => l.getAttribute('title') == 'pdf',
                    orElse: () => entry.findElements('link').first,
                  )
                  .getAttribute('href') ??
              id;

          // Parse published date
          final publishedStr =
              entry.getElement('published')!.value?.trim() ?? '';
          DateTime published;
          try {
            published = DateTime.parse(publishedStr);
          } catch (e) {
            published = DateTime.now();
          }

          // Parse categories
          final articleCategories = entry
              .findElements('category')
              .map((cat) => cat.getAttribute('term') ?? '')
              .where((term) => term.isNotEmpty)
              .toList();

          return ArxivArticle(
            id: id,
            title: title,
            summary: summary,
            authors: authors,
            link: pdfLink,
            published: published,
            categories: articleCategories,
          );
        }).toList();

        // Aplicar filtros de data se especificados
        if (startDate != null || endDate != null) {
          articles = articles.where((article) {
            if (startDate != null && article.published.isBefore(startDate)) {
              return false;
            }
            if (endDate != null && article.published.isAfter(endDate)) {
              return false;
            }
            return true;
          }).toList();
        }

        return articles;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar artigos avançados: $e');
      }
      return [];
    }
  }

  /// Busca artigos por área específica do arXiv
  Future<List<ArxivArticle>> searchByMathCategory(String category,
      {int maxResults = 20}) async {
    // Categorias matemáticas principais do arXiv
    const Map<String, String> mathCategories = {
      'algebra': 'math.AC OR math.AG OR math.AT OR math.CT OR math.RA',
      'analysis': 'math.AP OR math.CA OR math.CV OR math.FA OR math.OA',
      'geometry': 'math.AG OR math.DG OR math.GN OR math.GT OR math.MG',
      'topology': 'math.AT OR math.GT OR math.GN',
      'number_theory': 'math.NT',
      'logic': 'math.LO',
      'combinatorics': 'math.CO',
      'probability': 'math.PR OR math.ST',
      'statistics': 'math.ST',
      'optimization': 'math.OC',
      'numerical_analysis': 'math.NA',
      'dynamical_systems': 'math.DS',
    };

    final searchCategories =
        mathCategories[category.toLowerCase()] ?? 'math.$category';

    try {
      final url =
          '$_baseUrl?search_query=cat:($searchCategories)&start=0&max_results=$maxResults&sortBy=submittedDate&sortOrder=descending';

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MathStateArt/1.0',
          'Accept': 'application/atom+xml',
        },
      ).timeout(const Duration(seconds: 30));

      client.close();

      return _parseArxivResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar por categoria: $e');
      }
      return [];
    }
  }

  /// Busca artigos de um autor específico
  Future<List<ArxivArticle>> searchByAuthor(String authorName,
      {int maxResults = 20}) async {
    try {
      final url =
          '$_baseUrl?search_query=au:"${Uri.encodeComponent(authorName)}"&start=0&max_results=$maxResults&sortBy=submittedDate&sortOrder=descending';

      final client = http.Client();
      final response = await client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'MathStateArt/1.0',
          'Accept': 'application/atom+xml',
        },
      ).timeout(const Duration(seconds: 30));

      client.close();

      return _parseArxivResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar por autor: $e');
      }
      return [];
    }
  }

  /// Busca tendências dos últimos N meses
  Future<Map<String, List<ArxivArticle>>> getTrendAnalysis({
    required String query,
    int months = 12,
    int maxResults = 100,
  }) async {
    final endDate = DateTime.now();
    final startDate =
        DateTime(endDate.year, endDate.month - months, endDate.day);

    final articles = await searchArticlesAdvanced(
      query: query,
      startDate: startDate,
      endDate: endDate,
      maxResults: maxResults,
    );

    // Agrupar por mês
    final Map<String, List<ArxivArticle>> monthlyTrends = {};

    for (var article in articles) {
      final monthKey =
          '${article.published.year}-${article.published.month.toString().padLeft(2, '0')}';
      monthlyTrends.putIfAbsent(monthKey, () => []).add(article);
    }

    return monthlyTrends;
  }

  /// Método auxiliar para parsear resposta do arXiv
  List<ArxivArticle> _parseArxivResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(
          'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }

    final xmlDoc = XmlDocument.parse(response.body);
    final entries = xmlDoc.findAllElements('entry');

    return entries.map((entry) {
      final title = entry
              .getElement('title')!
              .value
              ?.trim()
              .replaceAll('\n', ' ')
              .replaceAll(RegExp(r'\s+'), ' ') ??
          '';
      final summary = entry
              .getElement('summary')!
              .value
              ?.trim()
              .replaceAll('\n', ' ')
              .replaceAll(RegExp(r'\s+'), ' ') ??
          '';
      final authors = entry
          .findElements('author')
          .map((a) => a.getElement('name')!.value?.trim() ?? '')
          .join(', ');
      final id = entry.getElement('id')!.value?.trim() ?? '';
      final pdfLink = entry
              .findElements('link')
              .firstWhere(
                (l) => l.getAttribute('title') == 'pdf',
                orElse: () => entry.findElements('link').first,
              )
              .getAttribute('href') ??
          id;

      // Parse published date
      final publishedStr = entry.getElement('published')!.value?.trim() ?? '';
      DateTime published;
      try {
        published = DateTime.parse(publishedStr);
      } catch (e) {
        published = DateTime.now();
      }

      // Parse categories
      final categories = entry
          .findElements('category')
          .map((cat) => cat.getAttribute('term') ?? '')
          .where((term) => term.isNotEmpty)
          .toList();

      return ArxivArticle(
        id: id,
        title: title,
        summary: summary,
        authors: authors,
        link: pdfLink,
        published: published,
        categories: categories,
      );
    }).toList();
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
