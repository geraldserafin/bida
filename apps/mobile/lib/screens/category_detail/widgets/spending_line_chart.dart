import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/expense.dart';
import '../../../widgets/chart_card.dart';

/// Cumulative spending for one envelope over the period.
///
/// Expenses are aggregated per day and summed running-total, so the line only
/// ever climbs — making it easy to see how fast an envelope is being drained.
class SpendingLineChart extends StatelessWidget {
  const SpendingLineChart({
    super.key,
    required this.expenses,
    required this.color,
  });

  final List<Expense> expenses;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (expenses.length < 2) {
      return ChartCard(
        title: l10n.spendingOverTime,
        child: Text(l10n.notEnoughData),
      );
    }

    // Sum per calendar day, then build a running total.
    final byDay = <DateTime, double>{};
    for (final e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      byDay[day] = (byDay[day] ?? 0) + e.amount;
    }
    final days = byDay.keys.toList()..sort();
    final first = days.first;

    var cumulative = 0.0;
    final spots = <FlSpot>[];
    for (final day in days) {
      cumulative += byDay[day]!;
      spots.add(FlSpot(day.difference(first).inDays.toDouble(), cumulative));
    }
    final maxY = cumulative * 1.2;

    return ChartCard(
      title: l10n.spendingOverTime,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    return Text(
                      _compact(value),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: spots.length <= 12),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Short axis label, e.g. 1500 -> "1,5k".
  static String _compact(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    }
    return value.toStringAsFixed(0);
  }
}
