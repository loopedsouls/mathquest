import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Animated splash screen background with floating math symbols and particles
class SplashGame extends FlameGame {
  final Color primaryColor;
  final Color secondaryColor;

  SplashGame({
    this.primaryColor = const Color(0xFF6C63FF),
    this.secondaryColor = const Color(0xFF00BFA5),
  });

  @override
  Future<void> onLoad() async {
    // Add floating math symbols
    for (int i = 0; i < 15; i++) {
      add(FloatingMathSymbol(
        symbol: _randomSymbol(),
        startPosition: Vector2(
          _random.nextDouble() * size.x,
          _random.nextDouble() * size.y,
        ),
        color: i % 2 == 0 ? primaryColor : secondaryColor,
      ));
    }

    // Add particle emitter
    add(ParticleField(
      bounds: size,
      particleCount: 30,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
    ));

    // Add animated rings
    add(PulsingRing(
      position: size / 2,
      maxRadius: size.x * 0.4,
      color: primaryColor,
    ));

    add(PulsingRing(
      position: size / 2,
      maxRadius: size.x * 0.5,
      color: secondaryColor,
      delay: 0.5,
    ));
  }

  final _random = Random();

  String _randomSymbol() {
    const symbols = [
      '+',
      '-',
      '×',
      '÷',
      '=',
      'π',
      '∑',
      '√',
      '∞',
      '%',
      'Δ',
      'α',
      'β',
      'θ'
    ];
    return symbols[_random.nextInt(symbols.length)];
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
}

/// Floating math symbol with gentle animation
class FloatingMathSymbol extends PositionComponent {
  final String symbol;
  final Vector2 startPosition;
  final Color color;

  late double _floatOffset;
  late double _floatSpeed;
  late double _rotationSpeed;
  double _time = 0;

  FloatingMathSymbol({
    required this.symbol,
    required this.startPosition,
    required this.color,
  }) : super(position: startPosition, anchor: Anchor.center);

  final _random = Random();

  @override
  Future<void> onLoad() async {
    _floatOffset = _random.nextDouble() * 2 * pi;
    _floatSpeed = 0.5 + _random.nextDouble() * 1.0;
    _rotationSpeed = (_random.nextDouble() - 0.5) * 0.5;

    // Add subtle scale animation
    add(ScaleEffect.by(
      Vector2.all(1.2),
      EffectController(
        duration: 2 + _random.nextDouble() * 2,
        reverseDuration: 2 + _random.nextDouble() * 2,
        infinite: true,
      ),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Gentle floating motion
    position.y = startPosition.y + sin(_time * _floatSpeed + _floatOffset) * 20;
    position.x =
        startPosition.x + cos(_time * _floatSpeed * 0.7 + _floatOffset) * 10;

    // Gentle rotation
    angle += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: color.withValues(alpha: 0.3),
          fontSize: 40,
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

/// Field of floating particles
class ParticleField extends Component {
  final Vector2 bounds;
  final int particleCount;
  final Color primaryColor;
  final Color secondaryColor;

  final List<_Particle> _particles = [];
  final _random = Random();

  ParticleField({
    required this.bounds,
    required this.particleCount,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < particleCount; i++) {
      _particles.add(_Particle(
        position: Vector2(
          _random.nextDouble() * bounds.x,
          _random.nextDouble() * bounds.y,
        ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 30,
          -20 - _random.nextDouble() * 30,
        ),
        size: 2 + _random.nextDouble() * 4,
        color: i % 2 == 0 ? primaryColor : secondaryColor,
        alpha: 0.2 + _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final particle in _particles) {
      particle.position += particle.velocity * dt;

      // Wrap around
      if (particle.position.y < -10) {
        particle.position.y = bounds.y + 10;
        particle.position.x = _random.nextDouble() * bounds.x;
      }
      if (particle.position.x < -10) particle.position.x = bounds.x + 10;
      if (particle.position.x > bounds.x + 10) particle.position.x = -10;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.alpha);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }
}

class _Particle {
  Vector2 position;
  Vector2 velocity;
  double size;
  Color color;
  double alpha;

  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.alpha,
  });
}

/// Pulsing ring effect
class PulsingRing extends PositionComponent {
  final double maxRadius;
  final Color color;
  final double delay;

  double _progress = 0;
  late double _startTime;

  PulsingRing({
    required Vector2 position,
    required this.maxRadius,
    required this.color,
    this.delay = 0,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _startTime = -delay;
  }

  @override
  void update(double dt) {
    _startTime += dt;
    if (_startTime < 0) return;

    _progress = (_progress + dt * 0.3) % 1.0;
  }

  @override
  void render(Canvas canvas) {
    if (_startTime < 0) return;

    final radius = maxRadius * _progress;
    final alpha = (1 - _progress) * 0.3;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, radius, paint);
  }
}
