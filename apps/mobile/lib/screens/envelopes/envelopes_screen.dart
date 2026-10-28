import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/envelope.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import 'envelope_editor.dart';

/// Manage the envelopes: the top-level ones with their sub-envelopes.
class EnvelopesScreen extends StatelessWidget {
  const EnvelopesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final top = state.topLevel;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageEnvelopes)),
      body: top.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noEnvelopes, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final envelope in top) ...[
                  _EnvelopeRow(envelope: envelope),
                  for (final child in state.childrenOf(envelope.id!))
                    _EnvelopeRow(envelope: child, indent: true),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showEnvelopeEditor(context);
          if (created != null && context.mounted) {
            final planner = context.read<PlannerState>();
            await attempt(context, () => planner.addEnvelope(created));
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addEnvelope),
      ),
    );
  }
}

class _EnvelopeRow extends StatelessWidget {
  const _EnvelopeRow({required this.envelope, this.indent = false});

  final Envelope envelope;
  final bool indent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent ? 40 : 16, right: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: envelope.displayColor.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          envelope.displayIcon,
          color: envelope.displayColor,
          size: 20,
        ),
      ),
      title: Text(envelope.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (envelope.isTopLevel)
            IconButton(
              tooltip: l10n.addSubEnvelope,
              icon: const Icon(Icons.subdirectory_arrow_right),
              onPressed: () async {
                final created = await showEnvelopeEditor(
                  context,
                  parentId: envelope.id,
                );
                if (created != null && context.mounted) {
                  final planner = context.read<PlannerState>();
                  await attempt(context, () => planner.addEnvelope(created));
                }
              },
            ),
          IconButton(
            tooltip: l10n.deleteEnvelope,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => confirmDeleteEnvelope(context, envelope),
          ),
        ],
      ),
      onTap: () async {
        final edited = await showEnvelopeEditor(context, existing: envelope);
        if (edited != null && context.mounted) {
          final planner = context.read<PlannerState>();
          await attempt(context, () => planner.updateEnvelope(edited));
        }
      },
    );
  }
}

/// Asks before deleting an envelope — it takes its sub-envelopes, expenses
/// and allocations with it — and deletes it. Returns whether it is gone.
Future<bool> confirmDeleteEnvelope(
  BuildContext context,
  Envelope envelope,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final planner = context.read<PlannerState>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteEnvelope),
      content: Text(l10n.deleteEnvelopeConfirm(envelope.name)),
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
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final deleted = await attempt(
    context,
    () => planner.deleteEnvelope(envelope.id!),
  );
  if (deleted) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.envelopeDeleted)));
  }
  return deleted;
}
