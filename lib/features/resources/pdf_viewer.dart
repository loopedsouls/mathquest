import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PDFViewer extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewer({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _openPDFExternal();
  }

  Future<void> _openPDFExternal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Close this screen since we opened external app
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw 'Não foi possível abrir o PDF';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao abrir PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _isLoading ? null : _openPDFExternal,
            tooltip: 'Abrir no navegador',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Abrindo PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openPDFExternal,
              child: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _openPDFExternal,
              child: const Text('Abrir no navegador'),
            ),
          ],
        ),
      );
    }

    // This would be where we show the PDF if we had a working PDF viewer
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'PDF aberto no aplicativo externo',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'O PDF foi aberto no seu visualizador padrão',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
