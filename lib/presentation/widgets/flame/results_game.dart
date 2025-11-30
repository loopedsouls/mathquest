import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Celebration game for results screen with confetti and animations
class ResultsGame extends FlameGame {
  final int stars;
  final Color primaryColor;

  ResultsGame({
    required this.stars,
    required this.primaryColor,
  });

  @override
  Future<void> onLoad() async {
    // Add confetti
    if (stars >= 2) {
      add(ConfettiEmitter(
        position: Vector2(size.x / 2, 0),
        bounds: size,
        intensity: stars == 3 ? 80 : 40,
      ));
    }

    // Add fireworks for perfect score
    if (stars == 3) {
      add(FireworkLauncher(bounds: size));
    }

    // Add floating sparkles
    for (int i = 0; i < 20; i++) {
      add(Sparkle(
        startPosition: Vector2(
          _random.nextDouble() * size.x,
          _random.nextDouble() * size.y,
        ),
        color: _getSparkleColor(i),
      ));
    }

    // Add trophy glow effect for stars > 0
    if (stars > 0) {
      add(TrophyGlow(
        position: Vector2(size.x / 2, size.y * 0.25),
        color: primaryColor,
        stars: stars,
      ));
    }

    // Add rising stars
    for (int i = 0; i < stars; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (isMounted) {
          add(RisingStar(
            startPosition: Vector2(
              size.x * 0.3 + (i * size.x * 0.2),
              size.y,
            ),
            targetPosition: Vector2(
              size.x * 0.3 + (i * size.x * 0.2),
              size.y * 0.15,
            ),
          ));
        }
      });
    }
  }

  final _random = Random();

  Color _getSparkleColor(int index) {
    const colors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
      Color(0xFF00FF00), // Green
      Color(0xFF00BFFF), // Sky blue
      Color(0xFFFF69B4), // Pink
    ];
    return colors[index % colors.length];
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

/// Confetti emitter for celebration
class ConfettiEmitter extends Component {
  final Vector2 position;
  final Vector2 bounds;
  final int intensity;

  final List<ConfettiPiece> _pieces = [];
  final _random = Random();
  double _spawnTimer = 0;

  ConfettiEmitter({
    required this.position,
    required this.bounds,
    this.intensity = 50,
  });

  @override
  void update(double dt) {
    _spawnTimer += dt;

    // Spawn new confetti
    if (_spawnTimer > 0.05 && _pieces.length < intensity) {
      _spawnTimer = 0;
      _pieces.add(ConfettiPiece(
        position: Vector2(
          _random.nextDouble() * bounds.x,
          -10,
        ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 100,
          100 + _random.nextDouble() * 150,
        ),
        color: _randomColor(),
        size: 6 + _random.nextDouble() * 6,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      ));
    }

    // Update pieces
    for (final piece in _pieces) {
      piece.position += piece.velocity * dt;
      piece.rotation += piece.rotationSpeed * dt;
      piece.velocity.x += (_random.nextDouble() - 0.5) * 50 * dt;

      // Add some flutter effect
      piece.velocity.x = piece.velocity.x.clamp(-100, 100);
    }

    // Remove off-screen pieces
    _pieces.removeWhere((p) => p.position.y > bounds.y + 20);
  }

  Color _randomColor() {
    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFFFE66D),
      Color(0xFF95E1D3),
      Color(0xFFF38181),
      Color(0xFFAA96DA),
      Color(0xFF6C63FF),
      Color(0xFF00BFA5),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void render(Canvas canvas) {
    for (final piece in _pieces) {
      canvas.save();
      canvas.translate(piece.position.x, piece.position.y);
      canvas.rotate(piece.rotation);

      final paint = Paint()..color = piece.color;

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: piece.size, height: piece.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }
}

class ConfettiPiece {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double size;
  double rotation = 0;
  double rotationSpeed;

  ConfettiPiece({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.rotationSpeed,
  });
}

/// Firework launcher for perfect scores
class FireworkLauncher extends Component {
  final Vector2 bounds;

  final List<Firework> _fireworks = [];
  final _random = Random();
  double _launchTimer = 0;

  FireworkLauncher({required this.bounds});

  @override
  void update(double dt) {
    _launchTimer += dt;

    // Launch new firework every second
    if (_launchTimer > 1.5 && _fireworks.length < 5) {
      _launchTimer = 0;
      _fireworks.add(Firework(
        position: Vector2(
          bounds.x * 0.2 + _random.nextDouble() * bounds.x * 0.6,
          bounds.y,
        ),
        targetY: bounds.y * 0.2 + _random.nextDouble() * bounds.y * 0.3,
        color: _randomColor(),
      ));
    }

    // Update fireworks
    for (final firework in _fireworks) {
      firework.update(dt);
    }

    // Remove completed fireworks
    _fireworks.removeWhere((f) => f.isComplete);
  }

  Color _randomColor() {
    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFFFFE66D),
      Color(0xFF4ECDC4),
      Color(0xFF6C63FF),
      Color(0xFFFF69B4),
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void render(Canvas canvas) {
    for (final firework in _fireworks) {
      firework.render(canvas);
    }
  }
}

class Firework {
  Vector2 position;
  final double targetY;
  final Color color;

  bool _exploded = false;
  bool isComplete = false;
  final List<FireworkParticle> _particles = [];
  final _random = Random();

  Firework({
    required this.position,
    required this.targetY,
    required this.color,
  });

