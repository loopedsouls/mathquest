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
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
            SizedBox(width: 4),
          ],
          if (widget.showText)
            Text(
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
            SizedBox(width: 4),
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
            SizedBox(width: 8),
            Text('Status do Serviço de IA'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serviço Atual: $_currentService'),
            SizedBox(height: 16),
            if (_currentService == 'Ollama Local') ...[
              Text(
                '✅ Conectado ao Ollama local',
                style: TextStyle(color: Colors.green),
              ),
              Text('• Funciona offline'),
              Text('• Maior privacidade'),
              Text('• Processamento local'),
            ] else if (_currentService == 'Gemini Cloud') ...[
              Text(
                '☁️ Usando Gemini na nuvem',
                style: TextStyle(color: Colors.blue),
              ),
              Text('• Requer internet'),
              Text('• Processamento na nuvem'),
              Text('• Sempre disponível'),
            ] else ...[
              Text(
                '⚠️ Serviço não disponível',
                style: TextStyle(color: Colors.orange),
              ),
              Text('• Verifique a configuração'),
            ],
            SizedBox(height: 16),
            Text(
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
            child: Text('Atualizar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
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
