import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../util/api_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/surface_card.dart';

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
    final state = context.read<PlannerState>();
    return SurfaceCard(
      outline: CardOutline.selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.invitationBanner(
              invitation.invitedBy ?? l10n.someone,
              invitation.envelopeName,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SmallButton(
                label: l10n.decline,
                outlined: true,
                onPressed: () => attempt(
                  context,
                  () => state.declineInvitation(invitation.id),
                ),
              ),
              const SizedBox(width: 8),
              SmallButton(
                label: l10n.accept,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
