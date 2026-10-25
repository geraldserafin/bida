import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../state/spaces_state.dart';
import '../../../widgets/space_chooser.dart';
import '../../spaces/spaces_screen.dart';

/// Which budget the app is in, with a way to switch, and a nudge when
/// somebody invited the user to theirs. Hidden for a user with one budget and
/// no invitations.
class BudgetHeader extends StatelessWidget {
  const BudgetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spaces = context.watch<SpacesState>();
    final current = spaces.current;
    final removed = spaces.removedFrom;

    // tell the user once that they are not in a budget any more
    if (removed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.removedFromBudget(removed))),
        );
        spaces.clearRemovedNotice();
      });
    }

    final show = spaces.spaces.length > 1 || spaces.invitations.isNotEmpty;
    if (current == null || !show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          ActionChip(
            avatar: Icon(spaceIcon(current), size: 18),
            label: Text(current.name),
            onPressed: () => showSpaceChooser(context),
          ),
          const Spacer(),
          if (spaces.invitations.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.mail_outline, size: 18),
              label: Text(l10n.invitationsBanner(spaces.invitations.length)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SpacesScreen()),
              ),
            ),
        ],
      ),
    );
  }
}
