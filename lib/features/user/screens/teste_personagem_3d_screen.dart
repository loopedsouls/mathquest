import 'package:flutter/material.dart';
import '../widgets/personagem_3d_widget.dart';
import 'package:mathquest/features/theme/app_theme.dart';

class TestePersonagem3DScreen extends StatelessWidget {
  const TestePersonagem3DScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor,
      appBar: AppBar(
        title: const Text('Teste Personagem 3D'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Personagem 3D Estilo Roblox',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            Personagem3DWidget(
              itensEquipados: {
                'cabeca': 'chapeu_mago',
                'corpo': 'armadura_lendaria',
                'pernas': 'calcas_epicas',
                'acessorio': 'capa_voadora',
              },
              width: 250,
              height: 350,
              nome: 'Matemático',
              interactive: true,
            ),
            SizedBox(height: 32),
            Text(
              'Arraste para rotacionar',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
