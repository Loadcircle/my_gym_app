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
  int touchedIndex = -1;

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
            final isTouched = index == touchedIndex;
            final color = MuscleGroups.getColor(data.muscleGroup);
            return PieChartSectionData(
              color: color,
              value: data.volumePercentage,
              title: '${data.volumePercentage.toStringAsFixed(0)}%',
              radius: isTouched ? 55 : 45,
              titleStyle: TextStyle(
                fontSize: isTouched ? 14 : 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titlePositionPercentageOffset: 0.6,
            );
          }).toList(),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse?.touchedSection == null) {
                setState(() => touchedIndex = -1);
                widget.onSectionTapped?.call(-1);
                return;
              }
              final index =
                  pieTouchResponse!.touchedSection!.touchedSectionIndex;
              setState(() => touchedIndex = index);
              widget.onSectionTapped?.call(index);
            },
          ),
        ),
      ),
    );
  }
}
