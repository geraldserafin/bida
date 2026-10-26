import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/applied_summary.dart';
import '../../util/money_format.dart';
import 'money_rule_sheets.dart';
import 'recurring_editor.dart';

/// Manage what repeats: expenses (rent), income (a salary) and the sums that
/// go into envelopes every month. Applying them adds all three to the month
/// on screen in one tap.
class RecurringRulesScreen extends StatelessWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final anyActive =
        state.recurringRules.any((r) => r.active) ||
        state.recurringIncomes.any((r) => r.active) ||
        state.allocationRules.any((r) => r.active);

    return DefaultTabController(
      length: 3,
      child: Builder(
        builder: (context) {
          final tabs = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.recurringRules),
              actions: [
                if (anyActive)
                  IconButton(
                    tooltip: l10n.applyRecurring,
                    icon: const Icon(Icons.playlist_add_check),
                    onPressed: () => applyRecurring(context),
                  ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(text: l10n.expenses),
                  Tab(text: l10n.incomes),
                  Tab(text: l10n.allocations),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _List(
                  empty: l10n.noRecurringRules,
                  children: [
                    for (final rule in state.recurringRules)
                      _ExpenseRuleTile(
                        rule: rule,
                        envelope: state.envelopeById(rule.envelopeId),
                      ),
                  ],
                ),
                _List(
                  empty: l10n.noRecurringIncomes,
                  children: [
                    for (final rule in state.recurringIncomes)
                      _IncomeRuleTile(rule: rule),
                  ],
                ),
                _List(
                  empty: l10n.noAllocationRules,
                  children: [
                    for (final rule in state.allocationRules)
                      _AllocationRuleTile(
                        rule: rule,
                        envelope: state.envelopeById(rule.envelopeId),
                      ),
                  ],
                ),
              ],
            ),
            floatingActionButton: ListenableBuilder(
              listenable: tabs,
              builder: (context, _) => FloatingActionButton.extended(
                onPressed: () => _add(context, state, tabs.index),
                icon: const Icon(Icons.add),
                label: Text(l10n.addRule),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _add(BuildContext context, PlannerState state, int tab) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (tab == 1) {
      final rule = await showRecurringIncomeSheet(context);
      if (rule != null && context.mounted) {
        await attempt(context, () => state.saveRecurringIncome(rule));
      }
      return;
    }
    if (state.envelopes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.needEnvelopeFirst)));
      return;
    }
    if (tab == 0) {
      final rule = await showRecurringEditor(
        context,
        envelopes: state.envelopes,
      );
      if (rule != null && context.mounted) {
        await attempt(context, () => state.saveRecurringRule(rule));
      }
    } else {
      final rule = await showAllocationRuleSheet(
        context,
        envelopes: _inOrder(state),
      );
      if (rule != null && context.mounted) {
        await attempt(context, () => state.saveAllocationRule(rule));
      }
    }
  }
}

/// Applies the rules to the month on screen and says what was added.
Future<void> applyRecurring(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final state = context.read<PlannerState>();
  ApplyOutcome? outcome;
  final applied = await attempt(
    context,
    () async => outcome = await state.applyRecurringToMonth(),
  );
  if (!applied) return;
  messenger.showSnackBar(
    SnackBar(content: Text(appliedMessage(l10n, outcome!))),
  );
}

/// The top-level envelopes, each followed by its sub-envelopes.
List<Envelope> _inOrder(PlannerState state) => [
  for (final top in state.topLevel) ...[top, ...state.childrenOf(top.id!)],
];

class _List extends StatelessWidget {
  const _List({required this.empty, required this.children});

  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: children,
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: color),
  );
}

class _ExpenseRuleTile extends StatelessWidget {
  const _ExpenseRuleTile({required this.rule, required this.envelope});

  final RecurringRule rule;
  final Envelope? envelope;

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlannerState>();
    final color = envelope?.displayColor ?? Theme.of(context).disabledColor;

    return Opacity(
      opacity: rule.active ? 1 : 0.5,
      child: ListTile(
        leading: _Icon(
          color: color,
          icon: envelope?.displayIcon ?? Icons.repeat,
        ),
        title: Text(
          rule.note?.isNotEmpty == true ? rule.note! : envelope?.name ?? '—',
        ),
        subtitle: Text(envelope?.name ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatZloty(rule.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  attempt(context, () => state.deleteRecurringRule(rule.id!)),
            ),
          ],
        ),
        onTap: () async {
          final edited = await showRecurringEditor(
            context,
            envelopes: state.envelopes,
            existing: rule,
          );
          if (edited != null && context.mounted) {
            await attempt(context, () => state.saveRecurringRule(edited));
          }
        },
      ),
    );
  }
}

class _IncomeRuleTile extends StatelessWidget {
  const _IncomeRuleTile({required this.rule});

  final RecurringIncome rule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    return Opacity(
      opacity: rule.active ? 1 : 0.5,
      child: ListTile(
        leading: _Icon(
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.south_west,
        ),
        title: Text(rule.note?.isNotEmpty == true ? rule.note! : l10n.income),
        subtitle: Text(l10n.everyMonthOn(rule.dayOfMonth)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatZloty(rule.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  attempt(context, () => state.deleteRecurringIncome(rule.id!)),
            ),
          ],
        ),
        onTap: () async {
          final edited = await showRecurringIncomeSheet(
            context,
            existing: rule,
          );
          if (edited != null && context.mounted) {
            await attempt(context, () => state.saveRecurringIncome(edited));
          }
        },
      ),
    );
  }
}

class _AllocationRuleTile extends StatelessWidget {
  const _AllocationRuleTile({required this.rule, required this.envelope});

  final AllocationRule rule;
  final Envelope? envelope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final color = envelope?.displayColor ?? Theme.of(context).disabledColor;
    return Opacity(
      opacity: rule.active ? 1 : 0.5,
      child: ListTile(
        leading: _Icon(
          color: color,
          icon: envelope?.displayIcon ?? Icons.south_west,
        ),
        title: Text(envelope?.name ?? '—'),
        subtitle: Text(
          [
            l10n.everyMonthOn(rule.dayOfMonth),
            if (rule.note?.isNotEmpty == true) rule.note!,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatZloty(rule.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  attempt(context, () => state.deleteAllocationRule(rule.id!)),
            ),
          ],
        ),
        onTap: () async {
          final edited = await showAllocationRuleSheet(
            context,
            envelopes: _inOrder(state),
            existing: rule,
          );
          if (edited != null && context.mounted) {
            await attempt(context, () => state.saveAllocationRule(edited));
          }
        },
      ),
    );
  }
}
