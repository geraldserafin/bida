import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../util/money_format.dart';

/// Slim sticky bar showing the current period's remaining balance.
///
/// Designed to be dropped into every screen (Dashboard, Add Expense, Category
/// Detail, …) so the number the user cares about is always in view.
class RemainingBalanceBar extends StatelessWidget {
  final double remaining;
  final String? periodName;

  const RemainingBalanceBar({
    super.key,
    required this.remaining,
    this.periodName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isNegative = remaining < 0;
    final bg = isNegative ? scheme.errorContainer : scheme.primaryContainer;
    final fg = isNegative ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Material(
      color: bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                periodName == null
                    ? l10n.remaining
                    : l10n.remainingIn(periodName!),
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                formatZloty(remaining),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
