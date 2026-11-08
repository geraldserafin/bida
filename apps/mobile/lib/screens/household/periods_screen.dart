import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_format.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import 'household_screen.dart';

final _day = DateFormat('d.MM.yyyy');

/// The periods of the household, newest first; a closed one shows how it
/// ended.
class PeriodsScreen extends StatelessWidget {
  const PeriodsScreen({super.key, required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    return Scaffold(
      appBar: FormTopBar(title: l10n.periods, where: household.name),
      body: RemoteData<List<Period>>(
        version: state.version,
        load: () => state.repository.periods(household.id),
        builder: (context, periods) => ListView(
          children: [
            for (final p in periods)
              ListTile(
                title: Text(
                  '${_day.format(p.startsOn)} – ${_day.format(p.endsOn)}',
                ),
                subtitle: Text(switch (p.status) {
                  PeriodStatus.current => l10n.currentPeriod,
                  PeriodStatus.next => l10n.nextPeriod,
                  PeriodStatus.closed => l10n.closedPeriod,
                }),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PeriodScreen(period: p)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One period: its piggy bank, the envelopes by what was spent (F17), the
/// shares (F33).
class PeriodScreen extends StatelessWidget {
  const PeriodScreen({super.key, required this.period});
  final Period period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    return Scaffold(
      appBar: FormTopBar(
        title:
            '${_day.format(period.startsOn)} – ${_day.format(period.endsOn)}',
      ),
      body: RemoteData<PeriodSummary>(
        version: state.version,
        load: () => state.repository.periodSummary(period.id),
        builder: (context, s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PiggyBankCard(summary: s, expanded: true),
            const SizedBox(height: 16),
            if (s.spentMinor == 0)
              Text(l10n.noExpensesInPeriod)
            else
              for (final e in s.envelopes.where((e) => e.spentMinor > 0))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SurfaceCard(
                    child: EnvelopeBar(
                      color: e.envelope.displayColor,
                      name: '${e.name} · ${e.sharePercent.toStringAsFixed(1)}%',
                      amounts:
                          '${formatPlain(e.spentMinor / 100)} / ${formatMinor(e.planMinor)}',
                      fraction: e.fraction.clamp(0, 1).toDouble(),
                      overspent: e.leftMinor < 0,
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            SharesCard(summary: s),
          ],
        ),
      ),
    );
  }
}
