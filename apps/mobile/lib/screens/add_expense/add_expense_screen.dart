import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../util/amounts.dart';
import '../../util/money_format.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';

/// Amount-first entry of an expense in the current period of the household
/// on screen (F08), or editing one when [existing] is given (F09). When it
/// does not fit the plan or the balance, the steps of F08 ask what to do.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialEnvelopeId, this.existing});

  final String? initialEnvelopeId;
  final Expense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  String? _envelopeId;
  DateTime _spentAt = DateTime.now();
  ForWhom? _forWhom;
  String? _forWhomUserId;
  bool _saving = false;
  String? _amountError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _envelopeId = e.envelopeId;
      _amountController.text = amountText(e.amountMinor / 100);
      _spentAt = e.spentAt;
      _titleController.text = e.title ?? '';
      _forWhom = e.forWhom;
      _forWhomUserId = e.forWhomUserId;
    } else {
      _envelopeId = widget.initialEnvelopeId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  int get _amountMinor =>
      ((parseAmount(_amountController.text) ?? 0) * 100).round();

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final household = state.household;
    if (_amountMinor <= 0) {
      setState(() => _amountError = l10n.enterAmount);
      return;
    }
    if (_envelopeId == null || household == null) {
      setState(() {}); // surface the "pick an envelope" hint
      return;
    }
    setState(() => _saving = true);
    final title = _titleController.text.trim();
    final draft = ExpenseDraft(
      envelopeId: _envelopeId!,
      amountMinor: _amountMinor,
      spentAt: _spentAt,
      title: title.isEmpty ? null : title,
      forWhom: _forWhom,
      forWhomUserId: _forWhom == ForWhom.member ? _forWhomUserId : null,
    );
    final outcome = await sendWithSteps(
      context,
      draft.amountMinor,
      (decision) => _isEdit
          ? state.repository.updateExpense(
              widget.existing!.id,
              draft,
              decision: decision,
            )
          : state.repository.addExpense(
              household.id,
              draft,
              decision: decision,
            ),
    );
    if (!mounted) return;
    if (outcome == null) {
      setState(() => _saving = false); // stay here so nothing typed is lost
      return;
    }
    await state.refresh();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (outcome.raisedPlanMinor > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.planRaised(formatMinor(outcome.raisedPlanMinor))),
        ),
      );
    } else if (outcome.plansExceedBalance) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.plansExceedBalance)));
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDanger(
      context,
      title: l10n.deleteExpense,
      body: l10n.deleteExpenseConfirm(
        formatMinor(widget.existing!.amountMinor),
      ),
      action: l10n.delete,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    final state = context.read<BudgetState>();
    final deleted = await attemptMoney(
      context,
      () => state.change((repo) => repo.deleteExpense(widget.existing!.id)),
    );
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(Period period) async {
    final now = DateTime.now();
    final last = period.endsOn.isBefore(now) ? period.endsOn : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt.isAfter(last) ? last : _spentAt,
      firstDate: period.startsOn,
      lastDate: last,
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_spentAt),
    );
    var at = DateTime(
      picked.year,
      picked.month,
      picked.day,
      time?.hour ?? _spentAt.hour,
      time?.minute ?? _spentAt.minute,
    );
    // an expense is never dated in the future
    if (at.isAfter(now)) at = now;
    setState(() => _spentAt = at);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    final envelopes = state.activeEnvelopes;
    final figures = state.summary?.envelopes
        .where((e) => e.envelopeId == _envelopeId)
        .firstOrNull;
    final period = household?.current;
    final others = state.members;

    return Scaffold(
      appBar: FormTopBar(
        title: _isEdit ? l10n.editExpense : l10n.newExpense,
        where: household?.name,
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l10n.deleteExpense,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
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
          onPressed: household == null || household.frozen ? null : _save,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          if (household?.frozen == true) ...[
            Text(l10n.errMemberFrozen, style: TextStyle(color: c.danger)),
            const SizedBox(height: 12),
          ],
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
          FieldLabel(l10n.envelope),
          const SizedBox(height: 10),
          if (envelopes.isEmpty)
            Text(
              l10n.noEnvelopesForExpense,
              style: TextStyle(color: c.textMuted),
            )
          else
            ChipWrap(
              children: [
                for (final e in envelopes)
                  PillChip(
                    label: e.name,
                    selected: e.id == _envelopeId,
                    onTap: () => setState(() => _envelopeId = e.id),
                  ),
              ],
            ),
          if (figures != null) ...[
            const SizedBox(height: 12),
            ValueRow(
              small: true,
              label: l10n.leftInPlan(figures.name),
              value: formatMinor(figures.leftMinor),
              valueColor: figures.leftMinor < 0 ? c.danger : null,
            ),
          ],
          const SizedBox(height: 20),
          if (period != null)
            ValueRow(
              label: l10n.dateAndTime,
              value: DateFormat('dd.MM.yyyy, HH:mm').format(_spentAt),
              divided: true,
              onTap: () => _pickDate(period),
            ),
          const SizedBox(height: 20),
          LabeledField(
            label: l10n.titleOptional,
            controller: _titleController,
            hint: l10n.descriptionHint,
          ),
          // F28: hidden while the household has one member
          if (others.length > 1) ...[
            const SizedBox(height: 20),
            FieldLabel(l10n.forWhom),
            const SizedBox(height: 10),
            ChipWrap(
              children: [
                PillChip(
                  label: l10n.forWhomNobody,
                  selected: _forWhom == null,
                  onTap: () => setState(() => _forWhom = null),
                ),
                PillChip(
                  label: l10n.forWhomShared,
                  selected: _forWhom == ForWhom.shared,
                  onTap: () => setState(() => _forWhom = ForWhom.shared),
                ),
                for (final m in others)
                  PillChip(
                    label: m.displayName,
                    selected:
                        _forWhom == ForWhom.member &&
                        _forWhomUserId == m.userId,
                    onTap: () => setState(() {
                      _forWhom = ForWhom.member;
                      _forWhomUserId = m.userId;
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
