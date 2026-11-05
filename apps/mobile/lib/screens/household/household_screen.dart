import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_format.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_view.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../setup_wizard/setup_wizard_screen.dart';
import 'envelopes_screen.dart';
import 'household_settings_screen.dart';
import 'log_screen.dart';
import 'members_screen.dart';
import 'periods_screen.dart';

final _day = DateFormat('d.MM');

/// The household tab: its piggy bank in the current or the next period,
/// the plans of its envelopes and who has how much in it.
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    final summary = state.summary;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.loadError != null) {
              return ErrorView(error: state.loadError!, onRetry: state.load);
            }
            if (household == null || summary == null) {
              return Center(
                child: AppButton(
                  label: l10n.wizardStart,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SetupWizardScreen(),
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: state.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _Header(household: household),
                  const SizedBox(height: 12),
                  _PeriodSwitch(household: household, shown: summary.period),
                  const SizedBox(height: 12),
                  PiggyBankCard(summary: summary),
                  const SizedBox(height: 12),
                  _MoneyButtons(period: summary.period),
                  const SizedBox(height: 20),
                  _Plans(summary: summary),
                  const SizedBox(height: 20),
                  SharesCard(summary: summary),
                  if (summary.forecast != null) ...[
                    const SizedBox(height: 20),
                    _ForecastCard(forecast: summary.forecast!),
                  ],
                  const SizedBox(height: 20),
                  _Links(household: household),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final all = context.watch<BudgetState>().households;
    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<String>(
            tooltip: l10n.chooseHousehold,
            onSelected: (id) async {
              if (id == '+') {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
                );
              } else {
                await state.selectHousehold(id);
              }
            },
            itemBuilder: (_) => [
              for (final h in all)
                PopupMenuItem(value: h.id, child: Text(h.name)),
              PopupMenuItem(value: '+', child: Text(l10n.newHousehold)),
            ],
            child: Row(
              children: [
                Flexible(child: TabTitle(household.name)),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        if (household.frozen) Chip(label: Text(l10n.frozen)),
      ],
    );
  }
}

/// The current period, the next one (when open), or the button to open it.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.household, required this.shown});
  final Household household;
  final Period shown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final next = household.next;
    String label(Period p) =>
        '${_day.format(p.startsOn)} – ${_day.format(p.endsOn)}';
    return ChipWrap(
      children: [
        PillChip(
          label: '${l10n.currentPeriod} · ${label(household.current)}',
          selected: shown.id == household.current.id,
          onTap: () => state.showPeriod(null),
        ),
        if (next != null)
          PillChip(
            label: '${l10n.nextPeriod} · ${label(next)}',
            selected: shown.id == next.id,
            onTap: () => state.showPeriod(next.id),
          )
        else
          PillChip(
            label: '+ ${l10n.openNextPeriod}',
            selected: false,
            onTap: () => attemptMoney(context, () async {
              final period = await state.repository.openNextPeriod(
                household.id,
              );
              await state.showPeriod(period.id);
            }),
          ),
      ],
    );
  }
}

/// Saldo skarbonki and how it came about (F16); the warning when the plans
/// exceed it (F19).
class PiggyBankCard extends StatelessWidget {
  const PiggyBankCard({super.key, required this.summary});
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final s = summary;
    return SurfaceCard(
      child: Column(
        children: [
          ValueRow(
            label: l10n.piggyBalance,
            value: formatMinor(s.balanceMinor),
            strong: true,
          ),
          ValueRow(
            small: true,
            label: l10n.transfers,
            value: formatMinor(s.transfersMinor),
          ),
          if (s.withdrawalsMinor > 0)
            ValueRow(
              small: true,
              label: l10n.withdrawals,
              value: '−${formatMinor(s.withdrawalsMinor)}',
            ),
          if (s.carryInMinor > 0)
            ValueRow(
              small: true,
              label: l10n.carryIn,
              value: formatMinor(s.carryInMinor),
            ),
          ValueRow(
            small: true,
            label: l10n.spent,
            value: '−${formatMinor(s.spentMinor)}',
          ),
          if (s.estimatedSpentMinor > 0)
            ValueRow(
              small: true,
              label: l10n.estimatedSpent,
              value: formatMinor(s.estimatedSpentMinor),
              valueColor: c.estimate,
            ),
          const Divider(),
          ValueRow(
            small: true,
            label: l10n.plansTotal,
            value: formatMinor(s.plansTotalMinor),
          ),
          ValueRow(
            small: true,
            label: l10n.freeMoneyLabel,
            value: formatMinor(s.freeMinor),
            valueColor: s.freeMinor < 0 ? c.warning : null,
          ),
          if (s.plansExceedBalance)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.plansExceedBalance,
                style: TextStyle(color: c.warning),
              ),
            ),
          if (s.carryOutMinor != null)
            ValueRow(
              label: l10n.closedCarried,
              value: formatMinor(s.carryOutMinor!),
            ),
        ],
      ),
    );
  }
}

class _MoneyButtons extends StatelessWidget {
  const _MoneyButtons({required this.period});
  final Period period;

