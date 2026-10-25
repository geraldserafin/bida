import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/spaces_state.dart';
import '../../util/api_errors.dart';
import '../../widgets/space_chooser.dart';
import 'space_detail_screen.dart';

/// All the budgets of the user, the invitations to others, and a way to start a
/// shared one.
class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spaces = context.watch<SpacesState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createSharedBudget(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSharedBudget),
      ),
      body: RefreshIndicator(
        onRefresh: spaces.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            if (spaces.invitations.isNotEmpty) ...[
              _Header(l10n.invitationsForYou),
              for (final invitation in spaces.invitations)
                _InvitationCard(invitation: invitation),
            ],
            _Header(l10n.yourBudgets),
            for (final space in spaces.spaces)
              Card(
                child: ListTile(
                  leading: Icon(spaceIcon(space)),
                  title: Text(space.name),
                  subtitle: Text(
                    space.isShared
                        ? '${space.isOwner ? l10n.roleOwner : l10n.roleMember}'
                              ' · ${l10n.membersCount(space.memberCount)}'
                        : l10n.personalBudget,
                  ),
                  trailing: space.id == spaces.current?.id
                      ? const Icon(Icons.check)
                      : const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SpaceDetailScreen(spaceId: space.id),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({required this.invitation});

  final SpaceInvitation invitation;

  Future<void> _answer(BuildContext context, {required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    final spaces = context.read<SpacesState>();
    final messenger = ScaffoldMessenger.of(context);
    final answered = await attempt(
      context,
      () => spaces.answerInvitation(invitation, accept: accept),
    );
    if (answered && accept) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.invitationAcceptedInfo)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final by = invitation.invitedBy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              by == null
                  ? l10n.invitationFromUnknown(invitation.spaceName)
                  : l10n.invitationFrom(invitation.spaceName, by),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _answer(context, accept: false),
                  child: Text(l10n.decline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _answer(context, accept: true),
                  child: Text(l10n.accept),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
