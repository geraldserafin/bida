import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../util/api_errors.dart';

/// The invitations to share an envelope that wait for the user's answer, each
/// with the two ways to answer. Nothing when there are none.
class InvitationsCard extends StatelessWidget {
  const InvitationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final invitations = context.watch<PlannerState>().invitations;
    if (invitations.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final invitation in invitations) ...[
          _InvitationRow(invitation: invitation),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({required this.invitation});
  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = context.read<PlannerState>();
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.invitationBanner(
                      invitation.invitedBy ?? l10n.someone,
                      invitation.envelopeName,
                    ),
                    style: TextStyle(color: scheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => attempt(
                    context,
                    () => state.declineInvitation(invitation.id),
                  ),
                  child: Text(l10n.decline),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final accepted = await attempt(
                      context,
                      () => state.acceptInvitation(invitation.id),
                    );
                    if (accepted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.invitationAccepted)),
                      );
                    }
                  },
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
