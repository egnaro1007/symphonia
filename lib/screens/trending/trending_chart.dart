import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendingChart extends StatelessWidget {
  const TrendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const hours = ['14', '15', '16', '17', '18', '19',
                      '20', '21', '22', '23', '00', '01'];
                    if (value.toInt() >= 0 && value.toInt() < hours.length) {
                      return Text(
                        hours[value.toInt()],
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // Blue line (top line)
              LineChartBarData(
                spots: const [
                  FlSpot(0, 7.0),
                  FlSpot(1, 6.8),
                  FlSpot(2, 6.5),
                  FlSpot(3, 7.2),
                  FlSpot(4, 7.0),
                  FlSpot(5, 6.8),
                  FlSpot(6, 6.5),
                  FlSpot(7, 6.2),
                  FlSpot(8, 5.8),
                  FlSpot(9, 5.4),
                  FlSpot(10, 4.5),
                  FlSpot(11, 4.0),
                ],
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.blue,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
              // Orange line (middle line)
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3.5),
                  FlSpot(1, 3.7),
                  FlSpot(2, 3.8),
                  FlSpot(3, 4.5),
                  FlSpot(4, 4.3),
                  FlSpot(5, 4.2),
                  FlSpot(6, 4.1),
                  FlSpot(7, 4.0),
                  FlSpot(8, 3.9),
                  FlSpot(9, 3.7),
                  FlSpot(10, 3.0),
                  FlSpot(11, 2.5),
                ],
                isCurved: true,
                color: Colors.orange,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
              // Green line (bottom line)
              LineChartBarData(
                spots: const [
                  FlSpot(0, 1.5),
                  FlSpot(1, 1.5),
                  FlSpot(2, 1.5),
                  FlSpot(3, 1.6),
                  FlSpot(4, 1.6),
                  FlSpot(5, 1.5),
                  FlSpot(6, 1.5),
                  FlSpot(7, 1.4),
                  FlSpot(8, 1.4),
                  FlSpot(9, 1.3),
                  FlSpot(10, 1.3),
                  FlSpot(11, 1.2),
                ],
                isCurved: true,
                color: Colors.teal,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            minX: 0,
            maxX: 11,
            minY: 0,
            maxY: 8,
          ),
        ),
      ),
    );
  }
}