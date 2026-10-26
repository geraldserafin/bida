import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../util/api_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/screen_header.dart';
import '../add_expense/add_expense_screen.dart';

enum _IncomeKind { oneOff, recurring }

/// Money that came in ("Nowa wpłata"): adds to the current period's income.
///
/// Recurring income has no place on the server yet, so that choice is shown
/// but cannot be made.
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountController = TextEditingController();
  bool _saving = false;
  String? _amountError;

  @override
  void dispose() {
    _amountController.dispose();
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
    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await attempt(context, () => state.addIncome(_amount));
    if (!mounted) return;
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.incomeAdded)));
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
    final period = state.currentPeriod?.name ?? '';

    return Scaffold(
      appBar: FormTopBar(
        title: l10n.newIncome,
        where: entryTarget(state, l10n),
      ),
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
            selected: _IncomeKind.oneOff,
            onChanged: (kind) {
              if (kind == _IncomeKind.recurring) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.recurringIncomeSoon)),
                );
              }
            },
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
          Text(
            l10n.incomeGoesTo(period),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
