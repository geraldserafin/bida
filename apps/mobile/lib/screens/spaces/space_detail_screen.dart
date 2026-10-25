import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sharing_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/spaces_state.dart';
import '../../util/api_errors.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/remote_data.dart';
import 'invite_dialog.dart';

class _Detail {
  const _Detail(this.members, this.invitations);

  final List<SpaceMember> members;
  final List<SpaceInvitation> invitations;
}

/// One budget: who is in it, who is invited, and what its owners and members
/// can do about it.
class SpaceDetailScreen extends StatefulWidget {
  const SpaceDetailScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  /// Changing it makes the lists load again.
  int _version = 0;

  AppSpace? _space(SpacesState spaces) =>
      spaces.spaces.where((s) => s.id == widget.spaceId).firstOrNull;

  Future<_Detail> _load(AppSpace space) async {
    final repo = context.read<SharingRepository>();
    final members = await repo.members(space.id);
    final invitations = space.isShared && space.isOwner
        ? await repo.spaceInvitations(space.id)
        : const <SpaceInvitation>[];
    return _Detail(members, invitations);
  }

  /// Runs a change, then shows what the server now says.
  Future<void> _change(Future<void> Function() action) async {
    final spaces = context.read<SpacesState>();
    final done = await attempt(context, action);
    if (!mounted) return;
    if (done) {
      await spaces.refresh();
      await spaces.reloadMembers();
    }
    if (mounted) setState(() => _version++);
  }

