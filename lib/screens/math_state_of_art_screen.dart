import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mathquest/screens/arxiv_service.dart';
import 'package:mathquest/screens/export_service.dart';
import 'package:mathquest/screens/saved_articles_service.dart';
import 'package:mathquest/screens/article_viewer.dart';
import 'package:mathquest/screens/math_topics.dart';

class MathStateOfArtPage extends StatefulWidget {
  const MathStateOfArtPage({super.key});

  @override
  State<MathStateOfArtPage> createState() => _MathStateOfArtPageState();
}

class _MathStateOfArtPageState extends State<MathStateOfArtPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _latexController = TextEditingController();
  final ArxivService _arxivService = ArxivService();
  final SavedArticlesService _savedService = SavedArticlesService();

  late TabController _tabController;

  List<ArxivArticle> _articles = [];
  List<ArxivArticle> _recentArticles = [];
  List<ArxivArticle> _savedArticles = [];
  Map<String, List<ArxivArticle>> _groupedByAuthor = {};
  Map<String, List<ArxivArticle>> _groupedByTopic = {};
  String? _summary;
  bool _loading = false;
  bool _loadingLatex = false;
  int _maxResults = 20;

  // Configurações de IA
  String _selectedAIService = 'auto'; // 'auto', 'gemini'
  final TextEditingController _geminiApiKeyController = TextEditingController();

  // Filtros avançados
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCategory = 'all';
  String _sortBy = 'submittedDate';
  final String _sortOrder = 'descending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Atualiza o estado quando a aba muda
    });
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _loadSavedArticles();
    _loadRecentArticles();
  }

  void _loadSavedArticles() async {
    final saved = await _savedService.getSavedArticles();
    setState(() {
      _savedArticles = saved;
    });
  }

  Future<void> _loadRecentArticles() async {
    setState(() {
      _loading = true;
    });
    try {
      final recent = await _arxivService.getRecentArticles(maxResults: 20);
      setState(() {
        _recentArticles = recent;
      });
    } catch (e) {
      debugPrint('Error loading recent articles: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveArticle(ArxivArticle article) async {
    await _savedService.saveArticle(article);
    _loadSavedArticles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artigo salvo!')),
      );
    }
  }

  Future<void> _removeSavedArticle(String id) async {
    final article = _savedArticles.firstWhere((a) => a.id == id);
    await _savedService.removeArticle(article);
    _loadSavedArticles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artigo removido!')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _latexController.dispose();
    super.dispose();
  }

  void _search() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _articles = [];
      _groupedByAuthor = {};
      _groupedByTopic = {};
      _summary = null;
    });

    try {
      List<ArxivArticle> results;

      if (_selectedCategory == 'all') {
        results = await _arxivService.searchArticlesAdvanced(
          query: _controller.text.trim(),
          maxResults: _maxResults,
          startDate: _startDate,
          endDate: _endDate,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
      } else {
        results = await _arxivService.searchByMathCategory(
          _selectedCategory,
          maxResults: _maxResults,
        );
        // Filtrar por termo de busca se especificado
        if (_controller.text.trim().isNotEmpty) {
          final searchTerm = _controller.text.trim().toLowerCase();
          results = results
              .where((article) =>
                  article.title.toLowerCase().contains(searchTerm) ||
                  article.summary.toLowerCase().contains(searchTerm) ||
                  article.authors.toLowerCase().contains(searchTerm))
              .toList();
        }
      }

      setState(() {
        _articles = results;
        _groupAuthorsByName();
        _groupArticlesByTopic();
        _generateSummary();
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _searchTopic(String topic) {
    _controller.text = topic;
    _search();
  }

  void _groupAuthorsByName() {
    _groupedByAuthor.clear();
    for (var article in _articles) {
      final authorList = article.authors.split(', ');
      for (var author in authorList) {
        if (author.trim().isNotEmpty) {
          _groupedByAuthor.putIfAbsent(author.trim(), () => []).add(article);
        }
      }
    }
  }

  void _groupArticlesByTopic() {
    _groupedByTopic.clear();
    for (var article in _articles) {
      for (var category in article.categories) {
        _groupedByTopic.putIfAbsent(category, () => []).add(article);
      }
    }
  }

  void _generateSummary() {
    if (_articles.isEmpty) return;

    final totalArticles = _articles.length;
    final uniqueAuthors = _groupedByAuthor.keys.length;
    final topics = _groupedByTopic.keys.toList();
    final recentArticles = _articles
        .where((a) => DateTime.now().difference(a.published).inDays <= 365)
        .length;

    _summary = '''
Resumo da Pesquisa:
• Total de artigos encontrados: $totalArticles
• Autores únicos: $uniqueAuthors
• Artigos recentes (último ano): $recentArticles
• Principais tópicos: ${topics.take(5).join(', ')}
• Período coberto: ${_articles.map((a) => a.published.year).reduce((a, b) => a < b ? a : b)} - ${_articles.map((a) => a.published.year).reduce((a, b) => a > b ? a : b)}
    ''';
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de busca principal
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ex: "topology", "algebra"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _loading ? null : _search,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? 'Pesquisando...' : 'Pesquisar'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Filtros avançados
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            // Categoria
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todas')),
                  DropdownMenuItem(value: 'algebra', child: Text('Álgebra')),
                  DropdownMenuItem(value: 'analysis', child: Text('Análise')),
                  DropdownMenuItem(value: 'geometry', child: Text('Geometria')),
                  DropdownMenuItem(value: 'topology', child: Text('Topologia')),
                  DropdownMenuItem(
                      value: 'number_theory',
                      child: Text('Teoria dos Números')),
                  DropdownMenuItem(
                      value: 'probability', child: Text('Probabilidade')),
                  DropdownMenuItem(value: 'logic', child: Text('Lógica')),
                  DropdownMenuItem(
                      value: 'combinatorics', child: Text('Combinatória')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),

            // Limite de resultados
            SizedBox(
              width: 150,
              child: DropdownButtonFormField<int>(
                initialValue: _maxResults,
                decoration: const InputDecoration(
                  labelText: 'Limite',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [5, 10, 20, 50, 100].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value artigos'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _maxResults = newValue;
                    });
                  }
                },
              ),
            ),

            // Ordenação
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Ordenar por',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'submittedDate', child: Text('Data de Submissão')),
                  DropdownMenuItem(
                      value: 'lastUpdatedDate',
                      child: Text('Última Atualização')),
                  DropdownMenuItem(
                      value: 'relevance', child: Text('Relevância')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
              ),
            ),

            // Data inicial
            SizedBox(
              width: 150,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ??
                        DateTime.now().subtract(const Duration(days: 365)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Inicial',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Selecionar',
                    style: TextStyle(
                      color:
                          _startDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Data final
            SizedBox(
              width: 150,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _endDate = date;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Final',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Selecionar',
                    style: TextStyle(
                      color: _endDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Botão limpar filtros
            if (_startDate != null ||
                _endDate != null ||
                _selectedCategory != 'all')
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                    _selectedCategory = 'all';
                    _sortBy = 'submittedDate';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpar Filtros'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildArticlesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão para voltar aos tópicos (mobile)
          if (_articles.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _articles.clear();
                    _summary = null;
                    _groupedByAuthor.clear();
                    _groupedByTopic.clear();
                    _controller.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar aos Tópicos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (_summary != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_summary!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de exportação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exportar Estado da Arte',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _exportBibTeX(),
                          icon: const Icon(Icons.book),
                          label: const Text('BibTeX'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _exportLatex(),
                          icon: const Icon(Icons.description),
                          label: const Text('LaTeX'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _exportStructuredReport(),
                          icon: const Icon(Icons.analytics),
                          label: const Text('Relatório Estruturado'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showTrendAnalysis(),
                          icon: const Icon(Icons.trending_up),
                          label: const Text('Análise de Tendências'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _generateAIStateOfArt(),
                          icon: const Icon(Icons.psychology),
                          label: const Text('Estado da Arte com IA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_articles.isEmpty && !_loading)
            MathTopics(onTopicSelected: _searchTopic)
          else
            Column(
              children: _articles.map((article) {
                final isSaved =
                    _savedArticles.any((saved) => saved.id == article.id);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleViewer(article: article),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  article.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color:
                                      isSaved ? const Color(0xFF1E3A8A) : null,
                                ),
                                onPressed: () {
                                  if (isSaved) {
                                    _removeSavedArticle(article.id);
                                  } else {
                                    _saveArticle(article);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Autores: ${article.authors}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Publicado: ${article.published.day}/${article.published.month}/${article.published.year}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            article.summary,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: article.categories
                                .take(5)
                                .map((cat) => Chip(
                                      label: Text(
                                        cat,
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor:
                                          const Color(0xFF1E3A8A).withAlpha(25),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorsTab() {
    if (_groupedByAuthor.isEmpty) {
      return const Center(
        child: Text('Faça uma pesquisa para ver os autores'),
      );
    }

    final sortedAuthors = _groupedByAuthor.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedAuthors.length,
      itemBuilder: (context, index) {
        final entry = sortedAuthors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E3A8A),
              child: Text(
                entry.key
                    .split(' ')
                    .map((n) => n.isNotEmpty ? n[0] : '')
                    .take(2)
                    .join(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} artigo(s)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Implementar visualização de artigos do autor
            },
          ),
        );
      },
    );
  }

  Widget _buildTopicsTab() {
    if (_groupedByTopic.isEmpty) {
      return const Center(
        child: Text('Faça uma pesquisa para ver os tópicos'),
      );
    }

    final sortedTopics = _groupedByTopic.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTopics.length,
      itemBuilder: (context, index) {
        final entry = sortedTopics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.category, color: Color(0xFF1E3A8A)),
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} artigo(s)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _searchTopic(entry.key);
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    if (_savedArticles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum artigo salvo ainda'),
            Text('Salve artigos para acessá-los facilmente'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedArticles.length,
      itemBuilder: (context, index) {
        final article = _savedArticles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleViewer(article: article),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          article.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bookmark,
                            color: Color(0xFF1E3A8A)),
                        onPressed: () => _removeSavedArticle(article.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Autores: ${article.authors}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Publicado: ${article.published.day}/${article.published.month}/${article.published.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTab() {
    if (_recentArticles.isEmpty && !_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Nenhum artigo recente carregado'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRecentArticles(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loading ? 5 : _recentArticles.length,
        itemBuilder: (context, index) {
          if (_loading) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 16, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(height: 16, color: Colors.grey[300]),
                  ],
                ),
              ),
            );
          }

          final article = _recentArticles[index];
          final isSaved = _savedArticles.any((saved) => saved.id == article.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleViewer(article: article),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            article.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? const Color(0xFF1E3A8A) : null,
                          ),
                          onPressed: () {
                            if (isSaved) {
                              _removeSavedArticle(article.id);
                            } else {
                              _saveArticle(article);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Autores: ${article.authors}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publicado: ${article.published.day}/${article.published.month}/${article.published.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: article.categories
                          .take(5)
                          .map((cat) => Chip(
                                label: Text(
                                  cat,
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: const Color(0xFF1E3A8A)
                                    .withValues(alpha: 0.1),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // NavigationRail à esquerda
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _tabController.index,
            onDestinationSelected: (index) {
              setState(() {
                _tabController.animateTo(index);
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: Text('Artigos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Autores'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Tópicos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: Text('Salvos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.feed_outlined),
                selectedIcon: Icon(Icons.feed),
                label: Text('Recentes'),
              ),
            ],
          ),
          // Conteúdo principal - lado esquerdo
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Título e área de busca no topo
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MathStateArt',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerador Automático de Estado da Arte em Matemática',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSearchSection(),
                    ],
                  ),
                ),
                // Conteúdo das abas
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
          // Divisor
          Container(
            width: 1,
            color: Colors.grey[300],
          ),
          // Editor LaTeX - lado direito
          Expanded(
            flex: 2,
            child: _buildLatexEditor(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Retorna o conteúdo baseado na aba selecionada
    switch (_tabController.index) {
      case 0:
        return _buildArticlesTab();
      case 1:
        return _buildAuthorsTab();
      case 2:
        return _buildTopicsTab();
      case 3:
        return _buildSavedTab();
      case 4:
        return _buildRecentTab();
      default:
        return _buildArticlesTab();
    }
  }

  // Métodos de exportação
  void _exportBibTeX() {
    if (_articles.isEmpty) return;

    final bibTeX = ExportService.generateBibTeX(_articles);
    _showExportDialog('Referências BibTeX', bibTeX, 'bibliografia.bib');
  }

  void _exportLatex() {
    if (_articles.isEmpty) return;

    final latex = ExportService.generateStateOfArtLatex(
        _articles, _controller.text.trim());
    _showExportDialog('Documento LaTeX', latex, 'estado_da_arte.tex');
  }

  void _exportStructuredReport() {
    if (_articles.isEmpty) return;

    final report = ExportService.generateStructuredReport(
        _articles, _controller.text.trim());
    _showExportDialog(
        'Relatório Estruturado', report, 'relatorio_estado_da_arte.txt');
  }

  void _generateAIStateOfArt() async {
    if (_articles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhum artigo encontrado para processar')),
        );
      }
      return;
    }

    // Mostra dialog com streaming do texto
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _StreamingStateOfArtDialog(
        articles: _articles,
        topic: _controller.text.trim().isEmpty
            ? 'Pesquisa Matemática'
            : _controller.text.trim(),
      ),
    );
  }

  Future<void> _showTrendAnalysis() async {
    if (_controller.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Digite um termo de busca para análise de tendências')),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Analisando tendências...'),
          ],
        ),
      ),
    );

    try {
      final trends = await _arxivService.getTrendAnalysis(
        query: _controller.text.trim(),
        months: 12,
        maxResults: 100,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Fechar dialog de loading
        _showTrendAnalysisDialog(trends);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar dialog de loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na análise de tendências: $e')),
        );
      }
    }
  }

  void _showExportDialog(String title, String content, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conteúdo gerado (${_articles.length} artigos):'),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('$title copiado para a área de transferência!')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  void _showTrendAnalysisDialog(Map<String, List<ArxivArticle>> trends) {
    final sortedMonths = trends.keys.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Análise de Tendências: ${_controller.text.trim()}'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evolução nos últimos 12 meses:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedMonths.length,
                  itemBuilder: (context, index) {
                    final month = sortedMonths[index];
                    final articles = trends[month]!;
                    final parts = month.split('-');
                    final monthName = _getMonthName(int.parse(parts[1]));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[600],
                          child: Text(
                            '${articles.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('$monthName ${parts[0]}'),
                        subtitle: Text('${articles.length} artigos publicados'),
                        trailing: articles.isNotEmpty
                            ? Icon(Icons.trending_up, color: Colors.green[600])
                            : Icon(Icons.trending_flat,
                                color: Colors.grey[600]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Total: ${trends.values.fold<int>(0, (sum, articles) => sum + articles.length)} artigos',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final trendText = _generateTrendReport(trends);
              Clipboard.setData(ClipboardData(text: trendText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Análise de tendências copiada!')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Relatório'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return months[month];
  }

  String _generateTrendReport(Map<String, List<ArxivArticle>> trends) {
    final buffer = StringBuffer();
    buffer.writeln('ANÁLISE DE TENDÊNCIAS');
    buffer.writeln('Termo: ${_controller.text.trim()}');
    buffer.writeln('Período: Últimos 12 meses');
    buffer.writeln('=' * 40);
    buffer.writeln();

    final sortedMonths = trends.keys.toList()..sort();
    for (final month in sortedMonths) {
      final articles = trends[month]!;
      final parts = month.split('-');
      buffer.writeln(
          '${_getMonthName(int.parse(parts[1]))} ${parts[0]}: ${articles.length} artigos');
    }

    buffer.writeln();
    buffer.writeln(
        'Total: ${trends.values.fold<int>(0, (sum, articles) => sum + articles.length)} artigos');

    return buffer.toString();
  }

  /// Constrói o editor LaTeX no painel direito
  Widget _buildLatexEditor() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Cabeçalho do editor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_document,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Editor LaTeX - Estado da Arte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Botão para configurações de IA
                IconButton(
                  onPressed: _showAISettingsDialog,
                  icon: const Icon(Icons.settings, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(25),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  tooltip: 'Configurações de IA',
                ),
                const SizedBox(width: 8),
                // Botão para gerar estado da arte
                ElevatedButton.icon(
                  onPressed: _loadingLatex ? null : _generateLatexStateOfArt,
                  icon: _loadingLatex
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_loadingLatex ? 'Gerando...' : 'Gerar IA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          // Toolbar do editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                _buildToolbarButton(Icons.save, 'Salvar', _saveLatexFile),
                const SizedBox(width: 8),
                _buildToolbarButton(
                    Icons.copy, 'Copiar', _copyLatexToClipboard),
                const SizedBox(width: 8),
                _buildToolbarButton(Icons.download, 'Export', _exportLatex),
                const Spacer(),
                Text(
                  '${_getSelectedArticlesCount()} artigos selecionados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Editor de texto
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _latexController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText:
                      'O estado da arte em LaTeX aparecerá aqui...\n\nDica: Selecione artigos nas abas à esquerda e clique em "Gerar IA" para criar automaticamente o estado da arte.',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(16),
                ),
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  int _getSelectedArticlesCount() {
    // Conta artigos selecionados baseado na aba atual
    switch (_tabController.index) {
      case 0:
        return _articles.length;
      case 3:
        return _savedArticles.length;
      case 4:
        return _recentArticles.length;
      default:
        return 0;
    }
  }

  Future<void> _generateLatexStateOfArt() async {
    final selectedArticles = _getSelectedArticles();

    if (selectedArticles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selecione alguns artigos primeiro para gerar o estado da arte'),
        ),
      );
      return;
    }

    setState(() {
      _loadingLatex = true;
    });

    try {
      // Primeiro, verifica se tem um termo de busca
      final topic = _controller.text.trim().isNotEmpty
          ? _controller.text.trim()
          : 'Estado da Arte em Matemática';

      // Limpa o editor e mostra progresso inicial
      setState(() {
        _latexController.text =
            '% Iniciando geração do Estado da Arte...\n% Tópico: $topic\n\n';
      });

      setState(() {
        _latexController.text += '% 🔍 Verificando sistema de IA...\n';
      });

      final hasGeminiConfigured = ExportService.hasGeminiConfigured;

      // Determina se deve usar IA
      bool useAI = false;

      if (_selectedAIService == 'auto') {
        useAI = true;
      } else if (_selectedAIService == 'gemini' && hasGeminiConfigured) {
        useAI = true;
      } else if (_selectedAIService == 'auto') {
        if (hasGeminiConfigured) {
          useAI = true;
        }
      }

      if (useAI) {
        // Inicia o cabeçalho LaTeX
        setState(() {
          _latexController.text = _getLatexHeader(topic);
        });

        // Streaming da análise com IA
        final stream = ExportService.generateAIStateOfArtStream(
            selectedArticles, topic,
            preferredService:
                _selectedAIService == 'auto' ? null : _selectedAIService);

        await for (String chunk in stream) {
          setState(() {
            // Se é uma mensagem de progresso (contém emojis), adiciona como comentário
            if (chunk.contains('🔧') ||
                chunk.contains('📄') ||
                chunk.contains('🤖') ||
                chunk.contains('🔄')) {
              _latexController.text += '\n% $chunk';
            } else {
              // Adiciona o chunk diretamente já que vem em LaTeX
              _latexController.text += chunk;
            }
          });

          // Pequeno delay para visualizar o streaming
          await Future.delayed(const Duration(milliseconds: 30));
        }

        // Adiciona o rodapé LaTeX
        setState(() {
          _latexController.text += '\n\n\\end{document}';
        });
      } else {
        // Fallback: usa o método tradicional
        setState(() {
          _latexController.text +=
              '% ⚠️ IA não disponível. Usando geração básica...\n';
        });

        final latexContent =
            ExportService.generateStateOfArtLatex(selectedArticles, topic);
        setState(() {
          _latexController.text = latexContent;
        });
      }

      // Mostra sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(useAI
                ? '🎉 Estado da arte gerado com IA!'
                : '✅ Estado da arte gerado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _latexController.text += '\n\n% ❌ Erro: $e\n';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar estado da arte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingLatex = false;
      });
    }
  }

  String _getLatexHeader(String title) {
    return '''\\documentclass[12pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[portuguese]{babel}
\\usepackage{amsmath,amsfonts,amssymb}
\\usepackage{graphicx}
\\usepackage{hyperref}
\\usepackage{geometry}
\\geometry{margin=2.5cm}

\\title{$title}
\\author{Gerado Automaticamente pelo MathStateArt}
\\date{\\today}

\\begin{document}
\\maketitle

''';
  }

  void _showAISettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.smart_toy, color: Color(0xFF1E3A8A)),
                  SizedBox(width: 8),
                  Text('Configurações de IA'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escolha o serviço de IA para gerar o estado da arte:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Opção Auto
                    GestureDetector(
                      onTap: () => setDialogState(() {
                        _selectedAIService = 'auto';
                      }),
                      child: RadioListTile<String>(
                        value: 'auto',
                        selected: _selectedAIService == 'auto',
                        title: const Text('🤖 Automático'),
                        subtitle: const Text(
                            'Detecta automaticamente o melhor serviço disponível'),
                      ),
                    ),

                    // Opção Local (Gemini)
                    GestureDetector(
                      onTap: () => setDialogState(() {
                        _selectedAIService = 'local';
                      }),
                      child: RadioListTile<String>(
                        value: 'local',
                        selected: _selectedAIService == 'local',
                        title: const Text('🏠 Local (Gemini)'),
                        subtitle: const Text('IA local - privada e gratuita'),
                      ),
                    ),

                    // Opção Gemini
                    GestureDetector(
                      onTap: () => setDialogState(() {
                        _selectedAIService = 'gemini';
                      }),
                      child: RadioListTile<String>(
                        value: 'gemini',
                        selected: _selectedAIService == 'gemini',
                        title: const Text('🚀 Gemini 2.0 Flash'),
                        subtitle:
                            const Text('IA da Google - rápida e avançada'),
                      ),
                    ),

                    // Campo da API Key do Gemini
                    if (_selectedAIService == 'gemini' ||
                        _selectedAIService == 'auto')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'API Key do Gemini:',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _geminiApiKeyController,
                            decoration: const InputDecoration(
                              hintText: 'Cole sua API key do Gemini aqui...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Aqui você pode abrir a URL da API key
                                  },
                                  child: const Text(
                                    'Obtenha sua API key gratuita em aistudio.google.com',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Salva as configurações
                    if (_geminiApiKeyController.text.isNotEmpty) {
                      ExportService.setGeminiApiKey(
                          _geminiApiKeyController.text);
                    }
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Configurações de IA salvas!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<ArxivArticle> _getSelectedArticles() {
    switch (_tabController.index) {
      case 0:
        return _articles;
      case 3:
        return _savedArticles;
      case 4:
        return _recentArticles;
      default:
        return [];
    }
  }

  void _saveLatexFile() {
    if (_latexController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nada para salvar')),
        );
      }
      return;
    }

    // Aqui você pode implementar o salvamento em arquivo
    // Por enquanto, apenas mostra uma mensagem
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funcionalidade de salvamento será implementada'),
        ),
      );
    }
  }

  void _copyLatexToClipboard() {
    if (_latexController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nada para copiar')),
        );
      }
      return;
    }

    Clipboard.setData(ClipboardData(text: _latexController.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('LaTeX copiado para a área de transferência!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _StreamingStateOfArtDialog extends StatefulWidget {
  final List<ArxivArticle> articles;
  final String topic;

  const _StreamingStateOfArtDialog({
    required this.articles,
    required this.topic,
  });

  @override
  State<_StreamingStateOfArtDialog> createState() =>
      _StreamingStateOfArtDialogState();
}

class _StreamingStateOfArtDialogState
    extends State<_StreamingStateOfArtDialog> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComplete = false;
  String _fullText = '';

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  void _startStreaming() async {
    try {
      await for (final token in ExportService.generateAIStateOfArtStreaming(
          widget.articles, widget.topic)) {
        if (mounted) {
          setState(() {
            _fullText += token;
            _textController.text = _fullText;
          });

          // Auto-scroll para o final
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }

      if (mounted) {
        setState(() {
          _isComplete = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullText += '\n\n❌ Erro durante a geração: $e';
          _textController.text = _fullText;
          _isComplete = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🧠 Gerando Estado da Arte com IA',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (_isComplete)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const Divider(),

            // Status indicator
            if (!_isComplete)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gerando texto token por token...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),

            if (_isComplete)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Geração concluída!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // Text area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  scrollController: _scrollController,
                  maxLines: null,
                  expands: true,
                  readOnly: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText:
                        'O estado da arte aparecerá aqui token por token...',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isComplete) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _fullText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Texto copiado para a área de transferência!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Aqui você pode adicionar lógica para salvar o arquivo
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(_isComplete ? 'Fechar' : 'Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
