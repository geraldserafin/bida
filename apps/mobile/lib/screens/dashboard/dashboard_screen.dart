import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/period.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/category_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
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
import '../category_detail/category_detail_screen.dart';
import '../home/home_shell.dart';
import '../period_setup/new_period_screen.dart';
import '../periods/periods_screen.dart';
import '../setup_wizard/setup_wizard_screen.dart';

/// Home tab ("Pulpit"): the household, the chosen period's money in and out,
/// and how full each envelope is.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final period = state.currentPeriod;

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
            if (period == null) return const _SetUpPrompt();
            return _PeriodView(state: state, period: period);
          },
        ),
      ),
      floatingActionButton: period == null || state.isLoading
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

/// Shown before the first period exists: leads into the set-up wizard.
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

class _PeriodView extends StatelessWidget {
  const _PeriodView({required this.state, required this.period});
  final PlannerState state;
  final Period period;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(state: state),
        _PeriodSwitcher(state: state, period: period),
        Expanded(
          child: ListView(
            // room for the add buttons floating over the end of the list
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            children: [
              _SummaryCard(state: state),
              const SizedBox(height: 12),
              _EnvelopesCard(state: state, period: period),
            ],
          ),
        ),
      ],
    );
  }
}

/// The household's name (tapping it opens the household tab) and its
/// members.
class _Header extends StatelessWidget {
  const _Header({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final email = context.watch<AuthState>().email ?? '';
    final name = state.household?.name ?? l10n.appTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context
                  .findAncestorStateOfType<HomeShellState>()
                  ?.select(AppTab.household),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
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
                    l10n.soloSubtitle,
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

/// The period's name between arrows to the previous and the next one.
/// Tapping the name lists all periods.
class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.state, required this.period});
  final PlannerState state;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final previous = state.previousPeriod;
    final next = state.nextPeriod;

    void go(Period? to) {
      if (to == null) return;
      attempt(context, () => state.selectPeriod(to.id!));
    }

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Opacity(
            opacity: previous == null ? 0.3 : 1,
            child: AppIconButton(
              AppIcon.chevronLeft,
              tooltip: l10n.previousPeriod,
              onPressed: previous == null ? null : () => go(previous),
            ),
          ),
          Expanded(
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PeriodsScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    period.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: next == null ? 0.3 : 1,
            child: AppIconButton(
              AppIcon.chevronRight,
              tooltip: l10n.nextPeriod,
              onPressed: next == null ? null : () => go(next),
            ),
          ),
        ],
      ),
    );
  }
}

/// Money in, money out, the balance, and what is not in any envelope.
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
                  value: formatZloty(state.totalSpent),
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
                  l10n.periodBalance,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: c.textSoft,
                  ),
                ),
              ),
              Text(
                formatZloty(state.balance),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: state.balance < 0 ? c.danger : c.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueRow(
            small: true,
            label: over ? l10n.overAllocated : l10n.unallocatedToEnvelopes,
            value: formatZloty(state.unallocated),
            valueColor: over ? c.danger : null,
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

/// Every envelope of the period with what was spent of it.
class _EnvelopesCard extends StatelessWidget {
  const _EnvelopesCard({required this.state, required this.period});
  final PlannerState state;
  final Period period;

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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewPeriodScreen(editPeriod: period),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    l10n.editPlan,
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
          if (state.progress.isEmpty)
            Text(l10n.noEnvelopes, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final (i, p) in state.progress.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              _envelope(context, p),
            ],
        ],
      ),
    );
  }

  Widget _envelope(BuildContext context, CategoryProgress p) {
    return EnvelopeBar(
      color: p.category.displayColor,
      name: p.category.name,
      amounts: '${formatPlain(p.spent)} / ${formatZloty(p.planned)}',
      fraction: p.fraction,
      overspent: p.isOverspent,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(envelopeId: p.envelope.id!),
        ),
      ),
    );
  }
}
