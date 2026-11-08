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
import '../../widgets/fab_bar.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/toggle_switch.dart';

/// The recurring rules (F25-F27): incomes into the wallet, transfers into
/// households, expenses of households. They run on their own at the app
/// start; "Zastosuj" applies the next one early.
class RecurringRulesScreen extends StatelessWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RemoteData<List<RecurringRule>>(
          version: state.version,
          load: () => state.repository.recurringRules(),
          builder: (context, rules) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              TabTitle(l10n.recurringTab),
              const SizedBox(height: 8),
              Text(
                l10n.recurringIntro,
                style: TextStyle(color: AppColors.of(context).textMuted),
              ),
              for (final kind in RuleKind.values) ...[
                const SizedBox(height: 20),
                Text(
                  _heading(l10n, kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final r in rules.where((r) => r.kind == kind))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RuleRow(rule: r, rules: rules),
                  ),
              ],
              if (state.household != null) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: l10n.applyAllExpenses(state.household!.name),
                  kind: ButtonKind.secondary,
                  onPressed: () => attemptMoney(
                    context,
                    () => state.change(
                      (repo) => repo.applyAllRules(state.household!.id),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FabBar(
        children: [
          AppButton(
            label: l10n.addRule,
            height: 48,
            onPressed: () => showRuleSheet(context),
          ),
        ],
      ),
    );
  }

  String _heading(AppLocalizations l10n, RuleKind kind) => switch (kind) {
    RuleKind.income => l10n.rulesIncomes,
    RuleKind.transfer => l10n.rulesTransfers,
    RuleKind.expense => l10n.rulesExpenses,
  };
}

