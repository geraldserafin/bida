import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/period.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../dashboard/widgets/planned_pie_chart.dart';
import '../dashboard/widgets/planned_vs_spent_chart.dart';

/// Read-only overview of any period (used from History): totals, the same
/// charts as the dashboard, and a non-interactive envelope list.
class PeriodDetailScreen extends StatelessWidget {
  const PeriodDetailScreen({super.key, required this.period});

  final Period period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(period.name)),
      body: FutureBuilder<List<CategoryProgress>>(
        future: context.read<PlannerState>().progressForPeriod(period.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final progress = snapshot.data!;
          final planned = progress.fold<double>(0, (s, p) => s + p.planned);
          final spent = progress.fold<double>(0, (s, p) => s + p.spent);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                income: period.income,
                planned: planned,
                spent: spent,
              ),
              if (progress.isNotEmpty) ...[
                const SizedBox(height: 16),
                PlannedPieChart(progress: progress),
                const SizedBox(height: 16),
                PlannedVsSpentChart(progress: progress),
                const SizedBox(height: 16),
                Text(
                  l10n.envelopes,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...progress.map((p) => _EnvelopeRow(progress: p)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.planned,
    required this.spent,
  });

  final double income;
  final double planned;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remaining = planned - spent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, l10n.income, formatZloty(income)),
            const Divider(height: 20),
            _row(context, l10n.planned, formatZloty(planned)),
            _row(context, l10n.spent, formatZloty(spent)),
            _row(context, l10n.remaining, formatZloty(remaining), bold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : null);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EnvelopeRow extends StatelessWidget {
  const _EnvelopeRow({required this.progress});
  final CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.category.displayColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(progress.category.displayIcon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(progress.category.name)),
              Text(
                '${formatZloty(progress.spent)} / ${formatZloty(progress.planned)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: progress.isOverspent ? scheme.error : color,
            ),
          ),
        ],
      ),
    );
  }
}
