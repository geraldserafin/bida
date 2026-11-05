import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../util/money_format.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';

/// The members of the household with their roles and shares (F14). Owners
/// give and take the owner role (F22), freeze and remove members (F36) and
/// invite people (F13); anybody leaves.
class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    if (household == null) return const SizedBox.shrink();
    final owner = household.isOwner;
    return Scaffold(
      appBar: FormTopBar(title: l10n.members, where: household.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
        children: [
          for (final m in state.members)
            ListTile(
              title: Text(m.displayName),
              subtitle: Text(
                [
                  m.role == Role.owner ? l10n.roleOwner : l10n.roleMember,
                  if (m.frozen) l10n.frozen,
                  l10n.shareOf(formatMinor(m.shareMinor)),
                ].join(' · '),
                style: TextStyle(color: m.shareMinor < 0 ? c.danger : null),
              ),
              trailing: owner
                  ? PopupMenuButton<String>(
                      onSelected: (a) => _act(context, household, m, a),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'role',
                          child: Text(
                            m.role == Role.owner
                                ? l10n.takeOwner
                                : l10n.makeOwner,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'freeze',
                          child: Text(m.frozen ? l10n.unfreeze : l10n.freeze),
                        ),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(l10n.removeMember),
                        ),
                      ],
                    )
                  : null,
            ),
          if (owner) ...[
            const Divider(),
            RemoteData<List<Invitation>>(
              version: state.version,
              load: () => state.repository.householdInvitations(household.id),
              builder: (context, invitations) => Column(
                children: [
                  for (final i in invitations)
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: Text(i.email),
                      subtitle: Text(l10n.invitationPending),
                      trailing: IconButton(
                        tooltip: l10n.revoke,
                        icon: const Icon(Icons.close),
                        onPressed: () => attemptMoney(
                          context,
                          () => state.change(
                            (repo) => repo.revokeInvitation(household.id, i.id),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: AppButton(
                label: l10n.invite,
                kind: ButtonKind.secondary,
                onPressed: () => _invite(context, household),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8),
            child: AppButton(
              label: l10n.leaveHousehold,
              kind: ButtonKind.secondary,
              onPressed: () => _leave(context, household),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _act(
    BuildContext context,
    Household household,
    Member m,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    switch (action) {
      case 'role':
        final yes = await confirmDanger(
          context,
          title: m.role == Role.owner ? l10n.takeOwner : l10n.makeOwner,
          body: l10n.roleConfirm(m.displayName),
          action: l10n.confirm,
        );
        if (!yes || !context.mounted) return;
        await attemptMoney(
          context,
          () => state.change(
            (repo) => repo.setRole(
              household.id,
              m.userId,
              m.role == Role.owner ? Role.member : Role.owner,
            ),
          ),
        );
      case 'freeze':
        await attemptMoney(
          context,
          () => state.change(
            (repo) => repo.setFrozen(household.id, m.userId, !m.frozen),
          ),
        );
      case 'remove':
        final yes = await confirmDanger(
          context,
          title: l10n.removeMember,
          body: l10n.removeMemberConfirm(m.displayName),
          action: l10n.removeMember,
        );
        if (!yes || !context.mounted) return;
        await attemptMoney(
          context,
          () =>
              state.change((repo) => repo.removeMember(household.id, m.userId)),
        );
    }
  }

  Future<void> _invite(BuildContext context, Household household) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final email = TextEditingController();
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.invite),
        content: TextField(
          controller: email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.email),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    final address = email.text.trim();
    email.dispose();
    if (send != true || address.isEmpty || !context.mounted) return;
    await attemptMoney(
      context,
      () => state.change((repo) => repo.invite(household.id, address)),
    );
  }

  /// F36: the dialog offers to take the shares back to the wallet.
  Future<void> _leave(BuildContext context, Household household) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.leaveHousehold),
        content: Text(l10n.leaveBody(household.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.leaveKeepShares),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.leaveWithdraw),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await attemptMoney(
      context,
      () => state.leaveHousehold(household.id, withdraw: choice),
    );
    if (ok) navigator.pop();
  }
}
