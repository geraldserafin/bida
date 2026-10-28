import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../util/month_label.dart';
import '../../widgets/remote_data.dart';

const _accent = Color(0xFF22C55E);

/// The months so far, newest first, with what came in, what went into the
/// envelopes and what was spent. Tapping one shows it on the dashboard.
class MonthsScreen extends StatelessWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.months)),
      body: RemoteData<List<MonthSummary>>(
        // fetched again when the figures of the month change
        version: (state.month, state.income, state.allocated, state.spent),
        load: state.monthSummaries,
        builder: (context, summaries) {
          if (summaries.isEmpty) {
            return Center(child: Text(l10n.noMonthsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: summaries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _MonthTile(
              summary: summaries[i],
              active: summaries[i].month == state.month,
            ),
          );
        },
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.summary, required this.active});

  final MonthSummary summary;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fraction = summary.income <= 0
        ? (summary.spent > 0 ? 1.0 : 0.0)
        : (summary.spent / summary.income).clamp(0.0, 1.0);
    final over = summary.spent > summary.income && summary.income > 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: active
              ? _accent.withValues(alpha: 0.6)
              : scheme.surfaceContainerHigh,
          width: active ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final state = context.read<PlannerState>();
          final selected = await attempt(
            context,
            () => state.selectMonth(summary.month),
          );
          if (selected && context.mounted) Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      monthLabel(summary.month),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    formatZloty(summary.spent),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: over ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.monthLine(
                  formatZloty(summary.income),
                  formatZloty(summary.allocated),
                ),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: over ? scheme.error : _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
