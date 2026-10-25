import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../screens/spaces/spaces_screen.dart';
import '../state/spaces_state.dart';
import '../util/api_errors.dart';
import 'dialogs.dart';

/// The icon of a budget: a person for the personal one, a group for shared.
IconData spaceIcon(AppSpace space) =>
    space.isShared ? Icons.groups_outlined : Icons.person_outline;

/// Lets the user pick the budget the app works in.
Future<void> showSpaceChooser(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SpaceChooser(),
  );
}

/// Asks for a name and creates a shared budget that becomes the one in use.
Future<void> createSharedBudget(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final spaces = context.read<SpacesState>();
  final name = await textDialog(
    context,
    title: l10n.newSharedBudget,
    label: l10n.budgetName,
    action: l10n.save,
  );
  if (name == null || !context.mounted) return;
  await attempt(context, () => spaces.createShared(name, 'PLN'));
}

class _SpaceChooser extends StatelessWidget {
  const _SpaceChooser();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spaces = context.watch<SpacesState>();

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.switchBudget,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final space in spaces.spaces)
              ListTile(
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
                    : null,
                onTap: () async {
                  Navigator.of(context).pop();
                  await spaces.select(space.id);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.newSharedBudget),
              onTap: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await createSharedBudget(navigator.context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: Text(l10n.manageBudgets),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.push(
                  MaterialPageRoute<void>(builder: (_) => const SpacesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
