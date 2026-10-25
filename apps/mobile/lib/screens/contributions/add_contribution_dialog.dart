import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

typedef ContributionInput = ({double amount, String? note, bool external});

/// Asks for the amount (and a note). Null when dismissed.
Future<ContributionInput?> showAddContributionDialog(BuildContext context) {
  return showDialog<ContributionInput>(
    context: context,
    builder: (_) => const _AddContributionDialog(),
  );
}

class _AddContributionDialog extends StatefulWidget {
  const _AddContributionDialog();

  @override
  State<_AddContributionDialog> createState() => _AddContributionDialogState();
}

class _AddContributionDialogState extends State<_AddContributionDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _external = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _note.text.trim();
    Navigator.of(context).pop((
      amount: _parse(_amount.text),
      note: note.isEmpty ? null : note,
      external: _external,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addContribution),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: 'zł',
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  _parse(value ?? '') > 0 ? null : l10n.enterAmount,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.externalMoney),
              value: _external,
              onChanged: (value) => setState(() => _external = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
