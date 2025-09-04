import 'package:flutter/material.dart';
import '../services/ai_queue_service.dart';
import '../theme/app_theme.dart';

class QueueStatusIndicator extends StatefulWidget {
  const QueueStatusIndicator({super.key});

  @override
  State<QueueStatusIndicator> createState() => _QueueStatusIndicatorState();
}

class _QueueStatusIndicatorState extends State<QueueStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AIQueueService _queueService;

  @override
  void initState() {
    super.initState();
    _queueService = AIQueueService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _queueService.addListener(_onQueueChanged);
    _updateAnimation();
  }

  @override
  void dispose() {
    _queueService.removeListener(_onQueueChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) {
      setState(() {});
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (_queueService.isProcessing || _queueService.queue.isNotEmpty) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  void _showQueueDetails() {
    final queueInfo = _queueService.getQueueInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Row(
          children: [
            Icon(Icons.queue_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Status da Fila de IA',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Gerações na fila:', '${queueInfo['queueLength']}'),
            _buildStatusRow('Conversas ativas:', '${queueInfo['activeRequests']}'),
            _buildStatusRow('Processando:', _queueService.isProcessing ? 'Sim' : 'Não'),
            _buildStatusRow('Pendentes:', '${queueInfo['pendingRequests']}'),
            const SizedBox(height: 16),
            Text(
              'ℹ️ A fila permite trocar de conversa sem perder gerações em andamento.',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_queueService.queue.isNotEmpty || _queueService.activeRequests.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _queueService.clearAll();
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.clear_all, color: AppTheme.errorColor),
              label: Text(
                'Limpar Fila',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fechar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActivity = _queueService.isProcessing || 
                        _queueService.queue.isNotEmpty ||
                        _queueService.activeRequests.isNotEmpty;

    if (!hasActivity) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showQueueDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(_animation.value),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 16,
                      color: AppTheme.primaryColor.withOpacity(_animation.value),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _queueService.isProcessing ? 'IA gerando...' : 'Na fila: ${_queueService.queue.length}',
                      style: TextStyle(
                        color: AppTheme.primaryColor.withOpacity(_animation.value),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
