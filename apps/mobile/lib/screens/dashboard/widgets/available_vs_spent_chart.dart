import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/envelope_progress.dart';
import '../../../theme/envelope_visuals.dart';
import '../../../util/money_format.dart';
import '../../../widgets/chart_card.dart';

/// Grouped bars comparing what was available with what was spent for each envelope.
///
/// For every envelope the left (translucent) bar is what was available and the right
/// (solid) bar is what has been spent, both tinted with the envelope's color.
class AvailableVsSpentChart extends StatelessWidget {
  const AvailableVsSpentChart({super.key, required this.progress, this.onTap});

  final List<EnvelopeProgress> progress;

  /// Called when an envelope's bar group is tapped.
  final void Function(EnvelopeProgress)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = progress
        .where((p) => p.available > 0 || p.spent > 0)
        .toList();

    if (items.isEmpty) {
      return ChartCard(
        title: l10n.availableVsSpent,
        child: Text(l10n.notEnoughData),
      );
    }

    final maxValue = items
        .map((p) => p.available > p.spent ? p.available : p.spent)
        .reduce((a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final scheme = Theme.of(context).colorScheme;

    return ChartCard(
      title: l10n.availableVsSpent,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.spot != null) {
                      final i = response!.spot!.touchedBarGroupIndex;
                      if (i >= 0 && i < items.length) onTap?.call(items[i]);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.surfaceContainerHighest,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = items[group.x];
                      final label = rodIndex == 0 ? l10n.available : l10n.spent;
                      return BarTooltipItem(
                        '${item.envelope.name}\n',
                        TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '$label: ${formatZloty(rod.toY)}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= items.length) {
                          return const SizedBox.shrink();
                        }
                        final name = items[i].envelope.name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            name.length > 6 ? '${name.substring(0, 5)}…' : name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < items.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: items[i].available,
                          color: items[i].envelope.displayColor.withValues(
                            alpha: 0.35,
                          ),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: items[i].spent,
                          color: items[i].isOverspent
                              ? scheme.error
                              : items[i].envelope.displayColor,
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              LegendDot(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                label: l10n.available,
              ),
              LegendDot(color: scheme.onSurfaceVariant, label: l10n.spent),
            ],
          ),
        ],
      ),
    );
  }
}
