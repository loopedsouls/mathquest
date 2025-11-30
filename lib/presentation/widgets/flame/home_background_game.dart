import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Animated background for home screen
class HomeBackgroundGame extends FlameGame {
  final Color primaryColor;

  HomeBackgroundGame({
    this.primaryColor = const Color(0xFF6C63FF),
  });

  @override
  Future<void> onLoad() async {
    // Add floating geometric shapes
    for (int i = 0; i < 8; i++) {
      add(FloatingShape(
        shapeType: ShapeType.values[i % ShapeType.values.length],
        startPosition: Vector2(
          Random().nextDouble() * size.x,
          Random().nextDouble() * size.y,
        ),
        color: primaryColor,
        index: i,
      ));
    }

    // Add grid pattern
    add(AnimatedGrid(bounds: size, color: primaryColor));

    // Add subtle pulse from center
    add(CenterPulse(
      center: size / 2,
      color: primaryColor,
    ));
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
}

enum ShapeType { circle, triangle, square, hexagon }

/// Floating geometric shape
class FloatingShape extends PositionComponent {
  final ShapeType shapeType;
  final Vector2 startPosition;
  final Color color;
  final int index;

  double _time = 0;
  late double _floatSpeed;
  late double _rotationSpeed;
  late double _size;
  final _random = Random();

