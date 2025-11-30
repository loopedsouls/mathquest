import 'package:flutter/material.dart';
import 'duolingo_design_system.dart';

/// Coins display widget for shop - Duolingo style
class CoinsDisplay extends StatelessWidget {
  final int coins;
  final bool showLabel;
  final bool compact;

  const CoinsDisplay({
    super.key,
    required this.coins,
    this.showLabel = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuoCoinIcon(size: 18),
          const SizedBox(width: 4),
          Text(
            _formatCoins(coins),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: DuoColors.yellow,
              fontSize: 14,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: DuoColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DuoColors.yellow.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DuoColors.yellow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DuoCoinIcon(size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel)
                const Text(
                  'Moedas',
                  style: TextStyle(
                    color: DuoColors.grayLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                _formatCoins(coins),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DuoColors.yellow,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCoins(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

/// Animated coins display with gain/loss animation
class AnimatedCoinsDisplay extends StatefulWidget {
  final int coins;
  final int? previousCoins;

  const AnimatedCoinsDisplay({
    super.key,
    required this.coins,
    this.previousCoins,
  });

  @override
  State<AnimatedCoinsDisplay> createState() => _AnimatedCoinsDisplayState();
}

class _AnimatedCoinsDisplayState extends State<AnimatedCoinsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _displayedCoins;
  int? _coinDiff;

  @override
  void initState() {
    super.initState();
    _displayedCoins = widget.coins;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedCoinsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coins != widget.coins) {
      _coinDiff = widget.coins - oldWidget.coins;
      _controller.forward(from: 0).then((_) {
        _controller.reverse();
        setState(() => _coinDiff = null);
      });
      _displayedCoins = widget.coins;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: CoinsDisplay(coins: _displayedCoins ?? widget.coins),
        ),
        if (_coinDiff != null && _coinDiff != 0)
          Positioned(
            top: -20,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(0, -20 * value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _coinDiff! > 0 ? DuoColors.green : DuoColors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _coinDiff! > 0 ? '+$_coinDiff' : '$_coinDiff',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

