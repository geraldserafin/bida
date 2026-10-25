import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/recurring_rule.dart';
import '../../theme/category_visuals.dart';

/// Modal editor for creating or editing a [RecurringRule]. Returns the edited
/// rule, or null if dismissed. Persistence is left to the caller.
Future<RecurringRule?> showRecurringEditor(
  BuildContext context, {
  required List<Category> categories,
  RecurringRule? existing,
}) {
  return showModalBottomSheet<RecurringRule>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _RecurringEditorSheet(categories: categories, existing: existing),
  );
}

class _RecurringEditorSheet extends StatefulWidget {
  const _RecurringEditorSheet({required this.categories, this.existing});

  final List<Category> categories;
  final RecurringRule? existing;

  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late int _categoryId;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountController = TextEditingController(
      text: e == null ? '' : e.amount.toString().replaceAll('.', ','),
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _categoryId = e?.categoryId ?? widget.categories.first.id!;
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    if (amount == null || amount <= 0) return;
    Navigator.of(context).pop(
      RecurringRule(
        id: widget.existing?.id,
        categoryId: _categoryId,
        amount: amount,
        frequency: widget.existing?.frequency ?? RecurrenceFrequency.monthly,
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

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? l10n.newRule : l10n.editRule,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final c in widget.categories)
                  DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(c.displayIcon, size: 18, color: c.displayColor),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: 'zł',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.note,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.active),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
