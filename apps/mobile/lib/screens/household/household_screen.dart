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
import '../../widgets/fab_bar.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../add_expense/add_expense_screen.dart';
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
    final spending =
        summary?.period.status == PeriodStatus.current &&
        household?.frozen == false;
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: spending
          ? FabBar(
              children: [
                AppButton(
                  label: l10n.addExpenseShort,
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  ),
                ),
              ],
            )
          : null,
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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

/// ( < ) ( 1.11 – 30.11 ) ( > ): steps through the periods of the household.
/// Past the current one it opens the next period, after asking.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.household, required this.shown});
  final Household household;
  final Period shown;

  Future<void> _openNext(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final starts = household.current.endsOn.add(const Duration(days: 1));
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.openNextPeriod),
        content: Text(
          l10n.openNextConfirm(DateFormat('d.MM.yyyy').format(starts)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.openNextPeriod),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    await attemptMoney(context, () async {
      final period = await state.repository.openNextPeriod(household.id);
      await state.showPeriod(period.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.read<BudgetState>();
    final periods = context.watch<BudgetState>().periods;
    final index = periods.indexWhere((p) => p.id == shown.id);
    final previous = index > 0 ? periods[index - 1] : null;
    final later = index >= 0 && index < periods.length - 1
        ? periods[index + 1]
        : null;
    // past the current period with no next one: the arrow opens it
    final canOpen =
        later == null &&
        shown.status == PeriodStatus.current &&
        household.next == null;
    final status = switch (shown.status) {
      PeriodStatus.current => l10n.currentPeriod,
      PeriodStatus.next => l10n.nextPeriod,
      PeriodStatus.closed => l10n.closedPeriod,
    };
    return Row(
      children: [
        IconButton.outlined(
          tooltip: l10n.previousPeriodTooltip,
          onPressed: previous == null
              ? null
              : () => state.showPeriod(
                  previous.id == household.current.id ? null : previous.id,
                ),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${_day.format(shown.startsOn)} – ${_day.format(shown.endsOn)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(status, style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          ),
        ),
        IconButton.outlined(
          tooltip: canOpen ? l10n.openNextPeriod : l10n.nextPeriodTooltip,
          onPressed: later != null
              ? () => state.showPeriod(
                  later.id == household.current.id ? null : later.id,
                )
              : canOpen
              ? () => _openNext(context)
              : null,
          icon: Icon(canOpen ? Icons.add : Icons.chevron_right),
        ),
      ],
    );
  }
}

/// What is free to plan and what the plans hold, up front (F19); the balance
/// and how it came about (F16) one tap away. The warning when the plans
/// exceed the balance always shows.
class PiggyBankCard extends StatefulWidget {
  const PiggyBankCard({
    super.key,
    required this.summary,
    this.expanded = false,
  });
  final PeriodSummary summary;

  /// Start with the details shown (a past period).
  final bool expanded;

  @override
  State<PiggyBankCard> createState() => _PiggyBankCardState();
}

class _PiggyBankCardState extends State<PiggyBankCard> {
  late bool _expanded = widget.expanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final s = widget.summary;
    Widget figure(String label, int minor, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            formatMinor(minor),
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
    return SurfaceCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              figure(
                l10n.freeMoneyLabel,
                s.freeMinor,
                color: s.freeMinor < 0 ? c.warning : c.accent,
              ),
              figure(l10n.plansTotal, s.plansTotalMinor),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            ],
          ),
          if (s.plansExceedBalance)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.plansExceedBalance,
                style: TextStyle(color: c.warning),
              ),
            ),
          if (_expanded) ...[
            const Divider(),
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
                value: formatMinor(s.withdrawalsMinor),
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
              value: formatMinor(s.spentMinor),
            ),
            if (s.estimatedSpentMinor > 0)
              ValueRow(
                small: true,
                label: l10n.estimatedSpent,
                value: formatMinor(s.estimatedSpentMinor),
                valueColor: c.estimate,
              ),
            if (s.carryOutMinor != null)
              ValueRow(
                label: l10n.closedCarried,
                value: formatMinor(s.carryOutMinor!),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.piggyBalanceShort(formatMinor(s.balanceMinor)),
                style: theme.textTheme.bodySmall?.copyWith(color: c.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Przelej" is the everyday button; "Wycofaj" is rare, so it stays small.
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
            label: l10n.transferFromWallet,
            kind: ButtonKind.tonal,
            height: 40,
            onPressed: () => _move(context, withdraw: false),
          ),
        ),
        const SizedBox(width: 10),
        SmallButton(
          label: l10n.withdraw,
          outlined: true,
          onPressed: () => _move(context, withdraw: true),
        ),
      ],
    );
  }
}

/// The envelopes with plan, spent and left (F17, F19). Tapping one adds an
/// expense to it (F08) or changes its plan.
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

  Future<void> _choose(BuildContext context, EnvelopeFigures e) async {
    final l10n = AppLocalizations.of(context);
    final spend = summary.period.status == PeriodStatus.current;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(e.name, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            if (spend)
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: Text(l10n.todoAddExpense),
                onTap: () => Navigator.of(ctx).pop('spend'),
              ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text(l10n.changePlan),
              onTap: () => Navigator.of(ctx).pop('plan'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'plan') return _setPlan(context, e);
    if (action == 'spend') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(initialEnvelopeId: e.envelopeId),
        ),
      );
    }
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
              onTap: open && !e.archived ? () => _choose(context, e) : null,
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
