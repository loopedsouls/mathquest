import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triângulo de Pascal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PascalTriangleScreen(),
    );
  }
}

class PascalTriangleScreen extends StatefulWidget {
  const PascalTriangleScreen({super.key});

  @override
  PascalTriangleScreenState createState() => PascalTriangleScreenState();
}

class PascalTriangleScreenState extends State<PascalTriangleScreen> {
  List<List<int>> pascalTriangle = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triângulo de Pascal'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Insira o número de linhas do triângulo:',
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  int rows = int.tryParse(value) ?? 0;
                  generatePascalTriangle(rows);
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var row in pascalTriangle)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var number in row)
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(number.toString()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para gerar o triângulo de Pascal
// Parâmetro: númeroDeLinhas - o número de linhas desejado no triângulo
void generatePascalTriangle(int numeroDeLinhas) {
    List<List<int>> triangulo = []; // Inicializa uma lista vazia para armazenar o triângulo de Pascal
    
    // Loop para gerar cada linha do triângulo
    for (int linha = 0; linha < numeroDeLinhas; linha++) {
        List<int> linhaAtual = []; // Inicializa uma lista vazia para armazenar os números da linha atual
        
        // Loop para gerar cada número na linha atual
        for (int coluna = 0; coluna <= linha; coluna++) {
            // Condição para verificar se é o primeiro ou último número da linha
            if (coluna == 0 || coluna == linha) {
                // Adiciona 1 à linha, pois os primeiros e últimos números são sempre 1
                linhaAtual.add(1);
            } else {
                // Calcula o valor do número atual como a soma dos dois números acima dele na linha anterior
                int valor = triangulo[linha - 1][coluna - 1] + triangulo[linha - 1][coluna];
                // Adiciona o valor à linha
                linhaAtual.add(valor);
            }
        }
        // Adiciona a linha gerada ao triângulo
        triangulo.add(linhaAtual);
    }
    // Atualiza o triângulo de Pascal com os novos valores
    setState(() {
        pascalTriangle = triangulo;
    });
}}
