import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/muscle_groups.dart';
import '../../../../core/services/progress_calculation_service.dart';

/// Gráfico donut de distribución muscular con interacción táctil.
class MuscleDonutChart extends StatefulWidget {
  final List<MuscleDistributionEntry> distribution;
  final ValueChanged<int>? onSectionTapped;

  const MuscleDonutChart({
    super.key,
    required this.distribution,
    this.onSectionTapped,
  });

  @override
  State<MuscleDonutChart> createState() => _MuscleDonutChartState();
}

class _MuscleDonutChartState extends State<MuscleDonutChart> {
  int _pressedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.distribution.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: widget.distribution.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final isPressed = index == _pressedIndex;
            final color = MuscleGroups.getColor(data.muscleGroup);
            return PieChartSectionData(
              color: color,
              value: data.volumePercentage,
              title: '${data.volumePercentage.toStringAsFixed(0)}%',
              radius: isPressed ? 55 : 45,
              titleStyle: TextStyle(
                fontSize: isPressed ? 14 : 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            );
          }).toList(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (!mounted) return;
              final section = pieTouchResponse?.touchedSection;
              final newIndex =
                  (event.isInterestedForInteractions && section != null)
                      ? section.touchedSectionIndex
                      : -1;

              // Feedback visual (sección agrandada mientras se presiona).
              if (_pressedIndex != newIndex) {
                setState(() => _pressedIndex = newIndex);
              }

              // Notifica al padre en cualquier evento interesado con sección válida.
              // El padre es idempotente (ignora el mismo índice repetido),
              // así que no importa si fl_chart dispara múltiples eventos.
              if (newIndex >= 0) {
                widget.onSectionTapped?.call(newIndex);
              }
            },
          ),
        ),
      ),
    );
  }
}
