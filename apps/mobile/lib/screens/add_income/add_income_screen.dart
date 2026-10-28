import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../util/amounts.dart';
import '../../util/api_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../add_expense/add_expense_screen.dart';

enum _IncomeKind { oneOff, recurring }

/// Money that came in ("Nowa wpłata"): an income on a day, or one that comes
/// every month on the same day (a salary). Either goes to the pool, from where
/// it is put into envelopes.
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  _IncomeKind _kind = _IncomeKind.oneOff;
  DateTime _date = DateTime.now();
  int _dayOfMonth = DateTime.now().day.clamp(1, 28);
  bool _saving = false;
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => parseAmount(_amountController.text) ?? 0;

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
    if (_amount <= 0) {
      setState(() => _amountError = l10n.enterAmount);
      return;
    }
    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();
    final saved = await attempt(
      context,
      () => switch (_kind) {
        _IncomeKind.oneOff => state.saveIncome(
          Income(
            amount: _amount,
            receivedOn: DateTime(_date.year, _date.month, _date.day),
            note: note,
          ),
        ),
        _IncomeKind.recurring => state.saveRecurringIncome(
          RecurringIncome(amount: _amount, dayOfMonth: _dayOfMonth, note: note),
        ),
      },
    );
    if (!mounted) return;
    if (saved) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _kind == _IncomeKind.oneOff
                ? l10n.incomeAdded
                : l10n.recurringIncomeAdded,
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: FormTopBar(title: l10n.newIncome, where: entryTarget(state)),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: AppButton(
          label: l10n.saveIncome,
          busy: _saving,
          onPressed: _save,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          SegmentedPills<_IncomeKind>(
            options: [
              (_IncomeKind.oneOff, l10n.oneOff),
              (_IncomeKind.recurring, l10n.recurringIncome),
            ],
            selected: _kind,
            onChanged: (kind) => setState(() => _kind = kind),
          ),
          const SizedBox(height: 20),
          BigAmountField(
            label: l10n.amount,
            controller: _amountController,
            color: c.accent,
            autofocus: true,
            error: _amountError,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            onChanged: (_) {
              if (_amountError != null) setState(() => _amountError = null);
            },
          ),
          const SizedBox(height: 20),
          if (_kind == _IncomeKind.oneOff)
            ValueRow(
              label: l10n.date,
              value: DateFormat('dd.MM.yyyy').format(_date),
              divided: true,
              onTap: _pickDate,
            )
          else ...[
            FieldLabel(l10n.dayOfMonth),
            const SizedBox(height: 10),
            ChipWrap(
              children: [
                for (var day = 1; day <= 28; day++)
                  PillChip(
                    label: '$day',
                    selected: day == _dayOfMonth,
                    onTap: () => setState(() => _dayOfMonth = day),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          LabeledField(
            label: l10n.descriptionOptional,
            controller: _noteController,
            hint: l10n.incomeNoteHint,
          ),
          const SizedBox(height: 20),
          Text(
            _kind == _IncomeKind.oneOff
                ? l10n.incomeGoesToPool
                : l10n.recurringIncomeHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
