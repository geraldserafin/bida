import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../state/planner_state.dart';
import '../../../util/applied_summary.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/surface_card.dart';
import '../../recurring/recurring_rules_screen.dart';

/// What the recurring rules would add to the month on screen, with a button
/// that adds it. Nothing when there is nothing to add.
class PendingRulesCard extends StatelessWidget {
  const PendingRulesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = context.watch<PlannerState>().pending;
    if (pending.added == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        radius: 20,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.pendingTitle(addedParts(l10n, pending)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            SmallButton(
              label: l10n.addPending,
              onPressed: () => applyRecurring(context),
            ),
          ],
        ),
      ),
    );
  }
}
