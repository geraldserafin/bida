import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/income.dart';
import '../../state/planner_state.dart';
import '../../util/amounts.dart';
import '../../util/api_errors.dart';

/// Asks for an income — how much came in, when, and a note — and saves it.
/// Edits [existing] when given. Returns whether something was saved.
Future<bool> showIncomeSheet(BuildContext context, {Income? existing}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _IncomeSheet(existing: existing),
  );
  return saved ?? false;
}

class _IncomeSheet extends StatefulWidget {
  const _IncomeSheet({this.existing});
  final Income? existing;

  @override
  State<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<_IncomeSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amount = TextEditingController(
      text: e == null ? '' : amountText(e.amount),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.receivedOn ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.enterAmount);
      return;
    }
    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final saved = await attempt(
      context,
      () => state.saveIncome(
        Income(
          id: widget.existing?.id,
          amount: amount,
          receivedOn: DateTime(_date.year, _date.month, _date.day),
          note: note,
        ),
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? l10n.addIncome : l10n.editIncome,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
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
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                hintText: l10n.incomeNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(DateFormat.yMMMMd('pl').format(_date)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
