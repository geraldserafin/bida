import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../state/planner_state.dart';
import '../../../util/applied_summary.dart';
import '../../recurring/recurring_rules_screen.dart';

/// What the recurring rules would add to the month on screen, with a button
/// that adds it. Nothing when there is nothing to add.
class PendingRulesCard extends StatelessWidget {
  const PendingRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pending = context.watch<PlannerState>().pending;
    if (pending.added == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Icon(Icons.repeat, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.pendingTitle(addedParts(l10n, pending))),
              ),
              TextButton(
                onPressed: () => applyRecurring(context),
                child: Text(l10n.addPending),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
