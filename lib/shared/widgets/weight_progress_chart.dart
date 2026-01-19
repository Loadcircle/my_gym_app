import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../features/exercises/data/models/weight_record_model.dart';

/// Widget que muestra un grafico de linea con la evolucion del peso.
/// Requiere al menos 2 registros para mostrar el grafico.
class WeightProgressChart extends StatelessWidget {
  final List<WeightRecordModel> records;
  final double height;

  const WeightProgressChart({
    super.key,
    required this.records,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Necesitamos al menos 2 puntos para un grafico
    if (records.length < 2) {
      return const SizedBox.shrink();
    }

    // Ordenar por fecha ascendente
    final sortedRecords = List<WeightRecordModel>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Tomar los ultimos 10 registros para no saturar el grafico
    final displayRecords = sortedRecords.length > 10
        ? sortedRecords.sublist(sortedRecords.length - 10)
        : sortedRecords;

    // Crear puntos para el grafico
    final spots = <FlSpot>[];
    for (var i = 0; i < displayRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayRecords[i].weight));
    }

    // Calcular min y max para el eje Y
    final weights = displayRecords.map((r) => r.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.2;
    final yMin = (minWeight - padding).clamp(0.0, double.infinity);
    final yMax = maxWeight + padding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evolucion de Peso',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateInterval(yMin, yMax),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= displayRecords.length) {
                        return const SizedBox.shrink();
                      }
                      final date = displayRecords[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    interval: _calculateInterval(yMin, yMax),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (displayRecords.length - 1).toDouble(),
              minY: yMin,
              maxY: yMax,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.background,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => AppColors.cardBackground,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final record = displayRecords[index];
                      return LineTooltipItem(
                        '${record.weight}kg\n${record.sets}x${record.reps}',
                        const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Indicador de tendencia
        _buildTrendIndicator(displayRecords),
      ],
    );
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 25) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  Widget _buildTrendIndicator(List<WeightRecordModel> records) {
    if (records.length < 2) return const SizedBox.shrink();

    final first = records.first.weight;
    final last = records.last.weight;
    final diff = last - first;
    final percentage = ((diff / first) * 100).abs();

    final isUp = diff > 0;
    final isFlat = diff.abs() < 0.5;

    IconData icon;
    Color color;
    String text;

    if (isFlat) {
      icon = Icons.trending_flat;
      color = AppColors.textSecondary;
      text = 'Estable';
    } else if (isUp) {
      icon = Icons.trending_up;
      color = AppColors.success;
      text = '+${percentage.toStringAsFixed(1)}%';
    } else {
      icon = Icons.trending_down;
      color = AppColors.warning;
      text = '-${percentage.toStringAsFixed(1)}%';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'desde ${records.first.date.day}/${records.first.date.month}',
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
