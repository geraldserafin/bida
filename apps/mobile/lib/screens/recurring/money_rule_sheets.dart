import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/amounts.dart';

/// Edits a recurring income, or makes a new one. Returns it, or null when
/// dismissed. Persistence is left to the caller.
Future<RecurringIncome?> showRecurringIncomeSheet(
  BuildContext context, {
  RecurringIncome? existing,
}) {
  return showModalBottomSheet<RecurringIncome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RuleSheet(
      incomeRule: true,
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
/// dismissed. Persistence is left to the caller.
Future<AllocationRule?> showAllocationRuleSheet(
  BuildContext context, {
  required List<Envelope> envelopes,
  AllocationRule? existing,
}) {
  return showModalBottomSheet<AllocationRule>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RuleSheet(
      incomeRule: false,
      envelopes: envelopes,
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
  });

  final bool incomeRule;
  final List<Envelope> envelopes;
  final _Values? initial;

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
    final title = widget.incomeRule
        ? (isNew ? l10n.newIncomeRule : l10n.editIncomeRule)
        : (isNew ? l10n.newAllocationRule : l10n.editAllocationRule);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (!widget.incomeRule) ...[
              DropdownButtonFormField<String>(
                initialValue: _envelopeId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.envelope,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final e in widget.envelopes)
                    DropdownMenuItem(
                      value: e.id,
                      child: Row(
                        children: [
                          Icon(e.displayIcon, size: 18, color: e.displayColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              e.isTopLevel ? e.name : '› ${e.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _envelopeId = v),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _amount,
              autofocus: isNew,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: 'zł',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _day,
              decoration: InputDecoration(
                labelText: l10n.dayOfMonth,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (var d = 1; d <= 28; d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (v) => setState(() => _day = v ?? _day),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.active),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
