import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'arxiv_service.dart';

class SavedArticlesService {
  static const String _savedArticlesKey = 'saved_articles';

  Future<void> init() async {
    // Initialize SharedPreferences if needed
    await SharedPreferences.getInstance();
  }

  Future<List<ArxivArticle>> getSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getStringList(_savedArticlesKey) ?? [];

    return savedJson.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return ArxivArticle(
        id: data['id'] ?? '',
        title: data['title'] ?? '',
        summary: data['summary'] ?? '',
        authors: data['authors'] ?? '',
        link: data['link'] ?? '',
        published: DateTime.tryParse(data['published'] ?? '') ?? DateTime.now(),
        categories: List<String>.from(data['categories'] ?? []),
      );
    }).toList();
  }

  Future<void> saveArticle(ArxivArticle article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticles = await getSavedArticles();

    // Check if already saved
    final alreadySaved = savedArticles.any((saved) => saved.id == article.id);
    if (alreadySaved) return;

    savedArticles.add(article);

    final savedJson = savedArticles.map((article) {
      return jsonEncode({
        'id': article.id,
        'title': article.title,
        'summary': article.summary,
        'authors': article.authors,
        'link': article.link,
        'published': article.published.toIso8601String(),
        'categories': article.categories,
      });
    }).toList();

    await prefs.setStringList(_savedArticlesKey, savedJson);
  }

  Future<void> removeArticle(ArxivArticle article) async {
    final prefs = await SharedPreferences.getInstance();
    final savedArticles = await getSavedArticles();

    savedArticles.removeWhere((saved) => saved.id == article.id);

    final savedJson = savedArticles.map((article) {
      return jsonEncode({
        'id': article.id,
        'title': article.title,
        'summary': article.summary,
        'authors': article.authors,
        'link': article.link,
        'published': article.published.toIso8601String(),
        'categories': article.categories,
      });
    }).toList();

    await prefs.setStringList(_savedArticlesKey, savedJson);
  }

  Future<bool> isArticleSaved(ArxivArticle article) async {
    final savedArticles = await getSavedArticles();
    return savedArticles.any((saved) => saved.id == article.id);
  }
}
