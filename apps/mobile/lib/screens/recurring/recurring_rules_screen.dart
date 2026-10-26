import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/recurring_rule.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/category_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/transaction_row.dart';
import 'recurring_editor.dart';

enum _Side { incomes, expenses }

/// Recurring tab ("Cykliczne"): expenses that come back, switched on and off
/// here, and added to the current period in one tap.
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
    final period = state.currentPeriod;

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
                    ],
                    selected: _side,
                    onChanged: (side) => setState(() => _side = side),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _side == _Side.incomes
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.recurringIncomeSoon,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _RuleList(state: state),
            ),
            if (_side == _Side.expenses &&
                period != null &&
                state.activeRecurringRules.isNotEmpty)
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
                        label: l10n.applyTo(period.name),
                        onPressed: () => _apply(context, state),
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

  Future<void> _apply(BuildContext context, PlannerState state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var added = 0;
    final applied = await attempt(
      context,
      () async => added = await state.applyRecurringToCurrentPeriod(),
    );
    if (!applied) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.recurringApplied(added))),
    );
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesById = {for (final c in state.categories) c.id: c};
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: [
        if (state.recurringRules.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.noRecurringRules, textAlign: TextAlign.center),
          ),
        for (final rule in state.recurringRules) ...[
          _RuleCard(rule: rule, category: categoriesById[rule.categoryId]),
          const SizedBox(height: 10),
        ],
        AppButton(
          label: l10n.newRulePlus,
          kind: ButtonKind.dashed,
          onPressed: () => editRecurringRule(context, state),
        ),
      ],
    );
  }
}

/// Opens the rule editor for a new rule, or for [existing], and saves or
/// deletes what comes back.
Future<void> editRecurringRule(
  BuildContext context,
  PlannerState state, {
  RecurringRule? existing,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (state.categories.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.needCategoryFirst)));
    return;
  }
  final rule = await showRecurringEditor(
    context,
    categories: state.categories,
    existing: existing,
    onDelete: existing == null
        ? null
        : () => attempt(context, () => state.deleteRecurringRule(existing.id!)),
  );
  if (rule != null && context.mounted) {
    await attempt(context, () => state.saveRecurringRule(rule));
  }
}

/// How a rule is described under its name: category, kind, how often.
String ruleDetails(
  AppLocalizations l10n,
  RecurringRule rule,
  Category? category,
) => [
  ?category?.name,
  l10n.ruleFixed,
  rule.active
      ? switch (rule.frequency) {
          RecurrenceFrequency.monthly => l10n.everyMonth,
          RecurrenceFrequency.weekly => l10n.everyWeek,
        }
      : l10n.ruleOff,
].join(' · ');

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.category});

  final RecurringRule rule;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final c = AppColors.of(context);
    final title = rule.note?.isNotEmpty == true
        ? rule.note!
        : category?.name ?? '—';

    return Opacity(
      opacity: rule.active ? 1 : 0.55,
      child: SurfaceCard(
        onTap: () => editRecurringRule(context, state, existing: rule),
        child: Row(
          children: [
            CategoryDot(category?.displayColor ?? c.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(
                    ruleDetails(l10n, rule, category),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatZloty(rule.amount),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ToggleSwitch(
              value: rule.active,
              semanticLabel: l10n.active,
              onChanged: (on) =>
                  attempt(context, () => state.setRuleActive(rule, on)),
            ),
          ],
        ),
      ),
    );
  }
}
