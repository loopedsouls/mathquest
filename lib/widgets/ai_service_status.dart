import 'package:flutter/material.dart';
import '../services/ia_service.dart';

/// Widget que mostra o status do serviço de IA atual
class AIServiceStatusWidget extends StatefulWidget {
  final SmartAIService? aiService;
  final bool showIcon;
  final bool showText;

  const AIServiceStatusWidget({
    super.key,
    this.aiService,
    this.showIcon = true,
    this.showText = true,
  });

  @override
  State<AIServiceStatusWidget> createState() => _AIServiceStatusWidgetState();
}

class _AIServiceStatusWidgetState extends State<AIServiceStatusWidget> {
  String _currentService = 'Verificando...';
  bool _isLoading = true;
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.help;

  @override
  void initState() {
    super.initState();
    _updateServiceStatus();
  }

  Future<void> _updateServiceStatus() async {
    if (widget.aiService == null) {
      setState(() {
        _currentService = 'Não configurado';
        _isLoading = false;
        _statusColor = Colors.red;
        _statusIcon = Icons.error;
      });
      return;
    }

    try {
      final service = await widget.aiService!.getCurrentService();

      setState(() {
        _currentService = service;
        _isLoading = false;

        if (service == 'Ollama Local') {
          _statusColor = Colors.green;
          _statusIcon = Icons.computer;
        } else if (service == 'Gemini Cloud') {
          _statusColor = Colors.blue;
          _statusIcon = Icons.cloud;
        } else {
          _statusColor = Colors.orange;
          _statusIcon = Icons.warning;
        }
      });
    } catch (e) {
      setState(() {
        _currentService = 'Erro';
        _isLoading = false;
        _statusColor = Colors.red;
        _statusIcon = Icons.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            const SizedBox(width: 4),
          ],
          if (widget.showText)
            const Text(
              'Verificando...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showServiceInfo(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showIcon) ...[
            Icon(
              _statusIcon,
              size: 16,
              color: _statusColor,
            ),
            const SizedBox(width: 4),
          ],
          if (widget.showText)
            Text(
              _currentService,
              style: TextStyle(
                fontSize: 12,
                color: _statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  void _showServiceInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_statusIcon, color: _statusColor),
            const SizedBox(width: 8),
            const Text('Status do Serviço de IA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serviço Atual: $_currentService'),
            const SizedBox(height: 16),
            if (_currentService == 'Ollama Local') ...[
              const Text(
                '✅ Conectado ao Ollama local',
                style: TextStyle(color: Colors.green),
              ),
              const Text('• Funciona offline'),
              const Text('• Maior privacidade'),
              const Text('• Processamento local'),
            ] else if (_currentService == 'Gemini Cloud') ...[
              const Text(
                '☁️ Usando Gemini na nuvem',
                style: TextStyle(color: Colors.blue),
              ),
              const Text('• Requer internet'),
              const Text('• Processamento na nuvem'),
              const Text('• Sempre disponível'),
            ] else ...[
              const Text(
                '⚠️ Serviço não disponível',
                style: TextStyle(color: Colors.orange),
              ),
              const Text('• Verifique a configuração'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Dica: Para usar Ollama local, configure CORS:\nOLLAMA_ORIGINS="*"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateServiceStatus(); // Atualiza o status
            },
            child: const Text('Atualizar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar apenas o ícone do status
class AIServiceStatusIcon extends StatelessWidget {
  final SmartAIService? aiService;

  const AIServiceStatusIcon({
    super.key,
    this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return AIServiceStatusWidget(
      aiService: aiService,
      showIcon: true,
      showText: false,
    );
  }
}

/// Widget para mostrar apenas o texto do status
class AIServiceStatusText extends StatelessWidget {
  final SmartAIService? aiService;

  const AIServiceStatusText({
    super.key,
    this.aiService,
  });

  @override
  Widget build(BuildContext context) {
    return AIServiceStatusWidget(
      aiService: aiService,
      showIcon: false,
      showText: true,
    );
  }
}
