import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final String imagePath;
  final Widget? child;

  const BackgroundWidget({required this.imagePath, this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}
