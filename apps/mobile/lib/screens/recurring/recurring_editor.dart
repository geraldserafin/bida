import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/envelope.dart';
import '../../models/recurring_rule.dart';
import '../../util/amounts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/toggle_switch.dart';

/// Modal editor for creating or editing a [RecurringRule]. Returns the edited
/// rule, or null if dismissed. Persistence is left to the caller; [onDelete],
/// when given, is offered for an existing rule and closes the editor.
Future<RecurringRule?> showRecurringEditor(
  BuildContext context, {
  required List<Envelope> envelopes,
  RecurringRule? existing,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<RecurringRule>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecurringEditorSheet(
      envelopes: envelopes,
      existing: existing,
      onDelete: onDelete,
    ),
  );
}

class _RecurringEditorSheet extends StatefulWidget {
  const _RecurringEditorSheet({
    required this.envelopes,
    this.existing,
    this.onDelete,
  });

  final List<Envelope> envelopes;
  final RecurringRule? existing;
  final VoidCallback? onDelete;

  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _envelopeId;
  late bool _active;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountController = TextEditingController(
      text: e == null ? '' : amountText(e.amount),
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _envelopeId = e?.envelopeId ?? widget.envelopes.first.id!;
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _amountError = AppLocalizations.of(context).enterAmount);
      return;
    }
    Navigator.of(context).pop(
      RecurringRule(
        id: widget.existing?.id,
        envelopeId: _envelopeId,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        active: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final onDelete = widget.onDelete;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? l10n.newRule : l10n.editRule,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: l10n.name,
              controller: _noteController,
              hint: l10n.noteHint,
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: l10n.amount,
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffixText: 'zł',
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
            ),
            if (_amountError != null) ...[
              const SizedBox(height: 6),
              Text(
                _amountError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FieldLabel(l10n.envelope),
            const SizedBox(height: 10),
            ChipWrap(
              children: [
                for (final e in widget.envelopes)
                  PillChip(
                    label: e.isTopLevel ? e.name : '› ${e.name}',
                    selected: e.id == _envelopeId,
                    onTap: () => setState(() => _envelopeId = e.id!),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.active,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                ToggleSwitch(
                  value: _active,
                  semanticLabel: l10n.active,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (onDelete != null) ...[
                  Expanded(
                    child: AppButton(
                      label: l10n.delete,
                      kind: ButtonKind.secondary,
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDelete();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: AppButton(label: l10n.save, onPressed: _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
