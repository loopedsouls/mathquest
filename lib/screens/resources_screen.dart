import 'package:flutter/material.dart';

class ResourcesScreen extends StatelessWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recursos Educacionais'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Tutorial sobre Conversões de Registros'),
            onTap: () {
              // Ação para abrir o tutorial
            },
          ),
          ListTile(
            title: const Text('Estudo de Caso: Aplicações Reais'),
            onTap: () {
              // Ação para abrir o estudo de caso
            },
          ),
        ],
      ),
    );
  }
}
