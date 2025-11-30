import 'package:flutter/material.dart';

/// Application Animation Configuration
class AppAnimations {
  // === DURATION CONSTANTS ===
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 800);

  // === CURVE CONSTANTS ===
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve linearCurve = Curves.linear;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  // === PAGE TRANSITION ANIMATIONS ===
  static Route<T> slideFromRight<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: defaultCurve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: normal,
    );
  }

  static Route<T> slideFromLeft<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: defaultCurve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: normal,
    );
  }

  static Route<T> slideFromBottom<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: defaultCurve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: normal,
    );
  }

  static Route<T> fadeIn<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: normal,
    );
  }

  static Route<T> scaleUp<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween =
            Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: defaultCurve));
        return ScaleTransition(scale: animation.drive(tween), child: child);
      },
      transitionDuration: normal,
    );
  }

  // === WIDGET ANIMATIONS ===
  static Widget fadeTransition({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(opacity: animation, child: child);
  }

  static Widget slideTransition({
    required Widget child,
    required Animation<double> animation,
    Offset begin = const Offset(0.0, 0.1),
    Offset end = Offset.zero,
  }) {
    var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: defaultCurve));
    return SlideTransition(position: animation.drive(tween), child: child);
  }

  static Widget scaleTransition({
    required Widget child,
    required Animation<double> animation,
    double begin = 0.95,
    double end = 1.0,
  }) {
    var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: defaultCurve));
    return ScaleTransition(scale: animation.drive(tween), child: child);
  }

  // === TWEEN BUILDERS ===
  static Tween<double> opacityTween({double begin = 0.0, double end = 1.0}) {
    return Tween(begin: begin, end: end);
  }

  static Tween<Offset> slideTween({
    Offset begin = const Offset(0.0, 0.1),
    Offset end = Offset.zero,
  }) {
    return Tween(begin: begin, end: end);
  }

  static Tween<double> scaleTween({double begin = 0.95, double end = 1.0}) {
    return Tween(begin: begin, end: end);
  }

  // === STAGGERED ANIMATION HELPERS ===
  static Animation<double> createStaggeredAnimation({
    required AnimationController controller,
    required double begin,
    required double end,
    Curve curve = defaultCurve,
  }) {
    return Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(begin, end, curve: curve),
      ),
    );
  }

  /// Create multiple staggered intervals for a list of items
  static List<Animation<double>> createStaggeredList({
    required AnimationController controller,
    required int itemCount,
    double delayBetweenItems = 0.1,
    Curve curve = defaultCurve,
  }) {
    return List.generate(itemCount, (index) {
      final begin = index * delayBetweenItems;
      final end = (begin + 0.5).clamp(0.0, 1.0);
      return createStaggeredAnimation(
        controller: controller,
        begin: begin.clamp(0.0, 1.0),
        end: end,
        curve: curve,
      );
    });
  }
}

/// Bounce Animation Widget
class BounceWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scale;

  const BounceWidget({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.scale = 0.95,
  });

  @override
  State<BounceWidget> createState() => _BounceWidgetState();
}

class _BounceWidgetState extends State<BounceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.bounceCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void bounce() {
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}

/// Shake Animation Widget
class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double distance;
  final int shakeCount;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.distance = 10.0,
    this.shakeCount = 3,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final sineValue =
            _sineCurve(_animation.value, widget.shakeCount) * widget.distance;
        return Transform.translate(
          offset: Offset(sineValue, 0),
          child: widget.child,
        );
      },
    );
  }

  double _sineCurve(double t, int shakeCount) {
    return (1 - t) *
        (0.5 -
            0.5 *
                (0.5 -
                        0.5 *
                            (1 -
                                (2 *
                                        (shakeCount *
                                            t *
                                            3.14159265359) /
                                        3.14159265359)
                                    .abs()))
                    .clamp(0.0, 1.0));
  }
}

/// Pulse Animation Widget
class PulseWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: widget.minScale, end: widget.maxScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
