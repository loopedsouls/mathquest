import 'package:flutter/cupertino.dart';
import 'screens/tutoria_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title:
          'Sistema de Tutoria Inteligente de Matemática Desplugado com IA Generativa',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.dark,
      ),
      home: TutoriaScreen(),
    );
  }
}
