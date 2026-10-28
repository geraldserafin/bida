import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/applied_summary.dart';
import '../../util/money_format.dart';
import '../../util/month_label.dart';
import '../../widgets/app_button.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/transaction_row.dart';
import 'money_rule_sheets.dart';
import 'recurring_editor.dart';

enum _Side { incomes, expenses, allocations }

/// Recurring tab ("Cykliczne"): what repeats — income (a salary), expenses
/// (rent) and the sums that go into envelopes every month — switched on and
/// off here, and added to the month on screen in one tap.
class RecurringRulesScreen extends StatefulWidget {
  const RecurringRulesScreen({super.key});

  @override
  State<RecurringRulesScreen> createState() => _RecurringRulesScreenState();
}

class _RecurringRulesScreenState extends State<RecurringRulesScreen> {
  _Side _side = _Side.expenses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final c = AppColors.of(context);
    final anyActive =
        state.recurringRules.any((r) => r.active) ||
        state.recurringIncomes.any((r) => r.active) ||
        state.allocationRules.any((r) => r.active);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabTitle(l10n.recurringTab),
                  const SizedBox(height: 14),
                  SegmentedPills<_Side>(
                    options: [
                      (_Side.incomes, l10n.incomes),
                      (_Side.expenses, l10n.expenses),
                      (_Side.allocations, l10n.allocations),
                    ],
                    selected: _side,
                    onChanged: (side) => setState(() => _side = side),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (_side) {
                _Side.incomes => _RuleList(
                  empty: l10n.noRecurringIncomes,
                  onAdd: () => _addIncomeRule(context, state),
                  children: [
                    for (final rule in state.recurringIncomes)
                      _IncomeRuleCard(rule: rule),
                  ],
                ),
                _Side.expenses => _RuleList(
                  empty: l10n.noRecurringRules,
                  onAdd: () => editRecurringRule(context, state),
                  children: [
                    for (final rule in state.recurringRules)
                      _ExpenseRuleCard(
                        rule: rule,
                        envelope: state.envelopeById(rule.envelopeId),
                      ),
                  ],
                ),
                _Side.allocations => _RuleList(
                  empty: l10n.noAllocationRules,
                  onAdd: () => _editAllocationRule(context, state),
                  children: [
                    for (final rule in state.allocationRules)
                      _AllocationRuleCard(
                        rule: rule,
                        envelope: state.envelopeById(rule.envelopeId),
                      ),
                  ],
                ),
              },
            ),
            if (anyActive)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: l10n.applyTo(monthLabel(state.month)),
                        onPressed: () => applyRecurring(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.applyHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addIncomeRule(BuildContext context, PlannerState state) async {
    final rule = await showRecurringIncomeSheet(context);
    if (rule != null && context.mounted) {
      await attempt(context, () => state.saveRecurringIncome(rule));
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
List<Envelope> envelopesInOrder(PlannerState state) => [
  for (final top in state.topLevel) ...[top, ...state.childrenOf(top.id!)],
];

/// Opens the rule editor for a new recurring expense, or for [existing], and
/// saves or deletes what comes back.
Future<void> editRecurringRule(
  BuildContext context,
  PlannerState state, {
  RecurringRule? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (state.envelopes.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.needEnvelopeFirst)));
    return;
  }
  final rule = await showRecurringEditor(
    context,
    envelopes: envelopesInOrder(state),
    existing: existing,
    onDelete: existing == null
        ? null
        : () => attempt(context, () => state.deleteRecurringRule(existing.id!)),
  );
  if (rule != null && context.mounted) {
    await attempt(context, () => state.saveRecurringRule(rule));
  }
}

Future<void> _editAllocationRule(
  BuildContext context,
  PlannerState state, {
  AllocationRule? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (state.envelopes.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.needEnvelopeFirst)));
    return;
  }
  final rule = await showAllocationRuleSheet(
    context,
    envelopes: envelopesInOrder(state),
    existing: existing,
    onDelete: existing == null
        ? null
        : () =>
              attempt(context, () => state.deleteAllocationRule(existing.id!)),
  );
  if (rule != null && context.mounted) {
    await attempt(context, () => state.saveAllocationRule(rule));
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.empty,
    required this.onAdd,
    required this.children,
  });

  final String empty;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: [
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(empty, textAlign: TextAlign.center),
          ),
        for (final child in children) ...[child, const SizedBox(height: 10)],
        AppButton(
          label: l10n.newRulePlus,
          kind: ButtonKind.dashed,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// A rule: a dot, its name, how it repeats, the amount, and a switch.
class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.color,
    required this.title,
    required this.details,
    required this.amount,
    required this.active,
    required this.onTap,
    required this.onActive,
  });

  final Color color;
  final String title;
  final String details;
  final double amount;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<bool> onActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Opacity(
      opacity: active ? 1 : 0.55,
      child: SurfaceCard(
        onTap: onTap,
        child: Row(
          children: [
            CategoryDot(color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(details, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 3),
                  Text(
                    formatZloty(amount),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ToggleSwitch(
              value: active,
              semanticLabel: l10n.active,
              onChanged: onActive,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRuleCard extends StatelessWidget {
  const _ExpenseRuleCard({required this.rule, required this.envelope});

  final RecurringRule rule;
  final Envelope? envelope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    return _RuleCard(
      color: envelope?.displayColor ?? AppColors.of(context).textMuted,
      title: rule.note?.isNotEmpty == true ? rule.note! : envelope?.name ?? '—',
      details: [
        ?envelope?.name,
        rule.active
            ? switch (rule.frequency) {
                RecurrenceFrequency.monthly => l10n.everyMonth,
                RecurrenceFrequency.weekly => l10n.everyWeek,
              }
            : l10n.ruleOff,
      ].join(' · '),
      amount: rule.amount,
      active: rule.active,
      onTap: () => editRecurringRule(context, state, existing: rule),
      onActive: (on) => attempt(
        context,
        () => state.saveRecurringRule(rule.copyWith(active: on)),
      ),
    );
  }
}

class _IncomeRuleCard extends StatelessWidget {
  const _IncomeRuleCard({required this.rule});

  final RecurringIncome rule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    return _RuleCard(
      color: AppColors.of(context).accent,
      title: rule.note?.isNotEmpty == true ? rule.note! : l10n.income,
      details: rule.active ? l10n.everyMonthOn(rule.dayOfMonth) : l10n.ruleOff,
      amount: rule.amount,
      active: rule.active,
      onTap: () async {
        final edited = await showRecurringIncomeSheet(
          context,
          existing: rule,
          onDelete: () =>
              attempt(context, () => state.deleteRecurringIncome(rule.id!)),
        );
        if (edited != null && context.mounted) {
          await attempt(context, () => state.saveRecurringIncome(edited));
        }
      },
      onActive: (on) => attempt(
        context,
        () => state.saveRecurringIncome(
          RecurringIncome(
            id: rule.id,
            amount: rule.amount,
            dayOfMonth: rule.dayOfMonth,
            note: rule.note,
            active: on,
          ),
        ),
      ),
    );
  }
}

class _AllocationRuleCard extends StatelessWidget {
  const _AllocationRuleCard({required this.rule, required this.envelope});

  final AllocationRule rule;
  final Envelope? envelope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    return _RuleCard(
      color: envelope?.displayColor ?? AppColors.of(context).textMuted,
      title: envelope?.name ?? '—',
      details: [
        rule.active ? l10n.everyMonthOn(rule.dayOfMonth) : l10n.ruleOff,
        if (rule.note?.isNotEmpty == true) rule.note!,
      ].join(' · '),
      amount: rule.amount,
      active: rule.active,
      onTap: () => _editAllocationRule(context, state, existing: rule),
      onActive: (on) => attempt(
        context,
        () => state.saveAllocationRule(
          AllocationRule(
            id: rule.id,
            envelopeId: rule.envelopeId,
            amount: rule.amount,
            dayOfMonth: rule.dayOfMonth,
            note: rule.note,
            active: on,
          ),
        ),
      ),
    );
  }
}
