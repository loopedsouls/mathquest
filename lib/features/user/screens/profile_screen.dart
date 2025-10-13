import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Aprendizagem'),
      ),
      body: const Center(
        child: Text('Progresso e Metas Personalizadas'),
      ),
    );
  }
}