  Future<void> _move(BuildContext context, {required bool withdraw}) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final amount = await askAmount(
      context,
      title: withdraw ? l10n.withdraw : l10n.transferFromWallet,
      message: withdraw
          ? l10n.withdrawHint
          : l10n.transferHint(formatMinor(state.wallet.balanceMinor)),
      action: withdraw ? l10n.withdraw : l10n.transfer,
    );
    if (amount == null || amount <= 0 || !context.mounted) return;
    MoveOutcome? outcome;
    final ok = await attemptMoney(
      context,
      () async => outcome = await state.change(
        (repo) => withdraw
            ? repo.withdraw(period.id, amount)
            : repo.transfer(period.id, amount),
      ),
    );
    if (!ok || !context.mounted || outcome == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (outcome!.usedUnconfirmed) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.usedUnconfirmed)));
    } else if (outcome!.plansExceedBalance) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.plansExceedBalance)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!period.isOpen) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: l10n.transfer,
            height: 44,
            onPressed: () => _move(context, withdraw: false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            label: l10n.withdraw,
            kind: ButtonKind.secondary,
            height: 44,
            onPressed: () => _move(context, withdraw: true),
          ),
        ),
      ],
    );
  }
}

/// The envelopes with plan, spent and left (F17, F19); tapping one sets its plan.
class _Plans extends StatelessWidget {
  const _Plans({required this.summary});
  final PeriodSummary summary;

  Future<void> _setPlan(BuildContext context, EnvelopeFigures e) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final amount = await askAmount(
      context,
      title: l10n.planOf(e.name),
      message: e.recurringMinor > 0
          ? l10n.planRecurringPart(formatMinor(e.recurringMinor))
          : null,
      initialMinor: e.planMinor,
    );
    if (amount == null || !context.mounted) return;
    await attemptMoney(
      context,
      () => state.change(
        (repo) => repo.setPlan(summary.period.id, e.envelopeId, amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = summary.period.isOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.envelopes,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EnvelopesScreen()),
              ),
              child: Text(l10n.manageEnvelopes),
            ),
          ],
        ),
        for (final e in summary.envelopes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SurfaceCard(
              onTap: open && !e.archived ? () => _setPlan(context, e) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EnvelopeBar(
                    color: e.envelope.displayColor,
                    name: e.archived ? '${e.name} · ${l10n.archived}' : e.name,
                    amounts:
                        '${formatPlain(e.spentMinor / 100)} / ${formatMinor(e.planMinor)}',
                    fraction: e.fraction.clamp(0, 1).toDouble(),
                    overspent: e.leftMinor < 0,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      l10n.leftAmount(formatMinor(e.leftMinor)),
                      if (e.recurringMinor > 0)
                        l10n.recurringInPlan(formatMinor(e.recurringMinor)),
                      if (e.previousSpentMinor != null)
                        l10n.comparedToPrevious(
                          _delta(e.spentMinor, e.previousSpentMinor!),
                        ),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// F23: the difference to the period before, in złoty and per cent.
  static String _delta(int now, int before) {
    final diff = now - before;
    final sign = diff > 0 ? '+' : '';
    final percent = before == 0
        ? ''
        : ' ($sign${(diff / before * 100).round()}%)';
    return '$sign${formatMinor(diff)}$percent';
  }
}

/// Who has how much in the piggy bank (F33); a negative share is marked.
class SharesCard extends StatelessWidget {
  const SharesCard({super.key, required this.summary});
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.shares, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final s in summary.shares)
            ValueRow(
              label: s.member ? s.name : '${s.name} · ${l10n.formerMember}',
              value: formatMinor(s.shareMinor),
              valueColor: s.shareMinor < 0 ? c.danger : null,
            ),
          if (summary.nobodyLeftMinor > 0)
            ValueRow(
              label: l10n.nobodysMoney,
              value: formatMinor(summary.nobodyLeftMinor),
            ),
          if (summary.shares.any((s) => s.shareMinor < 0))
            Text(l10n.negativeShareHint, style: TextStyle(color: c.danger)),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});
  final Forecast forecast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.forecast, style: Theme.of(context).textTheme.titleMedium),
          ValueRow(
            small: true,
            label: l10n.forecastSpent,
            value: formatMinor(forecast.projectedSpentMinor),
          ),
          ValueRow(
            small: true,
            label: l10n.forecastRecurring,
            value: formatMinor(forecast.recurringMinor),
          ),
          ValueRow(
            label: l10n.forecastBalance,
            value: formatMinor(forecast.projectedBalanceMinor),
            valueColor: forecast.projectedBalanceMinor < 0 ? c.danger : null,
          ),
        ],
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.members),
          trailing: Text('${household.memberCount}'),
          onTap: () => open(const MembersScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: Text(l10n.periods),
          onTap: () => open(PeriodsScreen(household: household)),
        ),
        ListTile(
          leading: const Icon(Icons.undo),
          title: Text(l10n.changeLog),
          onTap: () => open(LogScreen(household: household)),
        ),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(l10n.householdSettings),
          onTap: () => open(HouseholdSettingsScreen(household: household)),
        ),
      ],
    );
  }
}
