import 'package:flutter/material.dart';

class ContinueScreen extends StatelessWidget {
  const ContinueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Continuar Jogo')),
      body: const Center(
        child: Text('Tela de Continuação'),
      ),
    );
  }
}
