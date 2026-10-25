import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../state/planner_state.dart';
import '../../../util/money_format.dart';
import '../../contributions/contributions_screen.dart';

/// "Paid in X of Y" for a shared budget: what members actually paid into the
/// period next to the income that was planned.
class ContributionsCard extends StatelessWidget {
  const ContributionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final period = state.currentPeriod;
    if (period == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final fraction = state.income <= 0
        ? 0.0
        : (state.contributed / state.income).clamp(0.0, 1.0);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ContributionsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.contributions,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.contributedOf(
                  formatZloty(state.contributed),
                  formatZloty(state.income),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
