import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cercados de Coelhos',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const RabbitPens(),
    );
  }
}

class RabbitPens extends StatefulWidget {
  const RabbitPens({super.key});

  @override
  RabbitPensState createState() => RabbitPensState();
}

class RabbitPensState extends State<RabbitPens> {
  int _totalRabbits = 5; // Número inicial de coelhos
  int _totalPens = 3; // Número inicial de cercados
  int _totalWays = 0; // Total de maneiras únicas de distribuir os coelhos

  void _calculateWays() {
    // Usando o conceito de distribuição de bolas em caixas (cercados)
    // Vamos calcular o coeficiente binomial para determinar o número total de maneiras únicas
    int numerator = factorial(_totalRabbits + _totalPens - 1);
    int denominator = factorial(_totalRabbits) * factorial(_totalPens - 1);
    setState(() {
      _totalWays = numerator ~/ denominator;
    });
  }

  int factorial(int n) {
    if (n == 0 || n == 1) {
      return 1;
    }
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  Widget _buildRabbit() {
    return Container(
      padding: const EdgeInsets.all(5),
      child: const Text(
        '🐰',
        style: TextStyle(fontSize: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cercados de Coelhos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Número de coelhos:',
              style: TextStyle(fontSize: 20.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_totalRabbits > 1) {
                        _totalRabbits--;
                        _calculateWays();
                      }
                    });
                  },
                ),
                Text(
                  '$_totalRabbits',
                  style: const TextStyle(fontSize: 20.0),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _totalRabbits++;
                      _calculateWays();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Número de cercados:',
              style: TextStyle(fontSize: 20.0),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_totalPens > 1) {
                        _totalPens--;
                        _calculateWays();
                      }
                    });
                  },
                ),
                Text(
                  '$_totalPens',
                  style: const TextStyle(fontSize: 20.0),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _totalPens++;
                      _calculateWays();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _totalPens,
                  itemBuilder: (BuildContext context, int index) {
                    int rabbitsInPen = _totalRabbits ~/ _totalPens +
                        (index < _totalRabbits % _totalPens ? 1 : 0);
                    return _buildPen(rabbitsInPen);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Text(
              'Total de maneiras únicas: $_totalWays',
              style: const TextStyle(fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPen(int rabbitsInPen) {
    int maxRows = (rabbitsInPen / 3).ceil();
    double cardHeight = maxRows * 50.0;
    return Container(
      padding: const EdgeInsets.all(10),
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'Coelhos:',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: rabbitsInPen,
              itemBuilder: (BuildContext context, int index) {
                return _buildRabbit();
              },
            ),
          ),
        ],
      ),
    );
  }
}