  FloatingShape({
    required this.shapeType,
    required this.startPosition,
    required this.color,
    required this.index,
  }) : super(position: startPosition.clone(), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _floatSpeed = 0.3 + _random.nextDouble() * 0.4;
    _rotationSpeed = (_random.nextDouble() - 0.5) * 0.3;
    _size = 20 + _random.nextDouble() * 20;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    position.y = startPosition.y + sin(_time * _floatSpeed + index) * 30;
    position.x = startPosition.x + cos(_time * _floatSpeed * 0.7 + index) * 20;
    angle += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (shapeType) {
      case ShapeType.circle:
        canvas.drawCircle(Offset.zero, _size, paint);
        canvas.drawCircle(Offset.zero, _size, strokePaint);
        break;
      case ShapeType.triangle:
        _drawTriangle(canvas, _size, paint);
        _drawTriangle(canvas, _size, strokePaint);
        break;
      case ShapeType.square:
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: _size * 2, height: _size * 2),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: _size * 2, height: _size * 2),
          strokePaint,
        );
        break;
      case ShapeType.hexagon:
        _drawHexagon(canvas, _size, paint);
        _drawHexagon(canvas, _size, strokePaint);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, double size, Paint paint) {
    final path = Path();
    path.moveTo(0, -size);
    path.lineTo(size * 0.866, size * 0.5);
    path.lineTo(-size * 0.866, size * 0.5);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - pi / 2;
      final x = cos(angle) * size;
      final y = sin(angle) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Animated grid background
class AnimatedGrid extends Component {
  final Vector2 bounds;
  final Color color;

  double _time = 0;

  AnimatedGrid({required this.bounds, required this.color});

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    const spacing = 60.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    // Vertical lines
    for (double x = 0; x < bounds.x; x += spacing) {
      final offset = sin(_time + x * 0.01) * 5;
      canvas.drawLine(
        Offset(x + offset, 0),
        Offset(x + offset, bounds.y),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < bounds.y; y += spacing) {
      final offset = cos(_time + y * 0.01) * 5;
      canvas.drawLine(
        Offset(0, y + offset),
        Offset(bounds.x, y + offset),
        paint,
      );
    }
  }
}

/// Pulsing effect from center
class CenterPulse extends Component {
  final Vector2 center;
  final Color color;

  final List<_PulseRing> _rings = [];
  double _spawnTimer = 0;

  CenterPulse({required this.center, required this.color});

  @override
  void update(double dt) {
    _spawnTimer += dt;

    if (_spawnTimer > 3.0 && _rings.length < 3) {
      _spawnTimer = 0;
      _rings.add(_PulseRing(radius: 0, alpha: 0.2));
    }

    for (final ring in _rings) {
      ring.radius += dt * 50;
      ring.alpha -= dt * 0.05;
    }

    _rings.removeWhere((r) => r.alpha <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final ring in _rings) {
      final paint = Paint()
        ..color = color.withValues(alpha: ring.alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center.toOffset(), ring.radius, paint);
    }
  }
}

class _PulseRing {
  double radius;
  double alpha;

  _PulseRing({required this.radius, required this.alpha});
}

/// XP gain animation overlay
class XpGainGame extends FlameGame {
  final int xpAmount;
  final Color color;

  XpGainGame({
    required this.xpAmount,
    this.color = Colors.amber,
  });

  @override
  Future<void> onLoad() async {
    // Rising XP number
    add(RisingXpNumber(
      position: size / 2,
      xp: xpAmount,
      color: color,
    ));

    // Sparkles
    for (int i = 0; i < 12; i++) {
      add(XpSparkle(
        center: size / 2,
        angle: (i / 12) * 2 * pi,
        color: color,
        delay: i * 0.05,
      ));
    }
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

/// Rising XP number animation
class RisingXpNumber extends PositionComponent {
  final int xp;
  final Color color;

  double _time = 0;
  double _alpha = 0;
  double _scale = 0;
  double _yOffset = 0;

  RisingXpNumber({
    required Vector2 position,
    required this.xp,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    // Pop in
    if (_time < 0.3) {
      _scale = (_time / 0.3);
      _alpha = _scale;
    }
    // Hold
    else if (_time < 1.0) {
      _scale = 1.0;
      _alpha = 1.0;
    }
    // Rise and fade
    else if (_time < 2.0) {
      final fadeProgress = (_time - 1.0) / 1.0;
      _alpha = 1.0 - fadeProgress;
      _yOffset = fadeProgress * -50;
    } else {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(0, _yOffset);
    canvas.scale(_scale);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '+$xp XP',
        style: TextStyle(
          color: color.withValues(alpha: _alpha),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: _alpha * 0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
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

/// Sparkle for XP gain
class XpSparkle extends PositionComponent {
  @override
  final Vector2 center;
  @override
  final double angle;
  final Color color;
  final double delay;

  double _time = 0;
  double _distance = 0;
  double _alpha = 0;

  XpSparkle({
    required this.center,
    required this.angle,
    required this.color,
    this.delay = 0,
  }) : super(position: center.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    final activeTime = _time - delay;

    if (activeTime < 0.5) {
      _distance = activeTime / 0.5 * 100;
      _alpha = 1.0;
    } else if (activeTime < 1.0) {
      _distance = 100;
      _alpha = 1.0 - ((activeTime - 0.5) / 0.5);
    } else {
      removeFromParent();
    }

    position = center + Vector2(cos(angle) * _distance, sin(angle) * _distance);
  }

  @override
  void render(Canvas canvas) {
    if (_time < delay) return;

    final paint = Paint()..color = color.withValues(alpha: _alpha);

    // Star shape
    final path = Path();
    const size = 6.0;
    for (int i = 0; i < 4; i++) {
      final a = (i / 4) * 2 * pi;
      final x = cos(a) * size;
      final y = sin(a) * size;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }
}

/// Streak fire animation
class StreakFireGame extends FlameGame {
  final int streak;

  StreakFireGame({required this.streak});

  @override
  Future<void> onLoad() async {
    add(FireParticles(
      position: Vector2(size.x / 2, size.y),
      intensity: streak,
    ));
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

/// Fire particles for streak
class FireParticles extends Component {
  final Vector2 position;
  final int intensity;

  final List<_FireParticle> _particles = [];
  final _random = Random();
  double _spawnTimer = 0;

  FireParticles({
    required this.position,
    required this.intensity,
  });

  @override
  void update(double dt) {
    _spawnTimer += dt;

    if (_spawnTimer > 0.02 && _particles.length < intensity * 5) {
      _spawnTimer = 0;
      _particles.add(_FireParticle(
        position: Vector2(
          position.x + (_random.nextDouble() - 0.5) * 30,
          position.y,
        ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 30,
          -50 - _random.nextDouble() * 100,
        ),
        size: 4 + _random.nextDouble() * 4,
        color: _random.nextBool() ? Colors.orange : Colors.red,
      ));
    }

    for (final particle in _particles) {
      particle.position += particle.velocity * dt;
      particle.velocity.x += (_random.nextDouble() - 0.5) * 100 * dt;
      particle.alpha -= dt * 2;
      particle.size -= dt * 3;
    }

    _particles.removeWhere((p) => p.alpha <= 0 || p.size <= 0);
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.alpha);
      canvas.drawCircle(particle.position.toOffset(), particle.size, paint);
    }
  }
}

class _FireParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  Color color;
  double alpha = 1.0;

  _FireParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

/// Level up celebration
class LevelUpGame extends FlameGame {
  final int newLevel;

  LevelUpGame({required this.newLevel});

  @override
  Future<void> onLoad() async {
    // Central badge
    add(LevelBadge(
      position: size / 2,
      level: newLevel,
    ));

    // Rays
    add(LevelRays(
      center: size / 2,
    ));

    // Confetti
    for (int i = 0; i < 50; i++) {
      add(LevelConfetti(
        bounds: size,
        delay: i * 0.02,
      ));
    }
  }

  @override
  Color backgroundColor() => Colors.black.withValues(alpha: 0.7);
}

/// Level badge component
class LevelBadge extends PositionComponent {
  final int level;

  double _time = 0;
  double _scale = 0;

  LevelBadge({
    required Vector2 position,
    required this.level,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;

    // Bounce in effect
    if (_time < 0.5) {
      _scale = Curves.elasticOut.transform(_time / 0.5);
    } else {
      _scale = 1.0 + sin(_time * 3) * 0.05;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(_scale);

    // Glow
    final glowGradient = RadialGradient(
      colors: [
        Colors.amber.withValues(alpha: 0.5),
        Colors.amber.withValues(alpha: 0),
      ],
    );
    final glowPaint = Paint()
      ..shader = glowGradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: 80),
      );
    canvas.drawCircle(Offset.zero, 80, glowPaint);

    // Badge background
    final badgePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 50));
    canvas.drawCircle(Offset.zero, 50, badgePaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset.zero, 50, borderPaint);

    // Level text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
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

/// Rays emanating from level badge
class LevelRays extends Component {
  final Vector2 center;

  double _time = 0;

  LevelRays({required this.center});

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final rayPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * pi + _time * 0.2;
      const innerRadius = 60.0;
      final outerRadius = 120.0 + sin(_time * 4 + i) * 20;

      canvas.drawLine(
        Offset(
          center.x + cos(angle) * innerRadius,
          center.y + sin(angle) * innerRadius,
        ),
        Offset(
          center.x + cos(angle) * outerRadius,
          center.y + sin(angle) * outerRadius,
        ),
        rayPaint,
      );
    }
  }
}

/// Confetti for level up
class LevelConfetti extends PositionComponent {
  final Vector2 bounds;
  final double delay;

  double _time = 0;
  late Vector2 _velocity;
  late Color _color;
  late double _rotationSpeed;
  final _random = Random();

  LevelConfetti({
    required this.bounds,
    this.delay = 0,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    position = Vector2(
      _random.nextDouble() * bounds.x,
      -20,
    );
    _velocity = Vector2(
      (_random.nextDouble() - 0.5) * 100,
      100 + _random.nextDouble() * 100,
    );
    _color = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ][_random.nextInt(6)];
    _rotationSpeed = (_random.nextDouble() - 0.5) * 10;
  }

  @override
  void update(double dt) {
    _time += dt;

    if (_time < delay) return;

    position += _velocity * dt;
    _velocity.x += (_random.nextDouble() - 0.5) * 50 * dt;
    angle += _rotationSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    if (_time < delay) return;
    if (position.y > bounds.y + 20) return;

    final paint = Paint()..color = _color;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: 10, height: 6),
      paint,
    );
  }
}
