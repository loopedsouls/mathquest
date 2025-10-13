import 'package:flutter/material.dart';

class MatrixConversionScreen extends StatefulWidget {
  const MatrixConversionScreen({super.key});

  @override
  MatrixConversionScreenState createState() => MatrixConversionScreenState();
}

class MatrixConversionScreenState extends State<MatrixConversionScreen> {
  final TextEditingController _matrixInputController = TextEditingController();
  String _conversionResult = '';
  String _feedbackMessage = '';

  void _convertMatrix(String conversionType) {
    setState(() {
      if (_matrixInputController.text.isEmpty) {
        _feedbackMessage = 'Por favor, insira uma matriz válida.';
        _conversionResult = '';
      } else {
        _feedbackMessage = 'Conversão bem-sucedida!';
        _conversionResult = 'Resultado da $conversionType:\n[Simulação]';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversão de Matrizes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Insira a matriz:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _matrixInputController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Exemplo: [[1, 2], [3, 4]]',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Escolha o tipo de conversão:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _convertMatrix('Conversão para Gráfico'),
                  child: const Text('Para Gráfico'),
                ),
                ElevatedButton(
                  onPressed:
                      () => _convertMatrix('Conversão para Notação Algébrica'),
                  child: const Text('Para Notação Algébrica'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Resultado:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _conversionResult.isEmpty
                    ? 'Nenhum resultado ainda.'
                    : _conversionResult,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            if (_feedbackMessage.isNotEmpty)
              Text(
                _feedbackMessage,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _feedbackMessage.contains('sucesso')
                          ? Colors.green
                          : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
