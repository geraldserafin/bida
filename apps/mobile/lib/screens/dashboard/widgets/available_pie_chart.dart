import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/envelope_progress.dart';
import '../../../theme/envelope_visuals.dart';
import '../../../util/money_format.dart';
import '../../../widgets/chart_card.dart';

/// Donut chart of how the money available this month is spread across envelopes, with
/// the amount spent called out in the centre.
class AvailablePieChart extends StatelessWidget {
  const AvailablePieChart({
    super.key,
    required this.progress,
    this.spent = 0,
    this.onTap,
  });

  final List<EnvelopeProgress> progress;
  final double spent;

  /// Called when a slice or a legend entry is tapped.
  final void Function(EnvelopeProgress)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final items = progress.where((p) => p.available > 0).toList();
    final total = items.fold<double>(0, (sum, p) => sum + p.available);

    if (items.isEmpty || total <= 0) {
      return ChartCard(
        title: l10n.availableSplit,
        child: Text(l10n.notEnoughData),
      );
    }

    return ChartCard(
      title: l10n.availableSplit,
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
                          value: p.available,
                          color: p.envelope.displayColor,
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
                      color: p.envelope.displayColor,
                      label: '${p.envelope.name} · ${formatZloty(p.available)}',
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
