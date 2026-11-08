import 'package:flutter/material.dart';
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
import 'cycle_picker.dart';

/// The default envelopes (F11), offered in the wizard.
const defaultEnvelopes = [
  'Jedzenie',
  'Mieszkanie i rachunki',
  'Transport',
  'Zdrowie',
  'Rozrywka',
  'Ubrania',
  'Inne',
];

enum _Step { household, envelopes, income, transfer, done }

/// The first start (F30): a household ("Dom", monthly from the 1st) with its
/// envelopes, the first income into the wallet and the first transfer into
/// the household. Every step after the first can be left for later.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  _Step _step = _Step.household;
  final _name = TextEditingController(text: 'Dom');
  final _income = TextEditingController();
  final _transfer = TextEditingController();
  Cycle _cycle = const Cycle.monthly();
  DateTime? _manualEnd;
  final Set<String> _envelopes = {...defaultEnvelopes};
  bool _busy = false;
  Household? _household;

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    _transfer.dispose();
    super.dispose();
  }

  int _minor(TextEditingController c) =>
      ((parseAmount(c.text) ?? 0) * 100).round();

  Future<void> _next() async {
    final state = context.read<BudgetState>();
    setState(() => _busy = true);
    var ok = true;
    switch (_step) {
      case _Step.household:
        if (_name.text.trim().isEmpty) ok = false;
      case _Step.envelopes:
        // the household is made here, with the cycle and the envelopes
        ok = await attemptMoney(context, () async {
          _household = await state.createHousehold(
            name: _name.text.trim(),
            cycle: _cycle,
            firstEndsOn: _cycle.kind == CycleKind.manual
                ? (_manualEnd ?? DateTime.now().add(const Duration(days: 30)))
                : null,
            envelopes: [
              for (final e in defaultEnvelopes)
                if (_envelopes.contains(e)) e,
            ],
          );
        });
      case _Step.income:
        final minor = _minor(_income);
        if (minor > 0) {
          ok = await attemptMoney(context, () async {
            await state.repository.addIncome(
              amountMinor: minor,
              onDate: DateTime.now(),
            );
            await state.refresh();
          });
          if (ok) _transfer.text = _income.text;
        }
      case _Step.transfer:
        final minor = _minor(_transfer);
        final h = _household;
        if (minor > 0 && h != null) {
          ok = await attemptMoney(
            context,
            () => state.change((repo) => repo.transfer(h.current.id, minor)),
          );
        }
      case _Step.done:
        if (mounted) Navigator.of(context).pop();
        return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _step = _Step.values[_step.index + 1];
    });
  }

  void _later() => setState(() => _step = _Step.values[_step.index + 1]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final skippable = _step == _Step.income || _step == _Step.transfer;
    return Scaffold(
      appBar: FormTopBar(
        title: l10n.wizardTitle,
        where: l10n.wizardStep(_step.index + 1, _Step.values.length),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Row(
          children: [
            if (skippable) ...[
              Expanded(
                child: AppButton(
                  label: l10n.later,
                  kind: ButtonKind.secondary,
                  onPressed: _busy ? null : _later,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: AppButton(
                label: _step == _Step.done ? l10n.wizardFinish : l10n.next,
                busy: _busy,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: switch (_step) {
          _Step.household => [
            Text(
              l10n.wizardHouseholdTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wizardHouseholdBody,
              style: TextStyle(color: c.textMuted),
            ),
            const SizedBox(height: 20),
            LabeledField(label: l10n.name, controller: _name),
            const SizedBox(height: 20),
            FieldLabel(l10n.cycle),
            const SizedBox(height: 10),
            CycleEditor(
              cycle: _cycle,
              onChanged: (c) => setState(() => _cycle = c),
            ),
            if (_cycle.kind == CycleKind.manual)
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now.add(const Duration(days: 30)),
                    firstDate: now,
                    lastDate: DateTime(now.year + 2),
                  );
                  if (picked != null) setState(() => _manualEnd = picked);
                },
                child: Text(l10n.firstPeriodEnd),
              ),
          ],
          _Step.envelopes => [
            Text(
              l10n.wizardEnvelopesTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wizardEnvelopesBody,
              style: TextStyle(color: c.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.wizardEnvelopesChosen(_envelopes.length),
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ChipWrap(
              children: [
                for (final e in defaultEnvelopes)
                  PillChip(
                    label: e,
                    check: true,
                    selected: _envelopes.contains(e),
                    onTap: () => setState(() {
                      // at least one stays
                      if (_envelopes.contains(e) && _envelopes.length > 1) {
                        _envelopes.remove(e);
                      } else {
                        _envelopes.add(e);
                      }
                    }),
                  ),
              ],
            ),
          ],
          _Step.income => [
            Text(l10n.wizardIncomeTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.wizardIncomeBody, style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 20),
            BigAmountField(
              label: l10n.amount,
              controller: _income,
              autofocus: true,
            ),
          ],
          _Step.transfer => [
            Text(
              l10n.wizardTransferTitle,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.wizardTransferBody(
                formatMinor(context.watch<BudgetState>().wallet.balanceMinor),
              ),
              style: TextStyle(color: c.textMuted),
            ),
            const SizedBox(height: 20),
            BigAmountField(
              label: l10n.amount,
              controller: _transfer,
              autofocus: true,
            ),
          ],
          _Step.done => [
            Icon(Icons.check_circle_outline, size: 56, color: c.accent),
            const SizedBox(height: 16),
            Text(l10n.wizardDoneTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.wizardDoneBody, style: TextStyle(color: c.textMuted)),
          ],
        },
      ),
    );
  }
}
