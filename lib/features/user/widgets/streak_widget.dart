import 'package:flutter/material.dart';
import '../../../services/gamificacao_service.dart';
import '../../../app_theme.dart';

class StreakWidget extends StatefulWidget {
  const StreakWidget({super.key});

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget>
    with TickerProviderStateMixin {
  int streakAtual = 0;
  int melhorStreak = 0;
  bool isLoading = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _carregarStreak();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Anima quando há streak > 0
    _pulseController.repeat(reverse: true);
  }

  Future<void> _carregarStreak() async {
    try {
      final streak = await GamificacaoService.obterStreakAtual();
      final melhor = await GamificacaoService.obterMelhorStreak();

      if (mounted) {
        setState(() {
          streakAtual = streak;
          melhorStreak = melhor;
          isLoading = false;
        });
      }

      // Para animação se não há streak
      if (streak == 0) {
        _pulseController.stop();
        _pulseController.reset();
      } else {
        _pulseController.repeat(reverse: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Color _getStreakColor() {
    if (streakAtual == 0) return Colors.grey;
    if (streakAtual < 5) return Colors.orange;
    if (streakAtual < 10) return Colors.deepOrange;
    if (streakAtual < 20) return Colors.red;
    return Colors.purple;
  }

  IconData _getStreakIcon() {
    if (streakAtual == 0) return Icons.local_fire_department_outlined;
    if (streakAtual < 5) return Icons.local_fire_department;
    if (streakAtual < 10) return Icons.whatshot;
    return Icons.rocket_launch;
  }

  String _getStreakMessage() {
    if (streakAtual == 0) return 'Comece sua sequência!';
    if (streakAtual < 5) return 'Boa sequência!';
    if (streakAtual < 10) return 'Sequência impressionante!';
    if (streakAtual < 20) return 'Você está pegando fogo!';
    return 'Sequência lendária!';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: SizedBox(
          height: 80,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: streakAtual > 0
              ? LinearGradient(
                  colors: [
                    _getStreakColor().withValues(alpha: 0.1),
                    _getStreakColor().withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            // Ícone animado
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: streakAtual > 0 ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStreakColor(),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: streakAtual > 0
                          ? [
                              BoxShadow(
                                color: _getStreakColor().withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _getStreakIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(width: 12),

            // Informações do streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sequência: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '$streakAtual',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _getStreakColor(),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (streakAtual > 0) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.trending_up,
                          color: _getStreakColor(),
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStreakMessage(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStreakColor(),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),

            // Melhor streak
            if (melhorStreak > 0)
              Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppTheme.accentColor,
                    size: 16,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$melhorStreak',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Recorde',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Método público para atualizar o streak (pode ser chamado externamente)
  void atualizarStreak() {
    _carregarStreak();
  }
}
