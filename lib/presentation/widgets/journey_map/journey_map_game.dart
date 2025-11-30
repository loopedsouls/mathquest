import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

/// Data for a journey node
class JourneyNodeData {
  final String id;
  final String title;
  final String subtitle;
  final JourneyNodeStatus status;
  final int stars;
  final int order;

  const JourneyNodeData({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.status,
    this.stars = 0,
    required this.order,
  });
}

enum JourneyNodeStatus { locked, current, completed }

/// Callback type for node taps
typedef OnNodeTap = void Function(JourneyNodeData node);

/// Main Flame game for the journey map
class JourneyMapGame extends FlameGame with ScrollDetector, ScaleDetector {
  final List<JourneyNodeData> nodes;
  final OnNodeTap onNodeTap;
  final Color bgColor;
  final Color pathColor;
  final Color completedColor;
  final Color currentColor;
  final Color lockedColor;

  JourneyMapGame({
    required this.nodes,
    required this.onNodeTap,
    this.bgColor = const Color(0xFF1a1a2e),
    this.pathColor = const Color(0xFF4a4a6a),
    this.completedColor = const Color(0xFF4CAF50),
    this.currentColor = const Color(0xFFFFD700),
    this.lockedColor = const Color(0xFF666666),
  });

  late CameraComponent cameraComponent;
  late World gameWorld;
  double _currentScale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 2.0;

  @override
  Future<void> onLoad() async {
    gameWorld = World();
    cameraComponent = CameraComponent(world: gameWorld);
    
    addAll([gameWorld, cameraComponent]);

    // Add path first (behind nodes)
    await _addPath();
    
    // Add nodes
    await _addNodes();

    // Center camera on first uncompleted node
    _centerOnCurrentNode();
  }

  Future<void> _addPath() async {
    if (nodes.length < 2) return;

    for (int i = 0; i < nodes.length - 1; i++) {
      final startPos = _getNodePosition(i);
      final endPos = _getNodePosition(i + 1);
      
      final isCompleted = nodes[i].status == JourneyNodeStatus.completed;
      
      gameWorld.add(
        JourneyPath(
          start: startPos,
          end: endPos,
          color: isCompleted ? completedColor.withValues(alpha: 0.6) : pathColor,
          isCompleted: isCompleted,
        ),
      );
    }
  }

  Future<void> _addNodes() async {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final position = _getNodePosition(i);
      
      gameWorld.add(
        JourneyNode(
          data: node,
          position: position,
          completedColor: completedColor,
          currentColor: currentColor,
          lockedColor: lockedColor,
          onTap: () => onNodeTap(node),
        ),
      );
    }
  }

  Vector2 _getNodePosition(int index) {
    // Create a winding path - use fixed width since size may not be ready
    const nodeSpacing = 150.0;
    const amplitude = 80.0;
    const centerX = 200.0; // Fixed center position
    
    final y = index * nodeSpacing + 150.0;
    final x = centerX + sin(index * 0.8) * amplitude;
    
    return Vector2(x, y);
  }

  void _centerOnCurrentNode() {
    int targetIndex = 0;
    for (int i = 0; i < nodes.length; i++) {
      if (nodes[i].status == JourneyNodeStatus.current) {
        targetIndex = i;
        break;
      }
      if (nodes[i].status != JourneyNodeStatus.completed) {
        targetIndex = i;
        break;
      }
    }
    
    final targetPos = _getNodePosition(targetIndex);
    cameraComponent.viewfinder.position = Vector2(targetPos.x, targetPos.y - 200);
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final delta = info.scrollDelta.global.y;
    final newScale = (_currentScale - delta * 0.001).clamp(_minScale, _maxScale);
    _currentScale = newScale;
    cameraComponent.viewfinder.zoom = _currentScale;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Handle drag
    if (info.pointerCount == 1) {
      final delta = info.delta.global;
      cameraComponent.viewfinder.position -= Vector2(delta.x / _currentScale, delta.y / _currentScale);
    }
    // Handle pinch zoom
    else if (info.pointerCount == 2) {
      final scaleChange = info.scale.global.x; // Use x component for uniform scaling
      final newScale = (_currentScale * scaleChange).clamp(_minScale, _maxScale);
      _currentScale = newScale;
      cameraComponent.viewfinder.zoom = _currentScale;
    }
  }

  @override
  Color backgroundColor() => bgColor;
}

/// Path between nodes
class JourneyPath extends Component {
  final Vector2 start;
  final Vector2 end;
  final Color color;
  final bool isCompleted;

