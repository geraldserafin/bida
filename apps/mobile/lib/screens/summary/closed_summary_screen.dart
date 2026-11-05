import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/surface_card.dart';

final _day = DateFormat('d.MM.yyyy');

/// The happy event after a period closed (F35): what came in, what was
/// spent, and above all what went on to the next period, even when nothing
/// did.
class ClosedSummaryScreen extends StatelessWidget {
  const ClosedSummaryScreen({super.key, required this.summary});

  final ClosedSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.celebration_outlined, size: 56, color: c.accent),
              const SizedBox(height: 16),
              Text(
                l10n.closedTitle(summary.householdName),
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                '${_day.format(summary.startsOn)} – ${_day.format(summary.endsOn)}',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted),
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                child: Column(
                  children: [
                    ValueRow(
                      label: l10n.closedPutIn,
                      value: formatMinor(
                        summary.transfersMinor + summary.carryInMinor,
                      ),
                    ),
                    ValueRow(
                      label: l10n.closedSpent,
                      value: formatMinor(summary.spentMinor),
                    ),
                    ValueRow(
                      label: l10n.closedCarried,
                      value: formatMinor(summary.carryOutMinor),
                      strong: true,
                      valueColor: summary.carryOutMinor > 0 ? c.accent : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary.carryOutMinor > 0
                    ? l10n.closedCarriedHint
                    : l10n.closedNothingCarried,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(
                label: l10n.closedOk,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
