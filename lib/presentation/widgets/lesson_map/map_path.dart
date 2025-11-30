import 'package:flutter/material.dart';

/// Connecting path between lesson nodes
class MapPath extends StatelessWidget {
  final double height;

  const MapPath({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _PathPainter(
          color: Colors.grey[300]!,
        ),
        size: Size(4, height),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final Color color;

  _PathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw dotted line
    const dashHeight = 6.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
