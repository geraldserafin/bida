import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/fab_bar.dart';
import '../../widgets/screen_header.dart';

/// The envelopes of the household (F12): any member adds, renames and
/// archives them. One with expenses is archived, not deleted.
class EnvelopesScreen extends StatelessWidget {
  const EnvelopesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    return Scaffold(
      appBar: FormTopBar(title: l10n.envelopes, where: household?.name),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: household == null
          ? null
          : FabBar(
              children: [
                AppButton(
                  label: l10n.addEnvelope,
                  height: 48,
                  onPressed: () => _edit(context, null),
                ),
              ],
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: [
          for (final e in state.envelopes)
            ListTile(
              leading: Icon(e.displayIcon, color: e.displayColor),
              title: Text(e.name),
              subtitle: e.archived ? Text(l10n.archived) : null,
              textColor: e.archived ? c.textMuted : null,
              onTap: () => _edit(context, e),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => _act(context, e, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(e.archived ? l10n.unarchive : l10n.archive),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context, Envelope e, String action) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    if (action == 'archive') {
      await attemptMoney(
        context,
        () => state.change((repo) => repo.setArchived(e.id, !e.archived)),
      );
      return;
    }
    try {
      await state.change((repo) => repo.deleteEnvelope(e.id));
    } on ApiException catch (error) {
      if (!context.mounted) return;
      if (error.tag != 'EnvelopeHasExpenses') {
        await attemptMoney(context, () => Future.error(error));
        return;
      }
      final archive = await confirmDanger(
        context,
        title: l10n.envelopeHasExpensesTitle,
        body: l10n.errEnvelopeHasExpenses,
        action: l10n.archive,
      );
      if (archive && context.mounted) {
        await attemptMoney(
          context,
          () => state.change((repo) => repo.setArchived(e.id, true)),
        );
      }
    }
  }

  Future<void> _edit(BuildContext context, Envelope? existing) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final household = state.household;
    if (household == null) return;
    final name = TextEditingController(text: existing?.name ?? '');
    var color = existing?.color ?? envelopeColorPalette.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? l10n.addEnvelope : l10n.editEnvelope),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                maxLength: 30,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final hex in envelopeColorPalette)
                    GestureDetector(
                      onTap: () => setState(() => color = hex),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(
                          int.parse('FF${hex.substring(1)}', radix: 16),
                        ),
                        child: hex == color
                            ? const Icon(Icons.check, size: 16)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (saved != true || text.isEmpty || !context.mounted) return;
    await attemptMoney(
      context,
      () => state.change(
        (repo) => existing == null
            ? repo.createEnvelope(household.id, name: text, color: color)
            : repo.updateEnvelope(
                existing.id,
                name: text,
                color: color,
                icon: existing.icon,
              ),
      ),
    );
  }
}
