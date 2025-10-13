import 'package:flutter/material.dart';
import 'package:mathquest/features/exercise_system/exercise_screen.dart';
import 'package:mathquest/features/dashboard/dashboard_screen.dart';
import 'package:mathquest/features/matrix_tools/matrix_conversion_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(), // Tema claro padrão do Material Design
      darkTheme: ThemeData.dark(), // Tema escuro padrão do Material Design
      themeMode: ThemeMode.system, // Adapta-se ao tema do sistema
      home: const DashboardScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/matrix_conversion': (context) => const MatrixConversionScreen(),
        '/exercise': (context) => const ExerciseScreen(),
      },
    );
  }
}

class MatrixVisionScreen extends StatelessWidget {
  const MatrixVisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix Vision')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone de matriz
            CustomPaint(size: const Size(80, 80), painter: MatrixIconPainter()),
            const SizedBox(height: 20),
            // Texto principal
            const Text(
              'TRRSMATRIXVISION',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Subtítulo
            const Text(
              'Explore mathematical\nrepresentations and conversions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Botão "Enter"
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text('Enter', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// CustomPainter para desenhar o ícone de matriz
class MatrixIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Desenhar o quadrado com bordas abertas
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      paint,
    ); // Linha esquerda
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * 0.3, 0),
      paint,
    ); // Linha superior esquerda
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width, 0),
      paint,
    ); // Linha superior direita
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, size.height),
      paint,
    ); // Linha direita
    canvas.drawLine(
      Offset(size.width, size.height * 0.7),
      Offset(size.width, size.height),
      paint,
    ); // Linha inferior direita
    canvas.drawLine(
      Offset(size.width * 0.3, size.height),
      Offset(0, size.height),
      paint,
    ); // Linha inferior esquerda

    // Desenhar os pontos da matriz
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const dotRadius = 4.0;
    final dots = [
      Offset(size.width * 0.3, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.7),
    ];

    for (var dot in dots) {
      canvas.drawCircle(dot, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
