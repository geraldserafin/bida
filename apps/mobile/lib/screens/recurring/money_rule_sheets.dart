import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../util/amounts.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/toggle_switch.dart';

/// Edits a recurring income, or makes a new one. Returns it, or null when
/// dismissed. Persistence is left to the caller; [onDelete], when given, is
/// offered for an existing rule and closes the sheet.
Future<RecurringIncome?> showRecurringIncomeSheet(
  BuildContext context, {
  RecurringIncome? existing,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<RecurringIncome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RuleSheet(
      incomeRule: true,
      onDelete: onDelete,
      initial: existing == null
          ? null
          : _Values(
              id: existing.id,
              amount: existing.amount,
              day: existing.dayOfMonth,
              note: existing.note,
              active: existing.active,
            ),
    ),
  );
}

/// Edits an allocation rule, or makes a new one. Returns it, or null when
/// dismissed. Persistence is left to the caller; [onDelete] as above.
Future<AllocationRule?> showAllocationRuleSheet(
  BuildContext context, {
  required List<Envelope> envelopes,
  AllocationRule? existing,
  VoidCallback? onDelete,
}) {
  return showModalBottomSheet<AllocationRule>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RuleSheet(
      incomeRule: false,
      envelopes: envelopes,
      onDelete: onDelete,
      initial: existing == null
          ? null
          : _Values(
              id: existing.id,
              envelopeId: existing.envelopeId,
              amount: existing.amount,
              day: existing.dayOfMonth,
              note: existing.note,
              active: existing.active,
            ),
    ),
  );
}

class _Values {
  const _Values({
    this.id,
    this.envelopeId,
    required this.amount,
    required this.day,
    this.note,
    required this.active,
  });

  final String? id;
  final String? envelopeId;
  final double amount;
  final int day;
  final String? note;
  final bool active;
}

/// One sheet for both kinds: they differ only in having an envelope or not.
class _RuleSheet extends StatefulWidget {
  const _RuleSheet({
    required this.incomeRule,
    this.envelopes = const [],
    this.initial,
    this.onDelete,
  });

  final bool incomeRule;
  final List<Envelope> envelopes;
  final _Values? initial;
  final VoidCallback? onDelete;

  @override
  State<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<_RuleSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late String? _envelopeId;
  late int _day;
  late bool _active;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = widget.initial;
    _amount = TextEditingController(
      text: v == null ? '' : amountText(v.amount),
    );
    _note = TextEditingController(text: v?.note ?? '');
    _envelopeId = v?.envelopeId ?? widget.envelopes.firstOrNull?.id;
    _day = v?.day ?? 1;
    _active = v?.active ?? true;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.enterAmount);
      return;
    }
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final id = widget.initial?.id;
    if (widget.incomeRule) {
      Navigator.of(context).pop(
        RecurringIncome(
          id: id,
          amount: amount,
          dayOfMonth: _day,
          note: note,
          active: _active,
        ),
      );
    } else {
      Navigator.of(context).pop(
        AllocationRule(
          id: id,
          envelopeId: _envelopeId!,
          amount: amount,
          dayOfMonth: _day,
          note: note,
          active: _active,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isNew = widget.initial == null;
    final onDelete = widget.onDelete;
    final title = widget.incomeRule
        ? (isNew ? l10n.newIncomeRule : l10n.editIncomeRule)
        : (isNew ? l10n.newAllocationRule : l10n.editAllocationRule);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            LabeledField(
              label: l10n.amount,
              controller: _amount,
              autofocus: isNew,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              suffixText: 'zł',
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (!widget.incomeRule) ...[
              const SizedBox(height: 18),
              FieldLabel(l10n.envelope),
              const SizedBox(height: 10),
              ChipWrap(
                children: [
                  for (final e in widget.envelopes)
                    PillChip(
                      label: e.isTopLevel ? e.name : '› ${e.name}',
                      selected: e.id == _envelopeId,
                      onTap: () => setState(() => _envelopeId = e.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            FieldLabel(l10n.dayOfMonth),
            const SizedBox(height: 10),
            ChipWrap(
              children: [
                for (var d = 1; d <= 28; d++)
                  PillChip(
                    label: '$d',
                    selected: d == _day,
                    onTap: () => setState(() => _day = d),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            LabeledField(
              label: l10n.noteOptional,
              controller: _note,
              hint: widget.incomeRule ? l10n.incomeNoteHint : null,
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
