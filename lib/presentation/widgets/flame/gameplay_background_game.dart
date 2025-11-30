import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Animated background for gameplay screen
class GameplayBackgroundGame extends FlameGame {
  final Color primaryColor;
  final bool isCorrectAnimation;
  final bool isWrongAnimation;

  GameplayBackgroundGame({
    this.primaryColor = const Color(0xFF6C63FF),
    this.isCorrectAnimation = false,
    this.isWrongAnimation = false,
  });

  final List<GridLine> _gridLines = [];
  final List<FloatingNumber> _floatingNumbers = [];
  final _random = Random();

  @override
  Future<void> onLoad() async {
    // Create grid pattern
    _createGrid();

    // Add floating numbers
    for (int i = 0; i < 10; i++) {
      _floatingNumbers.add(FloatingNumber(
        number: '${_random.nextInt(10)}',
        startPosition: Vector2(
          _random.nextDouble() * size.x,
          _random.nextDouble() * size.y,
        ),
        color: primaryColor,
      ));
    }

    for (final number in _floatingNumbers) {
      add(number);
    }

    // Add subtle particle effect
    add(SubtleParticles(
      bounds: size,
      color: primaryColor,
    ));
  }

  void _createGrid() {
    // Vertical lines
    for (double x = 0; x < size.x; x += 50) {
      _gridLines.add(GridLine(
        start: Vector2(x, 0),
        end: Vector2(x, size.y),
      ));
    }

    // Horizontal lines
    for (double y = 0; y < size.y; y += 50) {
      _gridLines.add(GridLine(
        start: Vector2(0, y),
        end: Vector2(size.x, y),
      ));
    }
  }

  void triggerCorrectAnimation() {
    add(CorrectFlash(bounds: size));
  }

  void triggerWrongAnimation() {
    add(WrongShake(game: this));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (final line in _gridLines) {
      canvas.drawLine(
        Offset(line.start.x, line.start.y),
        Offset(line.end.x, line.end.y),
        gridPaint,
      );
    }
  }

  @override
  Color backgroundColor() => const Color(0xFF1a1a2e);
}

class GridLine {
  final Vector2 start;
  final Vector2 end;

  GridLine({required this.start, required this.end});
}

/// Floating number animation
class FloatingNumber extends PositionComponent {
  final String number;
  final Vector2 startPosition;
  final Color color;

  double _time = 0;
  late double _floatSpeed;
  late double _floatAmplitude;
  final _random = Random();

  FloatingNumber({
    required this.number,
    required this.startPosition,
    required this.color,
  }) : super(position: startPosition.clone(), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _floatSpeed = 0.3 + _random.nextDouble() * 0.5;
    _floatAmplitude = 10 + _random.nextDouble() * 20;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    position.y = startPosition.y + sin(_time * _floatSpeed) * _floatAmplitude;
    position.x = startPosition.x +
        cos(_time * _floatSpeed * 0.7) * _floatAmplitude * 0.5;
  }

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: TextStyle(
          color: color.withValues(alpha: 0.1),
          fontSize: 60,
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

/// Subtle background particles
class SubtleParticles extends Component {
  final Vector2 bounds;
  final Color color;

  final List<_SubtleParticle> _particles = [];
  final _random = Random();

  SubtleParticles({
    required this.bounds,
    required this.color,
  });

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 15; i++) {
      _particles.add(_SubtleParticle(
        position: Vector2(
          _random.nextDouble() * bounds.x,
          _random.nextDouble() * bounds.y,
        ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 10,
          -5 - _random.nextDouble() * 10,
        ),
        size: 2 + _random.nextDouble() * 3,
        alpha: 0.1 + _random.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final particle in _particles) {
      particle.position += particle.velocity * dt;

      // Wrap
      if (particle.position.y < -10) {
        particle.position.y = bounds.y + 10;
        particle.position.x = _random.nextDouble() * bounds.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()..color = color.withValues(alpha: particle.alpha);
      canvas.drawCircle(
        Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }
}

class _SubtleParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double alpha;

  _SubtleParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.alpha,
  });
}

/// Flash effect for correct answer
class CorrectFlash extends Component {
  final Vector2 bounds;
  double _alpha = 0.3;

  CorrectFlash({required this.bounds});

  @override
  void update(double dt) {
    _alpha -= dt * 0.5;
    if (_alpha <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: _alpha)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, bounds.x, bounds.y),
      paint,
    );
  }
}

/// Shake effect for wrong answer
class WrongShake extends Component {
  final FlameGame game;
  double _time = 0;
  static const double _duration = 0.5;

  WrongShake({required this.game});

  @override
  void update(double dt) {
    _time += dt;
    if (_time >= _duration) {
      game.camera.viewfinder.position = Vector2.zero();
      removeFromParent();
    } else {
      final intensity = (1 - _time / _duration) * 10;
      game.camera.viewfinder.position = Vector2(
        sin(_time * 50) * intensity,
        cos(_time * 50) * intensity,
      );
    }
  }
}

/// Timer arc animation component
class TimerArc extends PositionComponent {
  final double duration;
  final Color color;

  double _remaining;

  TimerArc({
    required Vector2 position,
    required this.duration,
    this.color = Colors.amber,
  })  : _remaining = duration,
        super(position: position, size: Vector2.all(60), anchor: Anchor.center);

  void updateTime(double remaining) {
    _remaining = remaining;
  }

  @override
  void render(Canvas canvas) {
    final progress = _remaining / duration;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 25, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progress > 0.3 ? color : Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.x / 2, size.y / 2), radius: 25),
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );

    // Time text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${_remaining.ceil()}',
        style: TextStyle(
          color: progress > 0.3 ? Colors.white : Colors.red,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2,
          size.y / 2 - textPainter.height / 2),
    );
  }
}
