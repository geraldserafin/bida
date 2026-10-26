import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/household.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/avatar.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../categories/categories_screen.dart';
import '../periods/periods_screen.dart';
import '../settings/settings_screen.dart';

/// Household tab ("Gospodarstwo"): the households, who is in the current one,
/// and the way to periods, categories and settings.
///
/// Sharing a household is still to come, so inviting is shown but disabled.
class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final email = context.watch<AuthState>().email ?? '';
    final current = state.household;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TabTitle(l10n.households),
            ),
            const SizedBox(height: 14),
            RemoteData<List<Household>>(
              version: current?.name,
              load: state.households,
              builder: (context, households) => Column(
                children: [
                  for (final h in households) ...[
                    _HouseholdCard(
                      household: h,
                      current: h.id == current?.id,
                      balance: h.id == current?.id ? state.balance : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            AppButton(
              label: l10n.newHouseholdPlus,
              kind: ButtonKind.dashed,
              onPressed: null,
            ),
            const SizedBox(height: 16),
            Overline(l10n.membersOf(current?.name ?? l10n.appTitle)),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _MemberRow(email: email),
            ),
            const SizedBox(height: 8),
            AppButton(label: l10n.invitePerson, onPressed: null),
            const SizedBox(height: 8),
            Text(
              l10n.sharingSoon,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Overline(l10n.more),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _LinkRow(label: l10n.periods, screen: const PeriodsScreen()),
                  _LinkRow(
                    label: l10n.categories,
                    screen: const CategoriesScreen(),
                  ),
                  _LinkRow(
                    label: l10n.settings,
                    screen: const SettingsScreen(),
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({
    required this.household,
    required this.current,
    required this.balance,
  });

  final Household household;
  final bool current;

  /// The current period's balance; only known for the current household.
  final double? balance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final balance = this.balance;
    return SurfaceCard(
      outline: current ? CardOutline.selected : CardOutline.normal,
      onTap: current ? () => _rename(context) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  household.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.soloSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (balance != null)
            Text(
              formatZloty(balance),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: balance < 0 ? c.danger : c.accent,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final controller = TextEditingController(text: household.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameHousehold),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.householdName),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == household.name || !context.mounted) {
      return;
    }
    await attempt(context, () => state.renameHousehold(trimmed));
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final name = email.split('@').first;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Avatar(name: name, color: avatarColors.first),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.youMark(name),
                  style: TextStyle(fontSize: 15, height: 1.5, color: c.text),
                ),
                Text(l10n.owner, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of the "more" card that opens [screen].
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.screen,
    this.last = false,
  });

  final String label;
  final Widget screen;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, height: 1.5, color: c.text),
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
