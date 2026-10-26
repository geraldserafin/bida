import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/expense.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../categories/category_editor.dart';

String _amountText(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  return s.replaceAll('.', ',');
}

/// "Household · Period", what the top bar of a new entry says it goes into.
String entryTarget(PlannerState state, AppLocalizations l10n) {
  final household = state.household?.name ?? l10n.appTitle;
  final period = state.currentPeriod?.name;
  return period == null ? household : '$household · $period';
}

/// Amount-first entry for logging a real expense against an envelope, or
/// editing an existing one when [existing] is provided.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialEnvelopeId, this.existing});

  final String? initialEnvelopeId;
  final Expense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _envelopeId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _amountError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _envelopeId = e.envelopeId;
      _amountController.text = _amountText(e.amount);
      _date = e.date;
      _noteController.text = e.note ?? '';
    } else {
      _envelopeId = widget.initialEnvelopeId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_amount <= 0) {
      setState(() => _amountError = l10n.enterAmount);
      return;
    }
    if (_envelopeId == null) {
      setState(() {}); // surface the "pick an envelope" hint
      return;
    }

    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    final saved = await attempt(context, () {
      if (_isEdit) {
        return state.updateExpense(
          widget.existing!.copyWith(
            envelopeId: _envelopeId!,
            amount: _amount,
            date: _date,
            note: note,
          ),
        );
      }
      return state.addExpense(
        envelopeId: _envelopeId!,
        amount: _amount,
        date: _date,
        note: note,
      );
    });

    if (!mounted) return;
    if (saved) {
      // Return the envelope that was saved to, so callers can follow it.
      Navigator.of(context).pop(_envelopeId);
    } else {
      setState(() => _saving = false); // stay here so nothing typed is lost
    }
  }

  Future<void> _deleteExpense() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Text(
          l10n.deleteExpenseConfirm(formatZloty(widget.existing!.amount)),
        ),
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
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final deleted = await attempt(
      context,
      () => state.deleteExpense(widget.existing!.id!),
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(_envelopeId);
    } else {
      setState(() => _saving = false);
    }
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

  Future<void> _addNewCategory() async {
    final created = await showCategoryEditor(context);
    if (created == null || !mounted) return;
    final state = context.read<PlannerState>();
    String? envelopeId;
    await attempt(
      context,
      () async => envelopeId = await state.quickAddEnvelope(created),
    );
    if (mounted && envelopeId != null) {
      setState(() => _envelopeId = envelopeId);
    }
  }

  String _dateLabel(AppLocalizations l10n) {
    final now = DateTime.now();
    final isToday =
        _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final formatted = DateFormat('dd.MM.yyyy').format(_date);
    return isToday ? '${l10n.today}, $formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<PlannerState>();
    final progress = state.progress;
    CategoryProgress? selected;
    for (final p in progress) {
      if (p.envelope.id == _envelopeId) {
        selected = p;
        break;
      }
    }

    return Scaffold(
      appBar: FormTopBar(
        title: _isEdit ? l10n.editExpense : l10n.newExpense,
        where: _isEdit ? null : entryTarget(state, l10n),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.deleteExpense,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _deleteExpense,
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: AppButton(
          label: _isEdit ? l10n.saveChanges : l10n.saveExpense,
          busy: _saving,
          onPressed: _save,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          BigAmountField(
            label: l10n.amount,
            controller: _amountController,
            autofocus: !_isEdit,
            error: _amountError,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: 20),

          // ---- category ----
          FieldLabel(l10n.category),
          const SizedBox(height: 10),
          if (progress.isEmpty)
            Text(
              l10n.noEnvelopesForExpense,
              style: TextStyle(color: c.textMuted),
            )
          else
            ChipWrap(
              children: [
                for (final p in progress)
                  PillChip(
                    label: p.category.name,
                    selected: p.envelope.id == _envelopeId,
                    onTap: () => setState(() {
                      _envelopeId = p.envelope.id;
                      _amountError = null;
                    }),
                  ),
                PillChip(
                  label: '+ ${l10n.addNew}',
                  selected: false,
                  onTap: _addNewCategory,
                ),
              ],
            ),
          if (selected != null) ...[
            const SizedBox(height: 12),
            ValueRow(
              small: true,
              label: l10n.remainingInCategory(selected.category.name),
              value: formatZloty(selected.remaining),
              valueColor: selected.remaining < 0 ? c.danger : null,
            ),
          ],
          const SizedBox(height: 20),

          // ---- date ----
          ValueRow(
            label: l10n.date,
            value: _dateLabel(l10n),
            divided: true,
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),

          // ---- note ----
          LabeledField(
            label: l10n.descriptionOptional,
            controller: _noteController,
            hint: l10n.descriptionHint,
          ),
        ],
      ),
    );
  }
}
