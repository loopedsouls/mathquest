import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class InteractiveChart extends StatelessWidget {
  final List<FlSpot> spots;
  final bool animate;

  const InteractiveChart(this.spots, {super.key, required this.animate});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
          ),
        ],
      ),
    );
  }
}
