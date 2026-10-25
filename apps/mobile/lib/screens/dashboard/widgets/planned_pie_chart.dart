import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/category_progress.dart';
import '../../../theme/category_visuals.dart';
import '../../../util/money_format.dart';
import '../../../widgets/chart_card.dart';

/// Donut chart of how the period's income is planned across categories, with
/// the amount spent called out in the centre.
class PlannedPieChart extends StatelessWidget {
  const PlannedPieChart({
    super.key,
    required this.progress,
    this.spent = 0,
    this.onTap,
  });

  final List<CategoryProgress> progress;
  final double spent;

  /// Called when a slice or a legend entry is tapped.
  final void Function(CategoryProgress)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = progress.where((p) => p.planned > 0).toList();
    final total = items.fold<double>(0, (sum, p) => sum + p.planned);

    if (items.isEmpty || total <= 0) {
      return ChartCard(
        title: l10n.plannedSplit,
        child: Text(l10n.notEnoughData),
      );
    }

    return ChartCard(
      title: l10n.plannedSplit,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 52,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent &&
                            response?.touchedSection != null) {
                          final i =
                              response!.touchedSection!.touchedSectionIndex;
                          if (i >= 0 && i < items.length) onTap?.call(items[i]);
                        }
                      },
                    ),
                    sections: [
                      for (final p in items)
                        PieChartSectionData(
                          value: p.planned,
                          color: p.category.displayColor,
                          showTitle: false,
                          radius: 26,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.spent,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatZloty(spent),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final p in items)
                InkWell(
                  onTap: onTap == null ? null : () => onTap!(p),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: LegendDot(
                      color: p.category.displayColor,
                      label: '${p.category.name} · ${formatZloty(p.planned)}',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