  Future<void> _rename(AppSpace space) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<SharingRepository>();
    final name = await textDialog(
      context,
      title: l10n.editBudget,
      label: l10n.budgetName,
      action: l10n.save,
      initial: space.name,
    );
    if (name == null || !mounted) return;
    await _change(() => repo.updateSpace(space.id, name, space.currency));
  }

  Future<void> _invite(AppSpace space) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<SharingRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final invite = await showInviteDialog(context);
    if (invite == null || !mounted) return;
    await _change(() => repo.invite(space.id, invite.email, invite.role));
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.invitationSent(invite.email))),
    );
  }

  Future<void> _leave(AppSpace space) async {
    final l10n = AppLocalizations.of(context);
    final spaces = context.read<SpacesState>();
    final navigator = Navigator.of(context);
    final sure = await confirmDialog(
      context,
      title: l10n.leaveBudget,
      message: l10n.leaveBudgetConfirm(space.name),
      action: l10n.leaveBudget,
    );
    if (!sure || !mounted) return;
    if (await attempt(context, () => spaces.leave(space))) navigator.pop();
  }

  Future<void> _delete(AppSpace space) async {
    final l10n = AppLocalizations.of(context);
    final spaces = context.read<SpacesState>();
    final navigator = Navigator.of(context);
    final sure = await confirmDialog(
      context,
      title: l10n.deleteBudget,
      message: l10n.deleteBudgetConfirm(space.name),
      action: l10n.delete,
    );
    if (!sure || !mounted) return;
    if (await attempt(context, () => spaces.delete(space))) navigator.pop();
  }

  Future<void> _removeMember(AppSpace space, SpaceMember member) async {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<SharingRepository>();
    final sure = await confirmDialog(
      context,
      title: l10n.removeMember,
      message: l10n.removeMemberConfirm(member.label),
      action: l10n.removeMember,
    );
    if (!sure || !mounted) return;
    await _change(() => repo.removeMember(space.id, member.userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spaces = context.watch<SpacesState>();
    final space = _space(spaces);
    if (space == null) {
      // left or deleted: nothing to show any more
      return Scaffold(appBar: AppBar(title: Text(l10n.budgets)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(space.name),
        actions: [
          if (space.isShared && space.isOwner)
            IconButton(
              tooltip: l10n.editBudget,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _rename(space),
            ),
        ],
      ),
      floatingActionButton: space.isShared && space.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _invite(space),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.invite),
            )
          : null,
      body: RemoteData<_Detail>(
        load: () => _load(space),
        version: '$_version-${space.role}-${space.memberCount}',
        builder: (context, detail) => _Content(
          space: space,
          detail: detail,
          onRename: () => _rename(space),
          onChangeRole: (member, role) => _change(
            () => context.read<SharingRepository>().setRole(
              space.id,
              member.userId,
              role,
            ),
          ),
          onRemoveMember: (member) => _removeMember(space, member),
          onApprove: (invitation) => _change(
            () => context.read<SharingRepository>().approveInvitation(
              space.id,
              invitation.id,
            ),
          ),
          onRevoke: (invitation) => _change(
            () => context.read<SharingRepository>().revokeInvitation(
              space.id,
              invitation.id,
            ),
          ),
          onLeave: () => _leave(space),
          onDelete: () => _delete(space),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.space,
    required this.detail,
    required this.onRename,
    required this.onChangeRole,
    required this.onRemoveMember,
    required this.onApprove,
    required this.onRevoke,
    required this.onLeave,
    required this.onDelete,
  });

  final AppSpace space;
  final _Detail detail;
  final VoidCallback onRename;
  final void Function(SpaceMember member, SpaceRole role) onChangeRole;
  final void Function(SpaceMember member) onRemoveMember;
  final void Function(SpaceInvitation invitation) onApprove;
  final void Function(SpaceInvitation invitation) onRevoke;
  final VoidCallback onLeave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = context.read<AuthState>().email;
    final canManage = space.isShared && space.isOwner;
    final alone = detail.members.length <= 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        _Header(l10n.members),
        for (final member in detail.members)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(member.label.characters.first.toUpperCase()),
              ),
              title: Text(
                member.email == me
                    ? '${member.label} ${l10n.you}'
                    : member.label,
              ),
              subtitle: Text(
                member.role == SpaceRole.owner
                    ? l10n.roleOwner
                    : l10n.roleMember,
              ),
              trailing: canManage
                  ? PopupMenuButton<_MemberAction>(
                      onSelected: (action) => switch (action) {
                        _MemberAction.makeOwner => onChangeRole(
                          member,
                          SpaceRole.owner,
                        ),
                        _MemberAction.makeMember => onChangeRole(
                          member,
                          SpaceRole.member,
                        ),
                        _MemberAction.remove => onRemoveMember(member),
                      },
                      itemBuilder: (_) => [
                        if (member.role == SpaceRole.member)
                          PopupMenuItem(
                            value: _MemberAction.makeOwner,
                            child: Text(l10n.makeOwner),
                          )
                        else
                          PopupMenuItem(
                            value: _MemberAction.makeMember,
                            child: Text(l10n.makeMember),
                          ),
                        if (member.email != me)
                          PopupMenuItem(
                            value: _MemberAction.remove,
                            child: Text(l10n.removeMember),
                          ),
                      ],
                    )
                  : null,
            ),
          ),
        if (detail.invitations.isNotEmpty) ...[
          _Header(l10n.pendingInvitations),
          for (final invitation in detail.invitations)
            Card(
              child: ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text(invitation.email),
                subtitle: Text(
                  invitation.status == InvitationStatus.accepted
                      ? l10n.invitationAcceptedWaiting
                      : l10n.invitationWaiting,
                ),
                trailing: invitation.status == InvitationStatus.accepted
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => onRevoke(invitation),
                            child: Text(l10n.reject),
                          ),
                          FilledButton(
                            onPressed: () => onApprove(invitation),
                            child: Text(l10n.approve),
                          ),
                        ],
                      )
                    : IconButton(
                        tooltip: l10n.revokeInvitation,
                        icon: const Icon(Icons.close),
                        onPressed: () => onRevoke(invitation),
                      ),
              ),
            ),
        ],
        if (space.isShared) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.logout),
            label: Text(l10n.leaveBudget),
          ),
          if (space.isOwner && alone) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.deleteBudget),
            ),
          ],
        ],
      ],
    );
  }
}

enum _MemberAction { makeOwner, makeMember, remove }

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
