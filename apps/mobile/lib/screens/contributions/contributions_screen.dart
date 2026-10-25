import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/sharing_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../state/spaces_state.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/remote_data.dart';
import 'add_contribution_dialog.dart';

/// What was paid into the budget of the current period, by whom.
class ContributionsScreen extends StatefulWidget {
  const ContributionsScreen({super.key});

  @override
  State<ContributionsScreen> createState() => _ContributionsScreenState();
}

class _ContributionsScreenState extends State<ContributionsScreen> {
  /// Changing it makes the list load again.
  int _version = 0;

  Future<void> _changed() async {
    // the dashboard shows the total too
    await context.read<PlannerState>().reloadProgress();
    if (mounted) setState(() => _version++);
  }

  Future<void> _add(Period period) async {
    final repo = context.read<SharingRepository>();
    final input = await showAddContributionDialog(context);
    if (input == null || !mounted) return;
    final added = await attempt(
      context,
      () => repo.addContribution(
        period.id!,
        amount: input.amount,
        currency: period.currency,
        date: DateTime.now(),
        note: input.note,
        external: input.external,
      ),
    );
    if (added) await _changed();
  }

  Future<void> _delete(Contribution contribution) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<SharingRepository>();
    final sure = await confirmDialog(
      context,
      title: l10n.delete,
      message: l10n.deleteContributionConfirm,
      action: l10n.delete,
    );
    if (!sure || !mounted) return;
    final deleted = await attempt(
      context,
      () => repo.deleteContribution(contribution.id),
    );
    if (deleted) await _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final period = context.watch<PlannerState>().currentPeriod;
    final spaces = context.watch<SpacesState>();
    final email = context.read<AuthState>().email;
    final me = spaces.members.where((m) => m.email == email).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributions)),
      floatingActionButton: period == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _add(period),
              icon: const Icon(Icons.add),
              label: Text(l10n.addContribution),
            ),
      body: period == null
          ? const SizedBox.shrink()
          : RemoteData<List<Contribution>>(
              load: () => context.read<SharingRepository>().contributions(
                period.id!,
                period.currency,
              ),
              version: '$_version-${period.id}',
              builder: (context, contributions) => _List(
                contributions: contributions,
                spaces: spaces,
                canDelete: (c) =>
                    spaces.isOwner || (me != null && c.userId == me.userId),
                onDelete: _delete,
              ),
            ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.contributions,
    required this.spaces,
    required this.canDelete,
    required this.onDelete,
  });

  final List<Contribution> contributions;
  final SpacesState spaces;
  final bool Function(Contribution) canDelete;
  final void Function(Contribution) onDelete;

  String _who(AppLocalizations l10n, String? userId) {
    if (userId == null) return l10n.outsideMoney;
    return spaces.memberById(userId)?.label ?? l10n.formerMember;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (contributions.isEmpty) {
      return Center(child: Text(l10n.noContributions));
    }
    final totals = <String?, double>{};
    for (final c in contributions) {
      totals.update(c.userId, (v) => v + c.amount, ifAbsent: () => c.amount);
    }
    final day = DateFormat.yMMMd('pl');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(
            l10n.byPerson.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final entry in totals.entries)
                ListTile(
                  dense: true,
                  title: Text(_who(l10n, entry.key)),
                  trailing: Text(
                    formatZloty(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in contributions)
          Card(
            child: ListTile(
              title: Text(formatZloty(c.amount)),
              subtitle: Text(
                [
                  _who(l10n, c.userId),
                  day.format(c.date),
                  if (c.note != null && c.note!.isNotEmpty) c.note!,
                ].join(' · '),
              ),
              trailing: canDelete(c)
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onDelete(c),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
