import 'package:flutter/material.dart';

class Character {
  final String name;
  final Map<String, String> expressions; // expressão: caminho da imagem
  final String sprite;
  final Offset position;

  Character({
    required this.name,
    required this.expressions,
    required this.sprite,
    required this.position,
  });

  String getExpressionSprite(String expression) {
    return expressions[expression] ?? sprite;
  }

  Character copyWith({
    String? name,
    Map<String, String>? expressions,
    String? sprite,
    Offset? position,
  }) {
    return Character(
      name: name ?? this.name,
      expressions: expressions ?? this.expressions,
      sprite: sprite ?? this.sprite,
      position: position ?? this.position,
    );
  }
}
