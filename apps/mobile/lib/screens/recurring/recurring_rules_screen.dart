import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/envelope.dart';
import '../../models/recurring_rule.dart';
import '../../state/planner_state.dart';
import '../../util/api_errors.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_format.dart';
import 'recurring_editor.dart';

/// Manage recurring expense templates and apply them to the month on screen
/// in one tap.
class RecurringRulesScreen extends StatelessWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final rules = state.recurringRules;
    final envelopesById = {for (final e in state.envelopes) e.id: e};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringRules),
        actions: [
          if (rules.any((r) => r.active))
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
                final envelope = envelopesById[rule.envelopeId];
                return _RuleTile(rule: rule, envelope: envelope);
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
    if (state.envelopes.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.needEnvelopeFirst)));
      return;
    }
    final rule = await showRecurringEditor(
      context,
      envelopes: state.envelopes,
      existing: existing,
    );
    if (rule != null && context.mounted) {
      await attempt(context, () => state.saveRecurringRule(rule));
    }
  }

  Future<void> _apply(BuildContext context, PlannerState state) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var added = 0;
    final applied = await attempt(
      context,
      () async => added = await state.applyRecurringToMonth(),
    );
    if (!applied) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.recurringApplied(added))),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.envelope});

  final RecurringRule rule;
  final Envelope? envelope;

  @override
  Widget build(BuildContext context) {
    final state = context.read<PlannerState>();
    final color = envelope?.displayColor ?? Theme.of(context).disabledColor;

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
          child: Icon(envelope?.displayIcon ?? Icons.repeat, color: color),
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
