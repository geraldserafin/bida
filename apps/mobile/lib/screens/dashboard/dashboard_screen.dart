import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/fab_bar.dart';
import '../../widgets/bottom_menu.dart';
import '../../widgets/error_view.dart';
import '../../widgets/logo_box.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../add_expense/add_expense_screen.dart';
import '../home/home_shell.dart';
import '../settings/settings_screen.dart';
import '../setup_wizard/setup_wizard_screen.dart';
import '../summary/closed_summary_screen.dart';
import '../wallet/wallet_screen.dart';
import 'todo_card.dart';

final _day = DateFormat('d.MM');

/// Home tab ("Pulpit"): the wallet as of today, the to-do list, and the
/// households over the range chosen in the settings (F38).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showingSummary = false;

  /// The happy event (F35): each closed period once, after the app start.
  void _showSummaries(BudgetState state) {
    if (_showingSummary || state.unseenSummaries.isEmpty) return;
    _showingSummary = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final summary = state.unseenSummaries.first;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClosedSummaryScreen(summary: summary),
        ),
      );
      await state.summarySeen(summary);
      _showingSummary = false;
      if (mounted) _showSummaries(state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    if (!state.isLoading && state.loadError == null) _showSummaries(state);
    final empty = state.households.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final loadError = state.loadError;
            if (loadError != null) {
              return ErrorView(error: loadError, onRetry: state.load);
            }
            if (empty) return const _SetUpPrompt();
            return RefreshIndicator(
              onRefresh: state.load,
              child: _Overview(state: state),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: empty || state.isLoading || state.loadError != null
          ? null
          : FabBar(
              children: [
                AppButton(
                  label: l10n.addExpenseShort,
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Before there is a household: the invitations, and the set-up wizard.
class _SetUpPrompt extends StatelessWidget {
  const _SetUpPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InvitationsCard(),
            const Align(alignment: Alignment.centerLeft, child: LogoBox()),
            const SizedBox(height: 14),
            Text(l10n.wizardStartTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              l10n.wizardStartBody,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.of(context).textMuted,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.wizardStart,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SetupWizardScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});
  final BudgetState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final range = state.dashboardRange;
    final overview = state.overview;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Row(
          children: [
            Expanded(child: TabTitle(l10n.dashboard)),
            IconButton(
              tooltip: l10n.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const InvitationsCard(),
        _WalletCard(wallet: state.wallet),
        const SizedBox(height: 16),
        const TodoCard(),
        Text(
          l10n.dashboardRangeLabel(
            _day.format(range.start),
            _day.format(range.end),
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final h in overview?.households ?? const <HouseholdOverview>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HouseholdCard(household: h),
          ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet});
  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return SurfaceCard(
      outline: wallet.negative ? CardOutline.estimate : CardOutline.normal,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.wallet, style: theme.textTheme.bodySmall),
                Text(
                  formatMinor(wallet.balanceMinor),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: wallet.negative ? c.danger : null,
                  ),
                ),
                if (wallet.unconfirmedMinor > 0)
                  Text(
                    l10n.walletUnconfirmed(
                      formatMinor(wallet.unconfirmedMinor),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: c.estimate,
                    ),
                  ),
                if (wallet.negative)
                  Text(
                    l10n.walletNegativeHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: c.danger),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({required this.household});
  final HouseholdOverview household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: () async {
        await context.read<BudgetState>().selectHousehold(household.id);
        if (!context.mounted) return;
        context.findAncestorStateOfType<HomeShellState>()?.select(
          AppTab.household,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(household.name, style: theme.textTheme.titleMedium),
              ),
              Text(
                formatMinor(household.balanceMinor),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.householdSpentInRange(formatMinor(household.spentMinor)),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            household.freeMinor < 0
                ? l10n.plansExceedBalance
                : l10n.freeMoney(formatMinor(household.freeMinor)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: household.freeMinor < 0 ? c.warning : c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invitations to households waiting for the user's answer (F13).
class InvitationsCard extends StatelessWidget {
  const InvitationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    if (state.invitations.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final i in state.invitations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
              outline: CardOutline.selected,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.invitationTo(i.householdName),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (i.invitedBy != null) Text(l10n.invitedBy(i.invitedBy!)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SmallButton(
                        label: l10n.accept,
                        onPressed: () => state.acceptInvitation(i.id),
                      ),
                      const SizedBox(width: 8),
                      SmallButton(
                        label: l10n.decline,
                        outlined: true,
                        onPressed: () => state.change(
                          (repo) => repo.declineInvitation(i.id),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
