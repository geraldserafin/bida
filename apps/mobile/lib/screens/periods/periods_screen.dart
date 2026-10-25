import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/period_summary.dart';
import '../../state/planner_state.dart';
import '../../util/money_format.dart';
import '../period_setup/new_period_screen.dart';

const _accent = Color(0xFF22C55E);

/// Periods (Okresy): every planning period grouped into upcoming / current /
/// earlier, with the active one highlighted. Create and delete periods here.
class PeriodsScreen extends StatelessWidget {
  const PeriodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.periods)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewPeriodScreen())),
        icon: const Icon(Icons.add),
        label: Text(l10n.newPeriod),
      ),
      body: FutureBuilder<List<PeriodSummary>>(
        key: ValueKey(state.periods.length),
        future: state.periodSummaries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summaries = snapshot.data!;
          if (summaries.isEmpty) {
            return Center(child: Text(l10n.noPeriodsYet));
          }
          return _Grouped(
            summaries: summaries,
            activeId: state.currentPeriod?.id,
          );
        },
      ),
    );
  }
}

class _Grouped extends StatelessWidget {
  const _Grouped({required this.summaries, required this.activeId});

  final List<PeriodSummary> summaries;
  final int? activeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final upcoming = <PeriodSummary>[];
    final current = <PeriodSummary>[];
    final earlier = <PeriodSummary>[];
    for (final s in summaries) {
      if (s.period.endDate.isBefore(todayStart)) {
        earlier.add(s);
      } else if (s.period.startDate.isAfter(todayEnd)) {
        upcoming.add(s);
      } else {
        current.add(s);
      }
    }
    upcoming.sort((a, b) => a.period.startDate.compareTo(b.period.startDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        if (upcoming.isNotEmpty) ..._section(context, l10n.upcoming, upcoming),
        if (current.isNotEmpty) ..._section(context, l10n.currentSet, current),
        if (earlier.isNotEmpty) ..._section(context, l10n.earlier, earlier),
      ],
    );
  }

  List<Widget> _section(
    BuildContext context,
    String title,
    List<PeriodSummary> items,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      for (final s in items) ...[
        _PeriodTile(summary: s, active: s.period.id == activeId),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.summary, required this.active});

  final PeriodSummary summary;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd('pl');
    final over = summary.spent > summary.planned;
    final fraction = summary.income <= 0
        ? 0.0
        : (summary.spent / summary.income).clamp(0.0, 1.0);

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
          await context.read<PlannerState>().selectPeriod(summary.period.id!);
          if (context.mounted) Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.period.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${dateFmt.format(summary.period.startDate)} – '
                          '${dateFmt.format(summary.period.endDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatZloty(summary.spent),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: over ? scheme.error : scheme.onSurface,
                        ),
                      ),
                      Text(
                        '/ ${formatZloty(summary.income)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.deletePeriod,
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              if (active) ...[
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePeriod),
        content: Text(l10n.deletePeriodConfirm(summary.period.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await state.deletePeriod(summary.period.id!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.periodDeleted)));
    }
  }
}
