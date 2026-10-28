import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../util/month_label.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/avatar.dart';
import '../../widgets/bottom_menu.dart';
import '../../widgets/error_view.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/logo_box.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../add_expense/add_expense_screen.dart';
import '../add_income/add_income_screen.dart';
import '../envelope_detail/envelope_detail_screen.dart';
import '../funding/fund_sheet.dart';
import '../home/home_shell.dart';
import '../months/months_screen.dart';
import '../setup_wizard/setup_wizard_screen.dart';
import '../sharing/invitations_card.dart';
import 'widgets/pending_rules_card.dart';

/// Home tab ("Pulpit"): the month's money in and out, what is not in any
/// envelope yet, and how much is left in each envelope.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final empty = state.envelopes.isEmpty && state.isEmpty;

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
            return _MonthView(state: state);
          },
        ),
      ),
      floatingActionButton: empty || state.isLoading || state.loadError != null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: l10n.addIncomeShort,
                  kind: ButtonKind.raised,
                  height: 48,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
                  ),
                ),
                const SizedBox(width: 10),
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

/// Shown before there is anything: the invitations to shared envelopes, and
/// the way into the set-up wizard.
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

class _MonthView extends StatelessWidget {
  const _MonthView({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(state: state),
        _MonthSwitcher(state: state),
        Expanded(
          child: ListView(
            // room for the add buttons floating over the end of the list
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              const InvitationsCard(),
              const PendingRulesCard(),
              _SummaryCard(state: state),
              const SizedBox(height: 12),
              _EnvelopesCard(state: state),
            ],
          ),
        ),
      ],
    );
  }
}

/// The app's name over how many envelopes are shared; tapping it opens the
/// envelopes tab.
class _Header extends StatelessWidget {
  const _Header({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final email = context.watch<AuthState>().email ?? '';
    final shared = state.topLevelProgress.where((p) => p.isShared).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context
                  .findAncestorStateOfType<HomeShellState>()
                  ?.select(AppTab.envelopes),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const AppIconView(AppIcon.chevronDown),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shared == 0
                        ? l10n.soloSubtitle
                        : l10n.sharedEnvelopes(shared),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Avatar(name: email, color: avatarColors.first, size: 32, ring: true),
        ],
      ),
    );
  }
}

/// The month on screen between arrows to the previous and the next one.
/// Tapping the name lists the months with something in them.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          AppIconButton(
            AppIcon.chevronLeft,
            tooltip: l10n.previousMonth,
            onPressed: () => attempt(context, state.previousMonth),
          ),
          Expanded(
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const MonthsScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    monthLabel(state.month),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
          ),
          AppIconButton(
            AppIcon.chevronRight,
            tooltip: l10n.nextMonth,
            onPressed: () => attempt(context, state.nextMonth),
          ),
        ],
      ),
    );
  }
}

/// Money in, money out, what is not in any envelope, and what went in.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final over = state.isOverAllocated;

    return SurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: l10n.incomes,
                  value: formatZloty(state.income),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  label: l10n.expenses,
                  value: formatZloty(state.spent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  over ? l10n.overAllocated : l10n.unallocatedToEnvelopes,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: over ? c.danger : c.textSoft,
                  ),
                ),
              ),
              Text(
                formatZloty(state.pool),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: over ? c.danger : c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueRow(
            small: true,
            label: l10n.allocatedThisMonth,
            value: formatZloty(state.allocated),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Overline(label),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.of(context).text,
          ),
        ),
      ],
    );
  }
}

/// Every top-level envelope with what was spent of what it had this month.
class _EnvelopesCard extends StatelessWidget {
  const _EnvelopesCard({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);

    return SurfaceCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.envelopes,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: state.envelopes.isEmpty
                    ? null
                    : () => showFundSheet(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    l10n.allocate,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.topLevelProgress.isEmpty)
            Text(l10n.noEnvelopes, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final (i, p) in state.topLevelProgress.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _envelope(context, p),
            ],
        ],
      ),
    );
  }

  Widget _envelope(BuildContext context, EnvelopeProgress p) {
    final l10n = AppLocalizations.of(context);
    return EnvelopeBar(
      color: p.envelope.displayColor,
      name: p.isShared
          ? '${p.envelope.name} · ${l10n.sharedWith(p.memberCount)}'
          : p.envelope.name,
      amounts: '${formatPlain(p.spent)} / ${formatZloty(p.available)}',
      fraction: p.fraction,
      overspent: p.isOverspent,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnvelopeDetailScreen(envelopeId: p.envelope.id!),
        ),
      ),
    );
  }
}
