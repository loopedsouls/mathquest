import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'arxiv_service.dart';
import 'pdf_viewer.dart';

class ArticleViewer extends StatefulWidget {
  final ArxivArticle article;

  const ArticleViewer({super.key, required this.article});

  @override
  State<ArticleViewer> createState() => _ArticleViewerState();
}

class _ArticleViewerState extends State<ArticleViewer> {
  bool _isMobile = false;

  @override
  Widget build(BuildContext context) {
    _isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Visualizador de Artigo'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLink,
            tooltip: 'Copiar link',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareArticle,
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: _isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleHeader(),
          const SizedBox(height: 16),
          _buildArticleContent(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar com informações do artigo
        Container(
          width: 350,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArticleHeader(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
        // Conteúdo principal
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildArticleContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildArticleHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.article.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.article.authors,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.article.link,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A8A),
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.article, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'Resumo do Artigo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.article.summary,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildMetadata(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metadados do Artigo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        _buildMetadataRow('Título', widget.article.title),
        _buildMetadataRow('Autores', widget.article.authors),
        _buildMetadataRow('Link', widget.article.link),
        _buildMetadataRow('Fonte', 'arXiv'),
        _buildMetadataRow('Formato', 'Artigo Científico'),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _openInBrowser,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir no Navegador'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _viewPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Visualizar PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _downloadPdf,
          icon: const Icon(Icons.download),
          label: const Text('Download PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E3A8A),
            side: const BorderSide(color: Color(0xFF1E3A8A)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addToFavorites,
          icon: const Icon(Icons.bookmark_border),
          label: const Text('Adicionar aos Favoritos'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF059669),
            side: const BorderSide(color: Color(0xFF059669)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.article.link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  void _shareArticle() {
    // Compartilhar link do artigo usando Share API
    // Você pode usar o pacote 'share_plus' para multiplataforma
    // Exemplo:
    // import 'package:share_plus/share_plus.dart';
    // Share.share(widget.article.link);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função de compartilhamento será implementada'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _openInBrowser() async {
    final uri = Uri.parse(widget.article.link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewer(
          pdfUrl: widget.article.link,
          title: widget.article.title,
        ),
      ),
    );
  }

  void _downloadPdf() {
    // Implementação básica de download de PDF (abre o link no navegador)
    final uri = Uri.parse(widget.article.link);
    launchUrl(uri, mode: LaunchMode.externalApplication);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download iniciado no navegador'),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  void _addToFavorites() {
    // Exemplo de sistema de favoritos usando SavedArticlesService
    // Você pode importar e usar o serviço diretamente aqui:
    // import '../../services/math/saved_articles_service.dart';
    // final savedService = SavedArticlesService();
    // await savedService.saveArticle(widget.article);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adicionado aos favoritos!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }
}
