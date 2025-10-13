import 'package:flutter/material.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ExerciseScreenState createState() => ExerciseScreenState();
}

class ExerciseScreenState extends State<ExerciseScreen> {
  final TextEditingController _answerController = TextEditingController();
  String _feedbackMessage = '';
  final String _correctAnswer =
      '[[1, 0], [0, 1]]'; // Exemplo de resposta correta
  String _suggestion = '';

  void _checkAnswer() {
    setState(() {
      if (_answerController.text.isEmpty) {
        _feedbackMessage = 'Por favor, insira uma resposta.';
        _suggestion = '';
      } else if (_answerController.text == _correctAnswer) {
        _feedbackMessage = 'Resposta correta! Parabéns!';
        _suggestion = '';
      } else {
        _feedbackMessage = 'Resposta incorreta.';
        _suggestion = 'Sugestão: Revise os passos de conversão ou operação.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios de Matrizes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercício:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Resolva o seguinte sistema de matrizes e insira a resposta:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '[[2, 1], [1, 2]] * [[x], [y]] = [[3], [3]]',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sua Resposta:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                hintText: 'Exemplo: [[1, 0], [0, 1]]',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkAnswer,
              child: const Text('Verificar Resposta'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Feedback:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _feedbackMessage,
              style: TextStyle(
                fontSize: 16,
                color:
                    _feedbackMessage.contains('correta')
                        ? Colors.green
                        : Colors.red,
              ),
            ),
            if (_suggestion.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_suggestion, style: const TextStyle(fontSize: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
