import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../util/sharing_errors.dart';
import '../../widgets/remote_data.dart';
import 'invite_dialog.dart';

/// Who shares an envelope: the members with their roles, the open invitations,
/// and the ways to invite, let in, remove or leave.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.envelopeId});

  /// The envelope, or one of its sub-envelopes (they have the same members).
  final String envelopeId;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  /// Bumped after a change so the lists are fetched again.
  int _version = 0;

  /// Runs a change and, when the server refuses, says why. Returns whether it
  /// worked.
  Future<bool> _run(Future<void> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await action();
      if (mounted) setState(() => _version++);
      return true;
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(sharingErrorMessage(l10n, error))),
      );
      return false;
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true && mounted;
  }

  Future<void> _invite(String topId) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);
    final invitation = await showInviteDialog(context);
    if (invitation == null || !mounted) return;
    final sent = await _run(
      () => state.invite(topId, email: invitation.email, role: invitation.role),
    );
    if (sent) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.invitationSent(invitation.email))),
      );
    }
  }

  Future<void> _leave(String topId, String myUserId, String name) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await _confirm(
      l10n.leaveEnvelope,
      l10n.leaveEnvelopeConfirm(name),
      l10n.leave,
    )) {
      return;
    }
    final left = await _run(
      () => state.removeMember(topId, myUserId, leaving: true),
    );
    if (left) {
      // the envelope is not theirs to see any more
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(SnackBar(content: Text(l10n.leftEnvelope)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final myEmail = context.watch<AuthState>().email;
    final progress = state.progressOf(widget.envelopeId);
    if (progress == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final envelope = progress.envelope;
    final topId = envelope.parentId ?? envelope.id!;
    final top = state.envelopeById(topId) ?? envelope;
    final isOwner = progress.isOwner;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersOf(top.name))),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _invite(topId),
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: Text(l10n.invite),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          RemoteData<List<Member>>(
            version: (_version, progress.memberCount),
            load: () => state.membersOf(topId),
            builder: (context, members) {
              final me = members.where((m) => m.email == myEmail).firstOrNull;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final member in members)
                    _MemberTile(
                      member: member,
                      isMe: member.email == myEmail,
                      canManage: isOwner && member.email != myEmail,
                      onSetRole: (role) =>
                          _run(() => state.setRole(topId, member.userId, role)),
                      onRemove: () async {
                        if (await _confirm(
                          l10n.removeMember,
                          l10n.removeMemberConfirm(member.displayName),
                          l10n.remove,
                        )) {
                          await _run(
                            () => state.removeMember(topId, member.userId),
                          );
                        }
                      },
                    ),
                  if (me != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _leave(topId, me.userId, top.name),
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.leaveEnvelope),
                      ),
                    ),
                ],
              );
            },
          ),
          if (isOwner)
            RemoteData<List<Invitation>>(
              version: _version,
              load: () => state.invitationsOf(topId),
              builder: (context, invitations) => invitations.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                          child: Text(
                            l10n.invitations,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        for (final invitation in invitations)
                          _InvitationTile(
                            invitation: invitation,
                            onApprove: () => _run(
                              () =>
                                  state.approveInvitation(topId, invitation.id),
                            ),
                            onRevoke: () => _run(
                              () =>
                                  state.revokeInvitation(topId, invitation.id),
                            ),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.canManage,
    required this.onSetRole,
    required this.onRemove,
  });

  final Member member;
  final bool isMe;
  final bool canManage;
  final ValueChanged<EnvelopeRole> onSetRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isOwner = member.role == EnvelopeRole.owner;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Text(
          member.displayName.characters.first.toUpperCase(),
          style: TextStyle(color: scheme.onPrimaryContainer),
        ),
      ),
      title: Text(isMe ? l10n.youWith(member.displayName) : member.displayName),
      subtitle: Text(member.name == null ? '' : member.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(isOwner ? l10n.roleOwner : l10n.roleMember),
          ),
          if (canManage)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') {
                  onRemove();
                } else {
                  onSetRole(isOwner ? EnvelopeRole.member : EnvelopeRole.owner);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Text(isOwner ? l10n.makeMember : l10n.makeOwner),
                ),
                PopupMenuItem(value: 'remove', child: Text(l10n.removeMember)),
              ],
            ),
        ],
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.onApprove,
    required this.onRevoke,
  });

  final Invitation invitation;
  final VoidCallback onApprove;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accepted = invitation.status == InvitationStatus.accepted;
    return ListTile(
      leading: const Icon(Icons.mail_outline),
      title: Text(invitation.email),
      subtitle: Text(
        accepted ? l10n.awaitingApproval : l10n.awaitingAnswer,
        style: TextStyle(
          color: accepted ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accepted)
            IconButton(
              tooltip: l10n.approve,
              icon: const Icon(Icons.check_circle_outline),
              onPressed: onApprove,
            ),
          IconButton(
            tooltip: accepted ? l10n.reject : l10n.revokeInvitation,
            icon: const Icon(Icons.close),
            onPressed: onRevoke,
          ),
        ],
      ),
    );
  }
}
