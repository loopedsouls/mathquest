import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Animated onboarding background
class OnboardingGame extends FlameGame {
  final int pageIndex;
  final Color pageColor;

  OnboardingGame({
    this.pageIndex = 0,
    required this.pageColor,
  });

  @override
  Future<void> onLoad() async {
    // Add different animations based on page
    switch (pageIndex) {
      case 0:
        _addMathSymbolsAnimation();
        break;
      case 1:
        _addRewardsAnimation();
        break;
      case 2:
        _addProgressAnimation();
        break;
      case 3:
        _addSocialAnimation();
        break;
      default:
        _addMathSymbolsAnimation();
    }

    // Add subtle background particles on all pages
    add(OnboardingParticles(
      bounds: size,
      color: pageColor,
    ));
  }

  void _addMathSymbolsAnimation() {
    // Floating math equations
    const equations = ['2+2=4', 'π≈3.14', 'x²', '∑', '√9=3', '∞'];

    for (int i = 0; i < equations.length; i++) {
      add(FloatingEquation(
        equation: equations[i],
        startPosition: Vector2(
          (i % 3 + 0.5) * size.x / 3,
          (i ~/ 3 + 0.5) * size.y / 3,
        ),
        color: pageColor,
        delay: i * 0.2,
      ));
    }

    // Add orbiting symbols
    add(OrbitingSymbols(
      center: size / 2,
      color: pageColor,
    ));
  }

  void _addRewardsAnimation() {
    // Falling coins
    add(FallingCoins(
      bounds: size,
      color: const Color(0xFFFFD700),
    ));

    // Trophy glow
    add(TrophyPulse(
      position: Vector2(size.x / 2, size.y * 0.4),
      color: pageColor,
    ));

    // Stars burst
    for (int i = 0; i < 3; i++) {
      add(StarBurst(
        position: Vector2(
          size.x * (0.2 + i * 0.3),
          size.y * 0.3,
        ),
        delay: i * 0.5,
      ));
    }
  }

  void _addProgressAnimation() {
    // Progress bars filling up
    for (int i = 0; i < 5; i++) {
      add(AnimatedProgressBar(
        position: Vector2(size.x * 0.15, size.y * (0.25 + i * 0.1)),
        width: size.x * 0.7,
        color: pageColor,
        delay: i * 0.3,
        targetProgress: 0.3 + Random().nextDouble() * 0.6,
      ));
    }

    // Rising chart
    add(RisingChart(
      position: Vector2(size.x / 2, size.y * 0.7),
      color: pageColor,
    ));
  }

