import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/amounts.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../util/month_label.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/transaction_row.dart';
import '../envelopes/envelope_editor.dart';
import '../recurring/recurring_rules_screen.dart';

const _steps = 5;

double _parseAmount(String raw) =>
    parseAmount(raw.replaceAll(RegExp(r'\s'), '')) ?? 0;

/// An envelope the wizard offers to add at the start.
class _Starter {
  const _Starter(this.name, this.color, this.icon);
  final String name;
  final String color;
  final String icon;
}

/// Money coming in this month, typed in step 3: once, or every month.
class _Income {
  const _Income(this.name, this.amount, {required this.monthly});
  final String name;
  final double amount;
  final bool monthly;
}

/// What the active recurring expenses take from each envelope in a month.
Map<String, double> _billsByEnvelope(List<RecurringRule> rules) {
  final sums = <String, double>{};
  for (final rule in rules) {
    if (!rule.active) continue;
    sums.update(
      rule.envelopeId,
      (v) => v + rule.amount,
      ifAbsent: () => rule.amount,
    );
  }
  return sums;
}

/// First run ("Kreator"): the envelopes to start with, who shares them, the
/// income, the recurring bills, and what goes into each envelope. Finishing
/// records the income and puts the money into the envelopes, once or as
/// rules that repeat every month.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;
  bool _busy = false;

  // step 1
  final Set<int> _skippedStarters = {};

  // step 2
  bool _multi = false;
  String? _inviteEnvelopeId;
  final _inviteController = TextEditingController();
  final Set<String> _invited = {};

  // step 3
  final List<_Income> _incomes = [];
  final _incomeNameController = TextEditingController();
  final _incomeAmountController = TextEditingController();
  bool _incomeMonthly = true;

  // step 5
  final Map<String, TextEditingController> _planned = {};
  bool _repeatMonthly = true;
  String? _incomeError;

  @override
  void dispose() {
    _inviteController.dispose();
    _incomeNameController.dispose();
    _incomeAmountController.dispose();
    for (final c in _planned.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_Starter> _starters(AppLocalizations l10n) => [
    _Starter(l10n.starterFood, '#F97316', 'restaurant'),
    _Starter(l10n.starterHousing, '#F59E0B', 'home'),
    _Starter(l10n.starterTransport, '#60A5FA', 'directions_bus'),
    _Starter(l10n.starterHealth, '#F472B6', 'health'),
    _Starter(l10n.starterFun, '#A78BFA', 'celebration'),
    _Starter(l10n.starterClothes, '#22C55E', 'shopping_cart'),
    _Starter(l10n.starterOther, '#14B8A6', 'wallet'),
  ];

  double get _income => _incomes.fold(0, (sum, i) => sum + i.amount);

  double get _allocated =>
      _planned.values.fold(0, (sum, c) => sum + _parseAmount(c.text));

  void _go(int step) => setState(() => _step = step);

  // ---- step actions ---------------------------------------------------------

  /// Step 1: adds the starting envelopes that are not there yet.
  Future<void> _saveStarters() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final existing = {for (final e in state.envelopes) e.name.toLowerCase()};
    final starters = _starters(l10n);
    setState(() => _busy = true);
    final saved = await attempt(context, () async {
      for (final (i, s) in starters.indexed) {
        if (_skippedStarters.contains(i)) continue;
        if (existing.contains(s.name.toLowerCase())) continue;
        await state.addEnvelope(
          Envelope(name: s.name, color: s.color, icon: s.icon),
        );
      }
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) _go(1);
  }

  void _addIncome() {
    final amount = _parseAmount(_incomeAmountController.text);
    if (amount <= 0) return;
    final name = _incomeNameController.text.trim();
    setState(() {
      _incomes.add(
        _Income(
          name.isEmpty ? AppLocalizations.of(context).newIncome : name,
          amount,
          monthly: _incomeMonthly,
        ),
      );
      _incomeNameController.clear();
      _incomeAmountController.clear();
      _incomeError = null;
    });
  }

  /// Step 2: invites somebody to share the chosen envelope.
  Future<void> _invite(String? envelopeId) async {
    final l10n = AppLocalizations.of(context);
    final email = _inviteController.text.trim();
    if (email.isEmpty || envelopeId == null) return;
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);
    final sent = await attempt(
      context,
      () => state.invite(envelopeId, email: email, role: EnvelopeRole.member),
    );
    if (!sent || !mounted) return;
    setState(() {
      _invited.add(email);
      _inviteController.clear();
    });
    messenger.showSnackBar(SnackBar(content: Text(l10n.invitationSent(email))));
  }

  /// Step 5 starts from what the recurring bills already need.
  void _openEnvelopes() {
    final suggested = _billsByEnvelope(
      context.read<PlannerState>().recurringRules,
    );
    suggested.forEach((envelopeId, amount) {
      final controller = _planned.putIfAbsent(
        envelopeId,
        TextEditingController.new,
      );
      if (controller.text.isEmpty) controller.text = formatPlain(amount);
    });
    _go(4);
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context);
    if (_income <= 0) {
      setState(() => _incomeError = l10n.enterIncome);
      _go(2);
      return;
    }
    final state = context.read<PlannerState>();
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = now.day.clamp(1, 28);
    final amounts = {
      for (final e in _planned.entries)
        if (_parseAmount(e.value.text) > 0) e.key: _parseAmount(e.value.text),
    };
    setState(() => _busy = true);
    // The money comes in first, then goes into the envelopes. What repeats
    // becomes a rule, and applying the rules adds this month's share of it
    // (with the recurring bills).
    final done = await attempt(context, () async {
      for (final income in _incomes) {
        if (income.monthly) {
          await state.saveRecurringIncome(
            RecurringIncome(
              amount: income.amount,
              dayOfMonth: day,
              note: income.name,
            ),
          );
        } else {
          await state.saveIncome(
            Income(amount: income.amount, receivedOn: today, note: income.name),
          );
        }
      }
      for (final envelope in state.topLevel) {
        final amount = amounts[envelope.id];
        if (amount == null) continue;
        if (_repeatMonthly) {
          await state.saveAllocationRule(
            AllocationRule(
              envelopeId: envelope.id!,
              amount: amount,
              dayOfMonth: day,
            ),
          );
        } else {
          await state.saveAllocation(
            Allocation(envelopeId: envelope.id!, amount: amount, madeOn: today),
          );
        }
      }
      final madeRules =
          _incomes.any((i) => i.monthly) ||
          (_repeatMonthly && amounts.isNotEmpty);
      if (madeRules) await state.applyRecurringToMonth();
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (done) navigator.pop();
  }

  Future<void> _addEnvelope() async {
    final created = await showEnvelopeEditor(context);
    if (created != null && mounted) {
      final state = context.read<PlannerState>();
      await attempt(context, () => state.addEnvelope(created));
    }
  }

  // ---- layout ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (
      Widget content,
      String action,
      VoidCallback onAction,
    ) = switch (_step) {
      0 => (_startersStep(context), l10n.next, _saveStarters),
      1 => (_whoStep(context), l10n.next, () => _go(2)),
      2 => (_incomeStep(context), l10n.next, () => _go(3)),
      3 => (_billsStep(context), l10n.next, _openEnvelopes),
      _ => (_envelopesStep(context), l10n.wizardDone, _finish),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(context),
                const SizedBox(height: 22),
                _StepBar(step: _step),
                const SizedBox(height: 22),
                Expanded(child: SingleChildScrollView(child: content)),
                const SizedBox(height: 16),
                AppButton(label: action, busy: _busy, onPressed: onAction),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    void later() {
      switch (_step) {
        case 3:
          _openEnvelopes();
        case 4:
          Navigator.of(context).pop();
        default:
          _go(_step + 1);
      }
    }

    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            l10n.stepOf(_step + 1, _steps),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          if (_step > 0) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-11, 0),
                child: AppIconButton(
                  AppIcon.back,
                  tooltip: l10n.back,
                  onPressed: _busy ? null : () => _go(_step - 1),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _busy ? null : later,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    l10n.later,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The question of the step, with an explanation under it.
  Widget _heading(BuildContext context, String title, [String? body]) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.of(context).textMuted,
            ),
          ),
        ],
      ],
    );
  }

  // ---- step 1: the envelopes to start with --------------------------------

  Widget _startersStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final starters = _starters(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardStartersTitle, l10n.wizardStartersBody),
        const SizedBox(height: 22),
        // the only currency there is for now
        FieldLabel(l10n.currency),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.of(context).borderStrong),
          ),
          child: Text(l10n.currencyPln, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 22),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(l10n.starterEnvelopes),
              const SizedBox(height: 12),
              ChipWrap(
                children: [
                  for (final (i, s) in starters.indexed)
                    Opacity(
                      opacity: _skippedStarters.contains(i) ? 0.4 : 1,
                      child: PillChip(
                        label: s.name,
                        selected: false,
                        onTap: () => setState(() {
                          if (!_skippedStarters.remove(i)) {
                            _skippedStarters.add(i);
                          }
                        }),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- step 2: who uses it ---------------------------------------------------

  Widget _whoStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top = context.watch<PlannerState>().topLevel;
    final inviteTo = _inviteEnvelopeId ?? top.firstOrNull?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardWhoTitle),
        const SizedBox(height: 22),
        _ChoiceCard(
          title: l10n.soloTitle,
          body: l10n.soloBody,
          selected: !_multi,
          onTap: () => setState(() => _multi = false),
        ),
        const SizedBox(height: 22),
        _ChoiceCard(
          title: l10n.multiTitle,
          body: l10n.multiBody,
          selected: _multi,
          onTap: () => setState(() => _multi = true),
        ),
        if (_multi && top.isNotEmpty) ...[
          const SizedBox(height: 22),
          FieldLabel(l10n.shareWhichEnvelope),
          const SizedBox(height: 10),
          ChipWrap(
            children: [
              for (final e in top)
                PillChip(
                  label: e.name,
                  selected: e.id == inviteTo,
                  onTap: () => setState(() => _inviteEnvelopeId = e.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LabeledField(
                  label: l10n.inviteByEmail,
                  hint: l10n.inviteHint,
                  controller: _inviteController,
                  keyboardType: TextInputType.emailAddress,
                  onSubmitted: (_) => _invite(inviteTo),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: l10n.send,
                kind: ButtonKind.tonal,
                onPressed: () => _invite(inviteTo),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _invited.isEmpty
                ? l10n.sharingPerEnvelope
                : l10n.invitedPeople(_invited.join(', ')),
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.of(context).textMuted,
            ),
          ),
        ],
      ],
    );
  }

  // ---- step 3: income -----------------------------------------------------

  Widget _incomeStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          context,
          l10n.wizardIncomeTitle,
          l10n.wizardIncomeBody(monthLabel(context.read<PlannerState>().month)),
        ),
        const SizedBox(height: 14),
        for (final (i, income) in _incomes.indexed) ...[
          Dismissible(
            key: ObjectKey(income),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => setState(() => _incomes.removeAt(i)),
            child: TransactionRow(
              color: AppColors.of(context).accent,
              title: income.name,
              details: income.monthly
                  ? l10n.everyMonth.toLowerCase()
                  : l10n.oneOff.toLowerCase(),
              amount: formatZloty(income.amount),
              tone: AmountTone.income,
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        SurfaceCard(
          outline: CardOutline.bare,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(l10n.newIncome),
              const SizedBox(height: 12),
              SegmentedPills<bool>(
                options: [(true, l10n.everyMonth), (false, l10n.oneOff)],
                selected: _incomeMonthly,
                onChanged: (v) => setState(() => _incomeMonthly = v),
                radius: 12,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LabeledField(
                      label: l10n.name,
                      controller: _incomeNameController,
                      hint: l10n.incomeNameHint,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: LabeledField(
                      label: l10n.amount,
                      controller: _incomeAmountController,
                      hint: '0,00 zł',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onSubmitted: (_) => _addIncome(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(
                label: l10n.addIncomeAction,
                kind: ButtonKind.tonal,
                onPressed: _addIncome,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ValueRow(
          label: l10n.monthIncome,
          value: formatZloty(_income),
          strong: true,
        ),
        if (_incomeError != null) _ErrorText(_incomeError!),
      ],
    );
  }

  // ---- step 4: recurring bills ---------------------------------------------

  Widget _billsStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardBillsTitle, l10n.wizardBillsBody),
        const SizedBox(height: 20),
        for (final rule in state.recurringRules) ...[
          TransactionRow(
            color:
                state.envelopeById(rule.envelopeId)?.displayColor ??
                AppColors.of(context).textMuted,
            title: rule.note?.isNotEmpty == true
                ? rule.note!
                : state.envelopeById(rule.envelopeId)?.name ?? '—',
            details: [
              ?state.envelopeById(rule.envelopeId)?.name,
              l10n.everyMonth,
            ].join(' · '),
            amount: formatZloty(rule.amount),
            onTap: () => editRecurringRule(context, state, existing: rule),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        AppButton(
          label: l10n.addRecurringExpense,
          kind: ButtonKind.dashed,
          onPressed: () => editRecurringRule(context, state),
        ),
      ],
    );
  }

  // ---- step 5: envelopes ----------------------------------------------------

  Widget _envelopesStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<PlannerState>();
    final fromRecurring = _billsByEnvelope(state.recurringRules);
    final unallocated = _income - _allocated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardEnvelopesTitle, l10n.wizardEnvelopesBody),
        const SizedBox(height: 18),
        SurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final envelope in state.topLevel)
                _EnvelopeInput(
                  envelope: envelope,
                  note: fromRecurring[envelope.id] == null
                      ? null
                      : l10n.fromRecurring(
                          formatZloty(fromRecurring[envelope.id]!),
                        ),
                  controller: _planned.putIfAbsent(
                    envelope.id!,
                    TextEditingController.new,
                  ),
                  onChanged: () => setState(() {}),
                ),
              InkWell(
                onTap: _addEnvelope,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.addEnvelopePlus,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.repeatMonthly,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    l10n.repeatMonthlyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ToggleSwitch(
              value: _repeatMonthly,
              semanticLabel: l10n.repeatMonthly,
              onChanged: (v) => setState(() => _repeatMonthly = v),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ValueRow(small: true, label: l10n.income, value: formatZloty(_income)),
        const SizedBox(height: 6),
        ValueRow(
          small: true,
          label: l10n.allocated,
          value: formatZloty(_allocated),
        ),
        const SizedBox(height: 6),
        ValueRow(
          strong: true,
          label: unallocated < 0 ? l10n.overAllocated : l10n.unallocatedShort,
          value: formatZloty(unallocated),
          valueColor: unallocated < 0 ? c.danger : c.accent,
        ),
      ],
    );
  }
}

/// The five-part progress bar under the top bar ("Pasek kroków").
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < _steps; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? c.accent : c.surface2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One of the answers of step 2, outlined green when chosen.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      radius: 18,
      outline: selected ? CardOutline.selected : CardOutline.normal,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.of(context).textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// An envelope with the amount to put into it, one row of step 5.
class _EnvelopeInput extends StatelessWidget {
  const _EnvelopeInput({
    required this.envelope,
    required this.note,
    required this.controller,
    required this.onChanged,
  });

  final Envelope envelope;

  /// What recurring bills already need from it, when they need anything.
  final String? note;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final note = this.note;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c.borderStrong),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          CategoryDot(envelope.displayColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  envelope.name,
                  style: TextStyle(fontSize: 15, height: 1.5, color: c.text),
                ),
                if (note != null)
                  Text(note, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            height: 40,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
              ],
              onChanged: (_) => onChanged(),
              style: TextStyle(fontSize: 15, color: c.text),
              decoration: InputDecoration(
                hintText: '0,00',
                fillColor: c.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: BorderSide(color: c.accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: TextStyle(color: AppColors.of(context).danger, fontSize: 12),
    ),
  );
}