  JourneyPath({
    required this.start,
    required this.end,
    required this.color,
    this.isCompleted = false,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isCompleted ? 6 : 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw curved path
    final path = Path();
    path.moveTo(start.x, start.y);
    
    final controlPoint1 = Vector2(
      start.x + (end.x - start.x) * 0.5 + 30,
      start.y + (end.y - start.y) * 0.3,
    );
    final controlPoint2 = Vector2(
      start.x + (end.x - start.x) * 0.5 - 30,
      start.y + (end.y - start.y) * 0.7,
    );
    
    path.cubicTo(
      controlPoint1.x, controlPoint1.y,
      controlPoint2.x, controlPoint2.y,
      end.x, end.y,
    );

    canvas.drawPath(path, paint);

    // Draw dashed effect for incomplete paths
    if (!isCompleted) {
      final dashPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, dashPaint);
    }
  }
}

/// Interactive node on the journey map
class JourneyNode extends PositionComponent with TapCallbacks {
  final JourneyNodeData data;
  final Color completedColor;
  final Color currentColor;
  final Color lockedColor;
  final VoidCallback onTap;

  late Color _nodeColor;
  late Color _glowColor;
  double _pulseValue = 0;
  bool _isAnimating = false;

  JourneyNode({
    required this.data,
    required Vector2 position,
    required this.completedColor,
    required this.currentColor,
    required this.lockedColor,
    required this.onTap,
  }) : super(
          position: position,
          size: Vector2(80, 80),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    _updateColors();
    
    // Add pulse animation for current node
    if (data.status == JourneyNodeStatus.current) {
      _isAnimating = true;
      add(
        ScaleEffect.by(
          Vector2.all(1.1),
          EffectController(
            duration: 0.8,
            reverseDuration: 0.8,
            infinite: true,
          ),
        ),
      );
    }
  }

  void _updateColors() {
    switch (data.status) {
      case JourneyNodeStatus.completed:
        _nodeColor = completedColor;
        _glowColor = completedColor.withValues(alpha: 0.4);
        break;
      case JourneyNodeStatus.current:
        _nodeColor = currentColor;
        _glowColor = currentColor.withValues(alpha: 0.5);
        break;
      case JourneyNodeStatus.locked:
        _nodeColor = lockedColor;
        _glowColor = lockedColor.withValues(alpha: 0.2);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimating) {
      _pulseValue += dt * 3;
    }
  }

  @override
  void render(Canvas canvas) {
    final center = size / 2;

    // Draw glow
    if (data.status != JourneyNodeStatus.locked) {
      final glowRadius = 50.0 + (sin(_pulseValue) * 5);
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            _glowColor,
            _glowColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(center.x, center.y),
          radius: glowRadius,
        ));
      canvas.drawCircle(Offset(center.x, center.y), glowRadius, glowPaint);
    }

    // Draw main circle
    final circlePaint = Paint()..color = _nodeColor;
    canvas.drawCircle(Offset(center.x, center.y), 35, circlePaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(center.x, center.y), 35, borderPaint);

    // Draw icon
    _drawIcon(canvas, center);

    // Draw stars for completed
    if (data.status == JourneyNodeStatus.completed && data.stars > 0) {
      _drawStars(canvas, center);
    }

    // Draw order number
    _drawOrderNumber(canvas, center);
  }

  void _drawIcon(Canvas canvas, Vector2 center) {
    final iconPaint = Paint()..color = Colors.white;
    
    switch (data.status) {
      case JourneyNodeStatus.completed:
        // Checkmark
        final path = Path();
        path.moveTo(center.x - 12, center.y);
        path.lineTo(center.x - 4, center.y + 10);
        path.lineTo(center.x + 14, center.y - 8);
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        break;
      case JourneyNodeStatus.current:
        // Play icon
        final path = Path();
        path.moveTo(center.x - 8, center.y - 12);
        path.lineTo(center.x + 12, center.y);
        path.lineTo(center.x - 8, center.y + 12);
        path.close();
        canvas.drawPath(path, iconPaint);
        break;
      case JourneyNodeStatus.locked:
        // Lock icon
        final lockBody = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(center.x, center.y + 4), width: 20, height: 16),
          const Radius.circular(3),
        );
        canvas.drawRRect(lockBody, iconPaint);
        
        final lockArc = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(center.x, center.y - 4), width: 14, height: 14),
          3.14,
          3.14,
          false,
          lockArc,
        );
        break;
    }
  }

  void _drawStars(Canvas canvas, Vector2 center) {
    final starColor = Colors.amber;
    final starSize = 10.0;
    
    for (int i = 0; i < 3; i++) {
      final isFilled = i < data.stars;
      final x = center.x - 20 + (i * 20);
      final y = center.y + 50;
      
      _drawStar(
        canvas,
        Offset(x, y),
        starSize,
        isFilled ? starColor : Colors.grey.withValues(alpha: 0.5),
        isFilled,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Color color, bool filled) {
    final path = Path();
    final double halfSize = size / 2;
    
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * 3.14159 / 5) - 3.14159 / 2;
      final x = center.dx + cos(angle) * halfSize;
      final y = center.dy + sin(angle) * halfSize;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawPath(path, paint);
  }

  void _drawOrderNumber(Canvas canvas, Vector2 center) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${data.order}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.x - textPainter.width / 2, center.y - 55),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onTap();
  }
}