  void _addSocialAnimation() {
    // Avatar circles
    final avatarPositions = [
      Vector2(size.x * 0.3, size.y * 0.3),
      Vector2(size.x * 0.7, size.y * 0.3),
      Vector2(size.x * 0.5, size.y * 0.5),
      Vector2(size.x * 0.2, size.y * 0.6),
      Vector2(size.x * 0.8, size.y * 0.6),
    ];

    for (int i = 0; i < avatarPositions.length; i++) {
      add(AvatarBubble(
        position: avatarPositions[i],
        color: pageColor,
        delay: i * 0.2,
        rank: i + 1,
      ));
    }

    // Connecting lines
    add(ConnectingLines(
      positions: avatarPositions,
      color: pageColor,
    ));
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

/// Floating equation text
class FloatingEquation extends PositionComponent {
  final String equation;
  final Vector2 startPosition;
  final Color color;
  final double delay;

  double _time = 0;
  double _alpha = 0;

  FloatingEquation({
    required this.equation,
    required this.startPosition,
    required this.color,
    this.delay = 0,
  }) : super(position: startPosition.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    final activeTime = _time - delay;
    _alpha = (sin(activeTime * 2) + 1) / 2 * 0.4;

    position.y = startPosition.y + sin(activeTime * 0.5) * 20;
    position.x = startPosition.x + cos(activeTime * 0.3) * 15;
  }

  @override
  void render(Canvas canvas) {
    if (_time < delay) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: equation,
        style: TextStyle(
          color: color.withValues(alpha: _alpha),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

/// Orbiting symbols around center
class OrbitingSymbols extends PositionComponent {
  @override
  final Vector2 center;
  final Color color;

  double _time = 0;
  final symbols = ['+', '-', '×', '÷', '=', '%'];

  OrbitingSymbols({
    required this.center,
    required this.color,
  }) : super(position: center, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < symbols.length; i++) {
      final angle = _time * 0.3 + (i * 2 * pi / symbols.length);
      const radius = 120.0;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius * 0.3; // Elliptical orbit

      final textPainter = TextPainter(
        text: TextSpan(
          text: symbols[i],
          style: TextStyle(
            color: color.withValues(alpha: 0.3),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }
}

/// Falling coins animation
class FallingCoins extends Component {
  final Vector2 bounds;
  final Color color;

  final List<_Coin> _coins = [];
  final _random = Random();
  double _spawnTimer = 0;

  FallingCoins({
    required this.bounds,
    required this.color,
  });

  @override
  void update(double dt) {
    _spawnTimer += dt;

    if (_spawnTimer > 0.3 && _coins.length < 15) {
      _spawnTimer = 0;
      _coins.add(_Coin(
        position: Vector2(_random.nextDouble() * bounds.x, -30),
        velocity: Vector2(
            (_random.nextDouble() - 0.5) * 30, 50 + _random.nextDouble() * 50),
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: 2 + _random.nextDouble() * 3,
      ));
    }

    for (final coin in _coins) {
      coin.position += coin.velocity * dt;
      coin.rotation += coin.rotationSpeed * dt;
    }

    _coins.removeWhere((c) => c.position.y > bounds.y + 30);
  }

  @override
  void render(Canvas canvas) {
    for (final coin in _coins) {
      canvas.save();
      canvas.translate(coin.position.x, coin.position.y);
      canvas.rotate(coin.rotation);

      // Coin
      final paint = Paint()..color = color;
      canvas.drawCircle(Offset.zero, 15, paint);

      // Inner circle
      final innerPaint = Paint()..color = color.withValues(alpha: 0.7);
      canvas.drawCircle(Offset.zero, 10, innerPaint);

      // $ symbol
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '\$',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }
}

class _Coin {
  Vector2 position;
  Vector2 velocity;
  double rotation;
  double rotationSpeed;

  _Coin({
    required this.position,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Trophy pulse effect
class TrophyPulse extends PositionComponent {
  final Color color;
  double _time = 0;

  TrophyPulse({
    required Vector2 position,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulseSize = 50 + sin(_time * 3) * 10;

    // Glow
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: pulseSize),
      );

    canvas.drawCircle(Offset.zero, pulseSize, paint);
  }
}

/// Star burst animation
class StarBurst extends PositionComponent {
  final double delay;

  double _time = 0;
  final _stars = <_BurstStar>[];
  bool _burst = false;
  final _random = Random();

  StarBurst({
    required Vector2 position,
    this.delay = 0,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    if (!_burst) {
      _burst = true;
      _createBurst();
    }

    for (final star in _stars) {
      star.position += star.velocity * dt;
      star.velocity.y += 30 * dt; // gravity
      star.alpha -= dt * 0.5;
    }

    _stars.removeWhere((s) => s.alpha <= 0);
  }

  void _createBurst() {
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      _stars.add(_BurstStar(
        position: Vector2.zero(),
        velocity: Vector2(cos(angle) * 60, sin(angle) * 60 - 30),
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    for (final star in _stars) {
      final paint = Paint()..color = Colors.amber.withValues(alpha: star.alpha);
      _drawStar(canvas, star.position.toOffset(), 8, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * size,
        center.dy + sin(angle) * size,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

class _BurstStar {
  Vector2 position;
  Vector2 velocity;
  double alpha = 1.0;

  _BurstStar({required this.position, required this.velocity});
}

/// Animated progress bar
class AnimatedProgressBar extends PositionComponent {
  @override
  final double width;
  final Color color;
  final double delay;
  final double targetProgress;

  double _progress = 0;
  double _time = 0;

  AnimatedProgressBar({
    required Vector2 position,
    required this.width,
    required this.color,
    this.delay = 0,
    this.targetProgress = 1.0,
  }) : super(
            position: position,
            anchor: Anchor.centerLeft,
            size: Vector2(width, 12));

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    _progress = ((_time - delay) / 1.5).clamp(0.0, targetProgress);
  }

  @override
  void render(Canvas canvas) {
    // Background
    final bgPaint = Paint()..color = color.withValues(alpha: 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, 12),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    // Progress
    if (_progress > 0) {
      final progressPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width * _progress, 12),
          const Radius.circular(6),
        ),
        progressPaint,
      );
    }
  }
}

/// Rising chart animation
class RisingChart extends PositionComponent {
  final Color color;

  double _time = 0;
  final List<double> _barHeights = [0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 0.9];

  RisingChart({
    required Vector2 position,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    const barWidth = 20.0;
    const maxHeight = 80.0;
    const spacing = 8.0;
    final totalWidth = (_barHeights.length * (barWidth + spacing)) - spacing;
    final startX = -totalWidth / 2;

    for (int i = 0; i < _barHeights.length; i++) {
      final animatedHeight =
          _barHeights[i] * ((_time - i * 0.1).clamp(0.0, 1.0));
      final height = maxHeight * animatedHeight;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.3 + animatedHeight * 0.4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + i * (barWidth + spacing),
            -height,
            barWidth,
            height,
          ),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }
}

/// Avatar bubble for social page
class AvatarBubble extends PositionComponent {
  final Color color;
  final double delay;
  final int rank;

  double _time = 0;
  double _scale = 0;

  AvatarBubble({
    required Vector2 position,
    required this.color,
    this.delay = 0,
    this.rank = 1,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    final activeTime = _time - delay;
    _scale = (activeTime / 0.5).clamp(0.0, 1.0);

    // Gentle float
    position.y += sin(activeTime * 2) * 0.3;
  }

  @override
  void render(Canvas canvas) {
    if (_scale <= 0) return;

    canvas.save();
    canvas.scale(_scale);

    // Avatar circle
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset.zero, 25, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset.zero, 25, borderPaint);

    // Rank badge
    final badgePaint = Paint()..color = rank <= 3 ? Colors.amber : Colors.grey;
    canvas.drawCircle(const Offset(18, -18), 12, badgePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset(18 - textPainter.width / 2, -18 - textPainter.height / 2));

    canvas.restore();
  }
}

/// Connecting lines between avatars
class ConnectingLines extends Component {
  final List<Vector2> positions;
  final Color color;

  double _time = 0;

  ConnectingLines({
    required this.positions,
    required this.color,
  });

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (positions.length < 2) return;

    final alpha = ((_time - 1.0) / 0.5).clamp(0.0, 0.3);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw lines between nearby avatars
    for (int i = 0; i < positions.length; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        final distance = positions[i].distanceTo(positions[j]);
        if (distance < 200) {
          canvas.drawLine(
            positions[i].toOffset(),
            positions[j].toOffset(),
            paint,
          );
        }
      }
    }
  }
}

/// Background particles for onboarding
class OnboardingParticles extends Component {
  final Vector2 bounds;
  final Color color;

  final List<_OnboardingParticle> _particles = [];
  final _random = Random();

  OnboardingParticles({
    required this.bounds,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 20; i++) {
      _particles.add(_OnboardingParticle(
        position: Vector2(
          _random.nextDouble() * bounds.x,
          _random.nextDouble() * bounds.y,
        ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 15,
          -10 - _random.nextDouble() * 15,
        ),
        size: 2 + _random.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final particle in _particles) {
      particle.position += particle.velocity * dt;

      if (particle.position.y < -10) {
        particle.position.y = bounds.y + 10;
        particle.position.x = _random.nextDouble() * bounds.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()..color = color.withValues(alpha: 0.15);
      canvas.drawCircle(particle.position.toOffset(), particle.size, paint);
    }
  }
}

class _OnboardingParticle {
  Vector2 position;
  Vector2 velocity;
  double size;

  _OnboardingParticle({
    required this.position,
    required this.velocity,
    required this.size,
  });
}
