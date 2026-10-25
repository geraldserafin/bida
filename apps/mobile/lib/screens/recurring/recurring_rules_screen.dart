import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/recurring_rule.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import 'recurring_editor.dart';

/// Manage recurring income/expense templates and apply them to the current
/// period in one tap.
class RecurringRulesScreen extends StatelessWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final rules = state.recurringRules;
    final categoriesById = {for (final c in state.categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringRules),
        actions: [
          if (rules.any((r) => r.active) && state.currentPeriod != null)
            IconButton(
              tooltip: l10n.applyRecurring,
              icon: const Icon(Icons.playlist_add_check),
              onPressed: () => _apply(context, state),
            ),
        ],
      ),
      body: rules.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noRecurringRules, textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              itemCount: rules.length,
              itemBuilder: (context, i) {
                final rule = rules[i];
                final category = categoriesById[rule.categoryId];
                return _RuleTile(rule: rule, category: category);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, state),
        icon: const Icon(Icons.add),
        label: Text(l10n.addRule),
      ),
    );
  }

  Future<void> _addOrEdit(
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
    );
    if (rule != null) await state.saveRecurringRule(rule);
  }

  Future<void> _apply(BuildContext context, PlannerState state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final added = await state.applyRecurringToCurrentPeriod();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.recurringApplied(added))),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.category});

  final RecurringRule rule;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlannerState>();
    final color = category?.displayColor ?? Theme.of(context).disabledColor;

    return Opacity(
      opacity: rule.active ? 1 : 0.5,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(category?.displayIcon ?? Icons.repeat, color: color),
        ),
        title: Text(
          rule.note?.isNotEmpty == true ? rule.note! : category?.name ?? '—',
        ),
        subtitle: Text(category?.name ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatZloty(rule.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => state.deleteRecurringRule(rule.id!),
            ),
          ],
        ),
        onTap: () async {
          final edited = await showRecurringEditor(
            context,
            categories: state.categories,
            existing: rule,
          );
          if (edited != null) await state.saveRecurringRule(edited);
        },
      ),
    );
  }
}