  void update(double dt) {
    if (!_exploded) {
      position.y -= 400 * dt;

      if (position.y <= targetY) {
        _explode();
      }
    } else {
      // Update particles
      for (final particle in _particles) {
        particle.position += particle.velocity * dt;
        particle.velocity.y += 150 * dt; // gravity
        particle.alpha -= dt * 0.8;
      }

      _particles.removeWhere((p) => p.alpha <= 0);
      if (_particles.isEmpty) {
        isComplete = true;
      }
    }
  }

  void _explode() {
    _exploded = true;

    // Create particles in a circle
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * pi;
      final speed = 100 + _random.nextDouble() * 100;

      _particles.add(FireworkParticle(
        position: position.clone(),
        velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
        color: color,
      ));
    }
  }

  void render(Canvas canvas) {
    if (!_exploded) {
      // Draw trail
      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(position.x, position.y), 4, paint);

      // Trail
      for (int i = 0; i < 5; i++) {
        final trailPaint = Paint()
          ..color = color.withValues(alpha: 0.3 - i * 0.05);
        canvas.drawCircle(
            Offset(position.x, position.y + i * 10), 3 - i * 0.5, trailPaint);
      }
    } else {
      // Draw particles
      for (final particle in _particles) {
        final paint = Paint()
          ..color = particle.color.withValues(alpha: particle.alpha);
        canvas.drawCircle(
            Offset(particle.position.x, particle.position.y), 3, paint);
      }
    }
  }
}

class FireworkParticle {
  Vector2 position;
  Vector2 velocity;
  Color color;
  double alpha = 1.0;

  FireworkParticle({
    required this.position,
    required this.velocity,
    required this.color,
  });
}

/// Sparkle effect
class Sparkle extends PositionComponent {
  final Vector2 startPosition;
  final Color color;

  double _alpha = 0;
  double _scale = 0;
  late double _animationOffset;
  final _random = Random();

  Sparkle({
    required this.startPosition,
    required this.color,
  }) : super(position: startPosition, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _animationOffset = _random.nextDouble() * 2 * pi;
  }

  @override
  void update(double dt) {
    final time =
        (DateTime.now().millisecondsSinceEpoch / 1000.0) + _animationOffset;
    _alpha = (sin(time * 3) + 1) / 2 * 0.8;
    _scale = 0.5 + (sin(time * 2) + 1) / 4;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withValues(alpha: _alpha);

    // Draw star shape
    final path = Path();
    final size = 8.0 * _scale;

    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi;
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

    // Inner glow
    canvas.drawCircle(Offset.zero, size * 0.3, paint);
  }
}

/// Trophy glow effect
class TrophyGlow extends PositionComponent {
  final Color color;
  final int stars;

  double _time = 0;

  TrophyGlow({
    required Vector2 position,
    required this.color,
    required this.stars,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulseRadius = 80 + sin(_time * 2) * 20;

    // Outer glow
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.3),
        color.withValues(alpha: 0.1),
        color.withValues(alpha: 0),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: Offset.zero, radius: pulseRadius),
      );

    canvas.drawCircle(Offset.zero, pulseRadius, paint);

    // Rays
    if (stars == 3) {
      _drawRays(canvas, pulseRadius * 1.5);
    }
  }

  void _drawRays(Canvas canvas, double length) {
    final rayPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * pi + _time * 0.2;
      const innerRadius = 40.0;
      final outerRadius = length * (0.8 + sin(_time * 3 + i) * 0.2);

      canvas.drawLine(
        Offset(cos(angle) * innerRadius, sin(angle) * innerRadius),
        Offset(cos(angle) * outerRadius, sin(angle) * outerRadius),
        rayPaint,
      );
    }
  }
}

/// Rising star animation
class RisingStar extends PositionComponent {
  final Vector2 startPosition;
  final Vector2 targetPosition;

  double _progress = 0;
  bool _reachedTarget = false;
  double _glowAlpha = 0;

  RisingStar({
    required this.startPosition,
    required this.targetPosition,
  }) : super(position: startPosition.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    if (!_reachedTarget) {
      _progress = (_progress + dt * 2).clamp(0.0, 1.0);

      // Ease out curve
      final easedProgress = 1 - pow(1 - _progress, 3);

      position = Vector2(
        startPosition.x + (targetPosition.x - startPosition.x) * easedProgress,
        startPosition.y + (targetPosition.y - startPosition.y) * easedProgress,
      );

      if (_progress >= 1) {
        _reachedTarget = true;
      }
    } else {
      _glowAlpha =
          (sin(DateTime.now().millisecondsSinceEpoch / 300) + 1) / 2 * 0.5 +
              0.5;
    }
  }

  @override
  void render(Canvas canvas) {
    const starColor = Color(0xFFFFD700);

    // Glow
    if (_reachedTarget) {
      final glowGradient = RadialGradient(
        colors: [
          starColor.withValues(alpha: _glowAlpha * 0.5),
          starColor.withValues(alpha: 0),
        ],
      );

      final glowPaint = Paint()
        ..shader = glowGradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: 30),
        );

      canvas.drawCircle(Offset.zero, 30, glowPaint);
    }

    // Trail while moving
    if (!_reachedTarget) {
      for (int i = 0; i < 5; i++) {
        final trailAlpha = 0.3 - i * 0.05;
        final trailOffset = i * 15.0;

        final paint = Paint()..color = starColor.withValues(alpha: trailAlpha);
        _drawStar(canvas, Offset(0, trailOffset), 12 - i * 2, paint);
      }
    }

    // Main star
    final paint = Paint()..color = starColor;
    _drawStar(canvas, Offset.zero, _reachedTarget ? 20 : 15, paint);
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + cos(angle) * size;
      final y = center.dy + sin(angle) * size;

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
