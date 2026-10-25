import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/period.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../add_expense/add_expense_screen.dart';
import '../category_detail/category_detail_screen.dart';
import '../history/history_screen.dart';
import '../period_setup/new_period_screen.dart';
import '../periods/periods_screen.dart';
import '../recurring/recurring_rules_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/planned_pie_chart.dart';
import 'widgets/planned_vs_spent_chart.dart';

/// Opens an envelope's detail (expense) view for a tapped chart element.
void _openEnvelope(BuildContext context, CategoryProgress progress) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CategoryDetailScreen(splitId: progress.split.id!),
    ),
  );
}

/// Home screen — current-period overview with planned vs. spent per category.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final period = state.currentPeriod;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: period != null && state.periods.length > 1
            ? _PeriodSwitcher(state: state)
            : Row(
                children: [
                  const Icon(Icons.savings_outlined, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
        actions: [
          if (period != null)
            IconButton(
              tooltip: l10n.editPlan,
              icon: const Icon(Icons.tune),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewPeriodScreen(editPeriod: period),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.recurringRules,
            icon: const Icon(Icons.repeat),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringRulesScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (period == null) {
            return _EmptyState(onCreate: () => _openNewPeriod(context));
          }
          return _PeriodView(state: state);
        },
      ),
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: period == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.addExpense),
            ),
    );
  }

  void _openNewPeriod(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NewPeriodScreen()));
  }
}

/// Bottom navigation. The dashboard is index 0 ("Plan"); the other
/// destinations push their screens and the bar snaps back to Plan.
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          Widget? screen = switch (i) {
            1 => const HistoryScreen(),
            2 => const PeriodsScreen(),
            3 => const SettingsScreen(),
            _ => null,
          };
          if (screen != null) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => screen));
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l10n.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.periods,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: state.currentPeriod!.id,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        items: [
          for (final Period p in state.periods)
            DropdownMenuItem(value: p.id, child: Text(p.name)),
        ],
        onChanged: (id) {
          if (id != null) context.read<PlannerState>().selectPeriod(id);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.savings_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.dashboardEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.dashboardEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.newPeriod),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodView extends StatelessWidget {
  const _PeriodView({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _SummaryCard(state: state),
        if (state.progress.isNotEmpty) ...[
          const SizedBox(height: 14),
          PlannedPieChart(
            progress: state.progress,
            spent: state.totalSpent,
            onTap: (p) => _openEnvelope(context, p),
          ),
          const SizedBox(height: 14),
          PlannedVsSpentChart(
            progress: state.progress,
            onTap: (p) => _openEnvelope(context, p),
          ),
        ],
        const SizedBox(height: 20),
        _SectionLabel(l10n.envelopes),
        const SizedBox(height: 10),
        if (state.progress.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.noEnvelopes)),
          )
        else
          for (final p in state.progress) ...[
            _CategoryProgressTile(progress: p),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE4E4E7),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.income,
                    value: formatZloty(state.income),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.planned,
                    value: formatZloty(state.totalPlanned),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isOverAllocated ? l10n.overAllocated : l10n.unallocated,
                  style: TextStyle(
                    color: state.isOverAllocated
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatZloty(state.unallocated),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: state.isOverAllocated
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Color(0xFF71717A),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  const _CategoryProgressTile({required this.progress});
  final CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.category.displayColor;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(splitId: progress.split.id!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      progress.category.displayIcon,
                      size: 17,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progress.category.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${formatZloty(progress.spent)} / ${formatZloty(progress.planned)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 5,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: progress.isOverspent ? scheme.error : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
