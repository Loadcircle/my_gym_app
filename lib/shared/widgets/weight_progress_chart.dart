import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../features/exercises/data/models/weight_record_model.dart';
import '../../l10n/app_localizations.dart';

/// Widget que muestra un grafico de linea con la evolucion del peso.
/// Requiere al menos 2 registros para mostrar el grafico.
class WeightProgressChart extends StatefulWidget {
  final List<WeightRecordModel> records;
  final double height;

  const WeightProgressChart({
    super.key,
    required this.records,
    this.height = 200,
  });

  @override
  State<WeightProgressChart> createState() => _WeightProgressChartState();
}

class _WeightProgressChartState extends State<WeightProgressChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.records.length < 2) return const SizedBox.shrink();

    final sortedRecords = List<WeightRecordModel>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final deduplicatedRecords = _deduplicateRecords(sortedRecords);

    if (deduplicatedRecords.length < 2) return const SizedBox.shrink();

    final displayRecords = deduplicatedRecords.length > 10
        ? deduplicatedRecords.sublist(deduplicatedRecords.length - 10)
        : deduplicatedRecords;

    final spots = <FlSpot>[];
    for (var i = 0; i < displayRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayRecords[i].weight));
    }

    final weights = displayRecords.map((r) => r.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.2;
    final yMin = (minWeight - padding).clamp(0.0, double.infinity);
    final yMax = maxWeight + padding;

    // Clamp selected index in case records changed
    final selectedIndex = _selectedIndex != null &&
            _selectedIndex! < displayRecords.length
        ? _selectedIndex
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weightEvolution,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: widget.height,
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
                      final isSelected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                        l10n.weightAxisLabel(value.toStringAsFixed(1)),
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
                      final isSelected = index == selectedIndex;
                      return FlDotCirclePainter(
                        radius: isSelected ? 6 : 4,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary,
                        strokeWidth: isSelected ? 3 : 2,
                        strokeColor: isSelected
                            ? AppColors.cardBackground
                            : AppColors.background,
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
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  if (!event.isInterestedForInteractions) return;
                  final index =
                      response?.lineBarSpots?.firstOrNull?.x.toInt();
                  if (index == null || index == _selectedIndex) return;
                  setState(() => _selectedIndex = index);
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  getTooltipItems: (spots) =>
                      spots.map((_) => null).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Panel inferior: detalle del punto seleccionado o indicador de tendencia
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: selectedIndex != null
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildTrendIndicator(context, displayRecords),
          secondChild: selectedIndex != null
              ? _buildRecordDetail(context, displayRecords[selectedIndex], l10n)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildRecordDetail(
    BuildContext context,
    WeightRecordModel record,
    AppLocalizations l10n,
  ) {
    final date = record.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final hasNotes = record.notes != null && record.notes!.isNotEmpty;
    final hasSetEntries = record.setEntries.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fecha + botón cerrar
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = null),
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats principales
          if (!hasSetEntries) ...[
            _buildStatRow(context, [
              _StatItem(l10n.weightAxisLabel(record.weight.toString()),
                  Icons.fitness_center),
              _StatItem('${record.sets} ${l10n.sets}', Icons.repeat),
              _StatItem('${record.reps} ${l10n.reps}', Icons.numbers),
            ]),
          ] else ...[
            // Modo avanzado: resumen + detalle por serie
            _buildStatRow(context, [
              _StatItem(
                  l10n.weightAxisLabel(record.weight.toString()),
                  Icons.fitness_center),
              _StatItem(
                  '${record.setEntries.length} ${l10n.sets}', Icons.repeat),
            ]),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: record.setEntries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'S${entry.setNumber}: ${entry.weight}kg × ${entry.reps}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Notas (si existen)
          if (hasNotes) ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    record.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, List<_StatItem> items) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Row(
                  children: [
                    Icon(item.icon, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.label,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  List<WeightRecordModel> _deduplicateRecords(
      List<WeightRecordModel> records) {
    final seen = <String>{};
    final result = <WeightRecordModel>[];

    for (final record in records) {
      final key =
          '${record.date.year}-${record.date.month}-${record.date.day}'
          '_${record.weight}_${record.reps}';

      if (!seen.contains(key)) {
        seen.add(key);
        result.add(record);
      }
    }

    return result;
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 25) return 5;
    if (range <= 50) return 10;
    return 20;
  }

  Widget _buildTrendIndicator(
      BuildContext context, List<WeightRecordModel> records) {
    if (records.length < 2) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
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
      text = l10n.stable;
    } else if (isUp) {
      icon = Icons.trending_up;
      color = AppColors.success;
      text = l10n.positivePercentage(percentage.toStringAsFixed(1));
    } else {
      icon = Icons.trending_down;
      color = AppColors.warning;
      text = l10n.negativePercentage(percentage.toStringAsFixed(1));
    }

    final dateStr =
        '${records.first.date.day}/${records.first.date.month}';

    return SafeArea(
      top: false,
      child: Row(
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
            l10n.sinceDate(dateStr),
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final IconData icon;
  const _StatItem(this.label, this.icon);
}