String scheduleLabel(AppLocalizations l10n, RecurringRule r) =>
    r.frequency == RuleFrequency.monthly
    ? l10n.monthlyOnDay(r.dayOfMonth ?? 1)
    : l10n.everyWeeksFrom(
        r.everyWeeks ?? 1,
        DateFormat('d.MM').format(r.anchorOn ?? r.startsOn ?? DateTime.now()),
      );

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.rule, required this.rules});
  final RecurringRule rule;

  /// All the rules, for the income a transfer follows.
  final List<RecurringRule> rules;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.read<BudgetState>();
    final household = state.households
        .where((h) => h.id == rule.householdId)
        .firstOrNull;
    final income = rule.followsIncome
        ? rules.where((r) => r.id == rule.incomeRuleId).firstOrNull
        : null;
    return SurfaceCard(
      outline: rule.estimated ? CardOutline.estimate : CardOutline.normal,
      onTap: () => showRuleSheet(context, existing: rule),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  [
                    if (!rule.followsIncome) scheduleLabel(l10n, rule),
                    if (household != null) household.name,
                    if (rule.estimated) l10n.estimated,
                    if (rule.toNextPeriod) l10n.toNextPeriod,
                  ].join(' · '),
                  style: TextStyle(color: c.textMuted),
                ),
                Text(
                  rule.followsIncome
                      ? l10n.wholeIncomeOf(income?.name ?? '')
                      : formatMinor(rule.amountMinor),
                ),
                // it goes when its income goes
                if (!rule.followsIncome) ...[
                  const SizedBox(height: 8),
                  SmallButton(
                    label: l10n.applyNow,
                    onPressed: rule.active
                        ? () => applyRuleNow(context, rule)
                        : null,
                  ),
                ],
              ],
            ),
          ),
          ToggleSwitch(
            value: rule.active,
            onChanged: (v) => attemptMoney(
              context,
              () => state.change(
                (repo) => repo.saveRule(rule.copyWith(active: v)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Applies the next occurrence of a rule now (F25, F26) and says what came
/// of it: made, sent to the to-do list, or nothing left in this period.
Future<void> applyRuleNow(BuildContext context, RecurringRule rule) async {
  final l10n = AppLocalizations.of(context);
  final state = context.read<BudgetState>();
  final messenger = ScaffoldMessenger.of(context);
  final amount = rule.estimated
      ? await askAmount(
          context,
          title: l10n.applyNow,
          message: l10n.applyEstimateHint,
          initialMinor: rule.amountMinor,
        )
      : rule.amountMinor;
  if (amount == null || !context.mounted) return;
  ({int applied, int todo})? result;
  final ok = await attemptMoney(
    context,
    () async => result = await state.change(
      (repo) =>
          repo.applyRule(rule.id!, amountMinor: rule.estimated ? amount : null),
    ),
  );
  if (!ok || result == null) return;
  final message = result!.applied > 0
      ? l10n.appliedDone
      : result!.todo > 0
      ? l10n.appliedToTodo
      : l10n.appliedNothing;
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showRuleSheet(BuildContext context, {RecurringRule? existing}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RuleSheet(existing: existing),
    );

class _RuleSheet extends StatefulWidget {
  const _RuleSheet({this.existing});
  final RecurringRule? existing;

  @override
  State<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<_RuleSheet> {
  late RuleKind _kind = widget.existing?.kind ?? RuleKind.expense;
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : amountText(widget.existing!.amountMinor / 100),
  );
  late bool _estimated = widget.existing?.estimated ?? false;
  late RuleFrequency _frequency =
      widget.existing?.frequency ?? RuleFrequency.monthly;
  late int _day = widget.existing?.dayOfMonth ?? DateTime.now().day;
  late int _weeks = widget.existing?.everyWeeks ?? 1;
  late DateTime _anchor = widget.existing?.anchorOn ?? DateTime.now();
  late bool _toNext = widget.existing?.toNextPeriod ?? false;

  /// A transfer that moves the whole of each income of this rule.
  late String? _incomeRuleId = widget.existing?.incomeRuleId;
  String? _householdId;
  String? _envelopeId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<BudgetState>();
    _householdId = widget.existing?.householdId ?? state.household?.id;
    _envelopeId = widget.existing?.envelopeId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  bool get _follows => _kind == RuleKind.transfer && _incomeRuleId != null;

  Future<void> _save(List<RecurringRule> incomes) async {
    // a transfer that follows an income takes its amount and schedule
    final income = _follows
        ? incomes.where((r) => r.id == _incomeRuleId).firstOrNull
        : null;
    if (_follows && income == null) return;
    final minor =
        income?.amountMinor ?? ((parseAmount(_amount.text) ?? 0) * 100).round();
    if (_name.text.trim().isEmpty && income != null) {
      _name.text = income.name;
    }
    if (minor <= 0 || _name.text.trim().isEmpty) return;
    if (_kind == RuleKind.expense && _envelopeId == null) return;
    setState(() => _saving = true);
    final state = context.read<BudgetState>();
    final rule = RecurringRule(
      id: widget.existing?.id,
      kind: _kind,
      householdId: _kind == RuleKind.income ? null : _householdId,
      envelopeId: _kind == RuleKind.expense ? _envelopeId : null,
      name: _name.text.trim(),
      amountMinor: minor,
      estimated: _kind != RuleKind.transfer && _estimated,
      frequency: _frequency,
      dayOfMonth: _day,
      everyWeeks: _weeks,
      anchorOn: _frequency == RuleFrequency.weeks ? _anchor : null,
      startsOn: widget.existing?.startsOn,
      toNextPeriod: _toNext,
      incomeRuleId: _follows ? _incomeRuleId : null,
      active: widget.existing?.active ?? true,
    );
    final ok = await attemptMoney(
      context,
      () => state.change((repo) => repo.saveRule(rule)),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final yes = await confirmDanger(
      context,
      title: l10n.deleteRule,
      body: widget.existing!.kind == RuleKind.income
          ? l10n.deleteIncomeRuleConfirm
          : l10n.deleteRuleConfirm,
      action: l10n.delete,
    );
    if (!yes || !mounted) return;
    final navigator = Navigator.of(context);
    final ok = await attemptMoney(
      context,
      () => state.change((repo) => repo.deleteRule(widget.existing!.id!)),
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BudgetState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: RemoteData<List<RecurringRule>>(
        version: state.version,
        load: () => state.repository.recurringRules(),
        builder: (context, all) => _form(context, [
          for (final r in all)
            if (r.kind == RuleKind.income) r,
        ]),
      ),
    );
  }

  Widget _form(BuildContext context, List<RecurringRule> incomes) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    final isNew = widget.existing == null;
    final follows = _follows;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isNew ? l10n.addRule : l10n.editRule,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (isNew)
            ChipWrap(
              children: [
                for (final k in RuleKind.values)
                  PillChip(
                    label: switch (k) {
                      RuleKind.income => l10n.ruleIncome,
                      RuleKind.transfer => l10n.ruleTransfer,
                      RuleKind.expense => l10n.ruleExpense,
                    },
                    selected: _kind == k,
                    onTap: () => setState(() => _kind = k),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          LabeledField(label: l10n.name, controller: _name),
          if (_kind == RuleKind.transfer && incomes.isNotEmpty) ...[
            const SizedBox(height: 12),
            FieldLabel(l10n.transferHowMuch),
            ChipWrap(
              children: [
                PillChip(
                  label: l10n.fixedAmount,
                  selected: !follows,
                  onTap: () => setState(() => _incomeRuleId = null),
                ),
                for (final r in incomes)
                  PillChip(
                    label: l10n.wholeIncomeOf(r.name),
                    selected: _incomeRuleId == r.id,
                    onTap: () => setState(() => _incomeRuleId = r.id),
                  ),
              ],
            ),
            if (follows) ...[
              const SizedBox(height: 8),
              Text(
                l10n.wholeIncomeHint,
                style: TextStyle(color: AppColors.of(context).textMuted),
              ),
            ],
          ],
          if (!follows) ...[
            const SizedBox(height: 12),
            BigAmountField(label: l10n.amount, controller: _amount),
          ],
          if (_kind != RuleKind.income) ...[
            const SizedBox(height: 12),
            FieldLabel(l10n.household),
            ChipWrap(
              children: [
                for (final h in state.households)
                  PillChip(
                    label: h.name,
                    selected: _householdId == h.id,
                    onTap: () => setState(() {
                      _householdId = h.id;
                      _envelopeId = null;
                    }),
                  ),
              ],
            ),
          ],
          if (_kind == RuleKind.expense && _householdId != null) ...[
            const SizedBox(height: 12),
            FieldLabel(l10n.envelope),
            RemoteData<List<Envelope>>(
              version: _householdId,
              load: () => state.repository.envelopes(_householdId!),
              builder: (context, envelopes) => ChipWrap(
                children: [
                  for (final e in envelopes.where((e) => !e.archived))
                    PillChip(
                      label: e.name,
                      selected: _envelopeId == e.id,
                      onTap: () => setState(() => _envelopeId = e.id),
                    ),
                ],
              ),
            ),
          ],
          if (!follows) ...[
            const SizedBox(height: 12),
            FieldLabel(l10n.frequency),
            ChipWrap(
              children: [
                PillChip(
                  label: l10n.monthly,
                  selected: _frequency == RuleFrequency.monthly,
                  onTap: () =>
                      setState(() => _frequency = RuleFrequency.monthly),
                ),
                PillChip(
                  label: l10n.weekly,
                  selected: _frequency == RuleFrequency.weeks,
                  onTap: () => setState(() => _frequency = RuleFrequency.weeks),
                ),
              ],
            ),
            if (_frequency == RuleFrequency.monthly)
              DropdownButton<int>(
                value: _day,
                items: [
                  for (var d = 1; d <= 31; d++)
                    DropdownMenuItem(
                      value: d,
                      child: Text(l10n.monthlyOnDay(d)),
                    ),
                ],
                onChanged: (d) => setState(() => _day = d ?? 1),
              )
            else
              Row(
                children: [
                  DropdownButton<int>(
                    value: _weeks,
                    items: [
                      for (var w = 1; w <= 8; w++)
                        DropdownMenuItem(
                          value: w,
                          child: Text(l10n.cycleEveryWeeks(w)),
                        ),
                    ],
                    onChanged: (w) => setState(() => _weeks = w ?? 1),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _anchor,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _anchor = picked);
                    },
                    child: Text(
                      l10n.cycleFromDay(
                        DateFormat('d.MM.yyyy').format(_anchor),
                      ),
                    ),
                  ),
                ],
              ),
          ],
          if (_kind != RuleKind.transfer)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _kind == RuleKind.income
                        ? l10n.estimatedIncomeRule
                        : l10n.estimatedExpenseRule,
                  ),
                ),
                ToggleSwitch(
                  value: _estimated,
                  onChanged: (v) => setState(() => _estimated = v),
                ),
              ],
            ),
          if (_kind == RuleKind.transfer)
            Row(
              children: [
                Expanded(child: Text(l10n.toNextPeriodHint)),
                ToggleSwitch(
                  value: _toNext,
                  onChanged: (v) => setState(() => _toNext = v),
                ),
              ],
            ),
          const SizedBox(height: 16),
          AppButton(
            label: l10n.save,
            busy: _saving,
            onPressed: () => _save(incomes),
          ),
          if (!isNew &&
              widget.existing!.active &&
              !widget.existing!.followsIncome) ...[
            const SizedBox(height: 8),
            AppButton(
              label: l10n.applyNow,
              kind: ButtonKind.tonal,
              onPressed: _saving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      await applyRuleNow(context, widget.existing!);
                      navigator.pop();
                    },
            ),
          ],
          if (!isNew) ...[
            const SizedBox(height: 8),
            AppButton(
              label: l10n.deleteRule,
              kind: ButtonKind.secondary,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
    );
  }
}
