import 'package:flutter/material.dart';
import '../../firebase/service/firebase_ai_service.dart';
import '../../theme/app_theme.dart';

class QueueStatusIndicator extends StatefulWidget {
  const QueueStatusIndicator({super.key});

  @override
  State<QueueStatusIndicator> createState() => _QueueStatusIndicatorState();
}

class _QueueStatusIndicatorState extends State<QueueStatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _firebaseAIReady = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkFirebaseAIStatus();
  }

  Future<void> _checkFirebaseAIStatus() async {
    await FirebaseAIService.initialize();
    if (mounted) {
      setState(() {
        _firebaseAIReady = FirebaseAIService.isAvailable;
      });
      _updateAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation() {
    if (_firebaseAIReady) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.value = 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showStatusDetails,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _firebaseAIReady
                  ? AppTheme.successColor.withValues(alpha: 0.1)
                  : AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _firebaseAIReady
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    _firebaseAIReady ? Icons.check_circle : Icons.error,
                    color: _firebaseAIReady
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _firebaseAIReady
                      ? 'Firebase AI Pronto'
                      : 'Firebase AI Indisponível',
                  style: TextStyle(
                    color: _firebaseAIReady
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStatusDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurfaceColor,
        title: Row(
          children: [
            Icon(
              _firebaseAIReady ? Icons.check_circle : Icons.error,
              color: _firebaseAIReady
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Status do Firebase AI',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
                'Status:', _firebaseAIReady ? 'Disponível' : 'Indisponível'),
            const SizedBox(height: 8),
            Text(
              _firebaseAIReady
                  ? 'O Firebase AI está funcionando corretamente e pronto para gerar respostas.'
                  : 'O Firebase AI não está disponível. Verifique a configuração.',
              style: TextStyle(
                  color: AppTheme.darkTextSecondaryColor, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          if (!_firebaseAIReady)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _checkFirebaseAIStatus();
              },
              child: Text(
                'Tentar Novamente',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.darkTextSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
