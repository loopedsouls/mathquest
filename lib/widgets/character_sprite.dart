// CharacterSprite widget stub
import 'package:flutter/material.dart';

class CharacterSprite extends StatelessWidget {
  final String spritePath;
  final double width;
  final double height;
  final Offset position;
  final double opacity;
  final Duration fadeDuration;

  const CharacterSprite({
    required this.spritePath,
    this.width = 200,
    this.height = 400,
    this.position = Offset.zero,
    this.opacity = 1.0,
    this.fadeDuration = const Duration(milliseconds: 500),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: fadeDuration,
        child: Image.asset(
          spritePath,
          width: width,
          height: height,
        ),
      ),
    );
  }
}
