import '../l10n/app_localizations.dart';
import '../models/recurring_rule.dart';

/// "1 wpływ, 2 przydziały i 3 wydatki", for what applying the rules adds or
/// would add. Empty when it is nothing.
String addedParts(AppLocalizations l10n, ApplyOutcome outcome) => [
  if (outcome.incomes > 0) l10n.countIncomes(outcome.incomes),
  if (outcome.allocations > 0) l10n.countAllocations(outcome.allocations),
  if (outcome.expenses > 0) l10n.countExpenses(outcome.expenses),
].join(', ');

/// What to tell the user after the rules were applied.
String appliedMessage(AppLocalizations l10n, ApplyOutcome outcome) {
  final parts = [
    if (outcome.added > 0) l10n.appliedSummary(addedParts(l10n, outcome)),
    if (outcome.skipped > 0) l10n.skippedAllocations(outcome.skipped),
  ];
  return parts.isEmpty ? l10n.appliedNothing : parts.join(' ');
}
