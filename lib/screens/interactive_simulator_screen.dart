import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class InteractiveSimulatorScreen extends StatefulWidget {
  const InteractiveSimulatorScreen({super.key});

  @override
  InteractiveSimulatorScreenState createState() =>
      InteractiveSimulatorScreenState();
}

class InteractiveSimulatorScreenState
    extends State<InteractiveSimulatorScreen> {
  // Variáveis para armazenar os coeficientes da equação quadrática
  double _a = 1;
  double _b = 0;
  double _c = 0;

  // Função para gerar os pontos do gráfico baseado nos coeficientes
  List<ChartData> _getChartData() {
    List<ChartData> data = [];
    for (double x = -10; x <= 10; x += 0.1) {
      double y = _a * x * x + _b * x + _c;
      data.add(ChartData(x, y));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulador Interativo'),
      ),
      body: Column(
        children: [
          // Exibição do gráfico
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: const NumericAxis(minimum: -10, maximum: 10),
              primaryYAxis: const NumericAxis(minimum: -10, maximum: 10),
              series: <CartesianSeries<ChartData, double>>[
                LineSeries<ChartData, double>(
                  dataSource: _getChartData(),
                  xValueMapper: (ChartData data, _) => data.x,
                  yValueMapper: (ChartData data, _) => data.y,
                )
              ],
            ),
          ),
          // Exibição da equação correspondente
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Math.tex(
              r'f(x) = ' +
                  _a.toStringAsFixed(2) +
                  r'x^2 + ' +
                  _b.toStringAsFixed(2) +
                  r'x + ' +
                  _c.toStringAsFixed(2),
              textStyle: const TextStyle(fontSize: 24),
            ),
          ),
          // Sliders para ajustar os coeficientes
          _buildSlider('a', _a, (value) {
            setState(() {
              _a = value;
            });
          }),
          _buildSlider('b', _b, (value) {
            setState(() {
              _b = value;
            });
          }),
          _buildSlider('c', _c, (value) {
            setState(() {
              _c = value;
            });
          }),
        ],
      ),
    );
  }

  // Função para construir um slider para ajustar um coeficiente
  Widget _buildSlider(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text('$label = ${value.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18)),
        Slider(
          value: value,
          min: -10,
          max: 10,
          divisions: 200,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Classe para armazenar os dados do gráfico
class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}
