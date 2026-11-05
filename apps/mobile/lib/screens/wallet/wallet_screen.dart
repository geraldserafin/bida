import 'package:flutter/material.dart';
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
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/transaction_row.dart';

final _date = DateFormat('dd.MM.yyyy');

/// The private wallet (F31): what the user can still hand out to
/// households. Its history has the incomes, transfers and withdrawals (F10).
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    final wallet = state.wallet;
    return Scaffold(
      appBar: FormTopBar(title: l10n.wallet),
      floatingActionButton: AppButton(
        label: l10n.addIncome,
        height: 48,
        onPressed: () => showIncomeSheet(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          SurfaceCard(
            child: Column(
              children: [
                ValueRow(
                  label: l10n.walletBalance,
                  value: formatMinor(wallet.balanceMinor),
                  strong: true,
                  valueColor: wallet.negative ? c.danger : null,
                ),
                if (wallet.unconfirmedMinor > 0)
                  ValueRow(
                    small: true,
                    label: l10n.walletUnconfirmedLabel,
                    value: formatMinor(wallet.unconfirmedMinor),
                    valueColor: c.estimate,
                  ),
              ],
            ),
          ),
          if (wallet.negative) ...[
            const SizedBox(height: 8),
            Text(l10n.walletNegativeHint, style: TextStyle(color: c.danger)),
          ],
          const SizedBox(height: 16),
          RemoteData<List<WalletEntry>>(
            version: state.version,
            load: () => state.repository.walletEntries(),
            builder: (context, entries) => Column(
              children: [
                if (entries.isEmpty) Text(l10n.walletEmpty),
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TransactionRow(
                      color: e.isIn ? c.accent : c.textMuted,
                      title: _title(l10n, e),
                      details: _date.format(e.onDate),
                      amount:
                          '${e.isIn ? '+' : '−'}${formatMinor(e.amountMinor)}',
                      tone: e.estimated
                          ? AmountTone.estimate
                          : (e.isIn ? AmountTone.income : AmountTone.normal),
                      onTap: e.kind == WalletEntryKind.income
                          ? () => showIncomeSheet(context, existing: e)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations l10n, WalletEntry e) => switch (e.kind) {
    WalletEntryKind.income =>
      '${e.note ?? l10n.income}${e.estimated ? ' · ${l10n.estimated}' : ''}',
    WalletEntryKind.transfer => l10n.transferTo(e.householdName ?? ''),
    WalletEntryKind.withdrawal => l10n.withdrawalFrom(e.householdName ?? ''),
    WalletEntryKind.giveBack => l10n.returnedFrom(e.householdName ?? ''),
  };
}

/// Adds an income, or corrects (and deletes) one (F25).
Future<void> showIncomeSheet(BuildContext context, {WalletEntry? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _IncomeSheet(existing: existing),
    );

class _IncomeSheet extends StatefulWidget {
  const _IncomeSheet({this.existing});
  final WalletEntry? existing;

  @override
  State<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<_IncomeSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _onDate = DateTime.now();
  bool _estimated = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amount.text = amountText(e.amountMinor / 100);
      _note.text = e.note ?? '';
      _onDate = e.onDate;
      _estimated = e.estimated;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final minor = ((parseAmount(_amount.text) ?? 0) * 100).round();
    if (minor <= 0) return;
    setState(() => _saving = true);
    final state = context.read<BudgetState>();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final existing = widget.existing;
    final ok = existing == null
        ? await attemptMoney(
            context,
            () => state.repository.addIncome(
              amountMinor: minor,
              onDate: _onDate,
              note: note,
              estimated: _estimated,
            ),
          )
        : await sendWithCorrection(
            context,
            state.households,
            (correction) => state.repository.updateIncome(
              existing,
              amountMinor: minor,
              onDate: _onDate,
              note: note,
              estimated: _estimated,
              correction: correction,
            ),
          );
    if (!mounted) return;
    if (ok) {
      await state.refresh();
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final existing = widget.existing!;
    final yes = await confirmDanger(
      context,
      title: l10n.deleteIncome,
      body: l10n.deleteIncomeConfirm(formatMinor(existing.amountMinor)),
      action: l10n.delete,
    );
    if (!yes || !mounted) return;
    final ok = await sendWithCorrection(
      context,
      state.households,
      (correction) =>
          state.repository.removeIncome(existing.id, correction: correction),
    );
    if (!ok || !mounted) return;
    await state.refresh();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? l10n.addIncome : l10n.editIncome,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          BigAmountField(
            label: l10n.amount,
            controller: _amount,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          ValueRow(
            label: l10n.date,
            value: _date.format(_onDate),
            divided: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _onDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _onDate = picked);
            },
          ),
          const SizedBox(height: 12),
          LabeledField(label: l10n.descriptionOptional, controller: _note),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(l10n.estimatedIncome)),
              ToggleSwitch(
                value: _estimated,
                onChanged: (v) => setState(() => _estimated = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton(label: l10n.save, busy: _saving, onPressed: _save),
          if (widget.existing != null) ...[
            const SizedBox(height: 8),
            AppButton(
              label: l10n.deleteIncome,
              kind: ButtonKind.secondary,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
    );
  }
}
