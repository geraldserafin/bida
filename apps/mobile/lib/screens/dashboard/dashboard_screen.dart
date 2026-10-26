import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../util/month_label.dart';
import '../../widgets/error_view.dart';
import '../add_expense/add_expense_screen.dart';
import '../envelope_detail/envelope_detail_screen.dart';
import '../envelopes/envelope_editor.dart';
import '../funding/fund_sheet.dart';
import '../history/history_screen.dart';
import '../incomes/incomes_screen.dart';
import '../incomes/income_sheet.dart';
import '../months/months_screen.dart';
import '../sharing/invitations_card.dart';
import '../recurring/recurring_rules_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/available_pie_chart.dart';
import 'widgets/available_vs_spent_chart.dart';

/// Opens an envelope's detail view for a tapped chart element.
void _openEnvelope(BuildContext context, EnvelopeProgress progress) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EnvelopeDetailScreen(envelopeId: progress.envelope.id!),
    ),
  );
}

/// Home screen — the money of one month: what came in, what went into the
/// envelopes, and how much is left in each.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final hasData = !state.isLoading && state.loadError == null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: hasData
            ? _MonthSwitcher(state: state)
            : Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      l10n.appTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
        actions: [
          IconButton(
            tooltip: l10n.incomes,
            icon: const Icon(Icons.payments_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const IncomesScreen())),
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
          final loadError = state.loadError;
          if (loadError != null) {
            return ErrorView(error: loadError, onRetry: state.load);
          }
          if (state.envelopes.isEmpty && state.isEmpty) {
            return const _EmptyState();
          }
          return _MonthView(state: state);
        },
      ),
      bottomNavigationBar: const _BottomNav(),
      floatingActionButton: state.envelopes.isEmpty
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
}

/// Bottom navigation. The dashboard is index 0; the other destinations push
/// their screens and the bar snaps back to it.
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
            2 => const MonthsScreen(),
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
            label: l10n.months,
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

/// The month on screen, with arrows to the neighbouring ones. Tapping the name
/// opens the list of months.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton(
          tooltip: l10n.previousMonth,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => attempt(context, state.previousMonth),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MonthsScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                monthLabel(state.month),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.nextMonth,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => attempt(context, state.nextMonth),
        ),
      ],
    );
  }
}

/// Nothing yet: the money comes in first, then goes into envelopes.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const InvitationsCard(),
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
              onPressed: () => showIncomeSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addIncome),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _addEnvelope(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.addEnvelope),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _addEnvelope(BuildContext context) async {
  final created = await showEnvelopeEditor(context);
  if (created == null || !context.mounted) return;
  final state = context.read<PlannerState>();
  await attempt(context, () => state.addEnvelope(created));
}

class _MonthView extends StatelessWidget {
  const _MonthView({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = state.topLevelProgress;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const InvitationsCard(),
        _SummaryCard(state: state),
        if (top.any((p) => p.available > 0 || p.spent > 0)) ...[
          const SizedBox(height: 14),
          AvailablePieChart(
            progress: top,
            spent: state.spent,
            onTap: (p) => _openEnvelope(context, p),
          ),
          const SizedBox(height: 14),
          AvailableVsSpentChart(
            progress: top,
            onTap: (p) => _openEnvelope(context, p),
          ),
        ],
        const SizedBox(height: 20),
        _SectionLabel(l10n.envelopes),
        const SizedBox(height: 10),
        if (top.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.noEnvelopes)),
          )
        else
          for (final p in top) ...[
            _EnvelopeTile(progress: p),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _addEnvelope(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addEnvelope),
          ),
        ),
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
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
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
    final negative = state.isOverAllocated;
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
                    label: l10n.allocated,
                    value: formatZloty(state.allocated),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.spent,
                    value: formatZloty(state.spent),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  negative ? l10n.overAllocated : l10n.unallocated,
                  style: TextStyle(
                    color: negative ? scheme.error : scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatZloty(state.pool),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: negative ? scheme.error : scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showIncomeSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addIncome),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.envelopes.isEmpty
                        ? null
                        : () => showFundSheet(context),
                    icon: const Icon(Icons.south_west, size: 18),
                    label: Text(l10n.allocate),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EnvelopeTile extends StatelessWidget {
  const _EnvelopeTile({required this.progress});
  final EnvelopeProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final envelope = progress.envelope;
    final color = envelope.displayColor;

    return Card(
      child: InkWell(
        onTap: () => _openEnvelope(context, progress),
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
                    child: Icon(envelope.displayIcon, size: 17, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      envelope.name,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (progress.isShared) ...[
                    Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.memberCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    formatZloty(progress.balance),
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: progress.isOverspent ? scheme.error : null,
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
              const SizedBox(height: 8),
              Text(
                l10n.spentOfAvailable(
                  formatZloty(progress.spent),
                  formatZloty(progress.available),
                ),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
