import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../state/app_settings.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/category_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../categories/category_editor.dart';
import '../recurring/recurring_rules_screen.dart';

const _steps = 5;

double _parseAmount(String raw) =>
    double.tryParse(raw.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.')) ??
    0;

/// A category the wizard offers to add at the start.
class _Starter {
  const _Starter(this.name, this.color, this.icon);
  final String name;
  final String color;
  final String icon;
}

/// Money expected to come in during the first period, typed in step 3.
class _Income {
  const _Income(this.name, this.amount, {required this.estimated});
  final String name;
  final double amount;
  final bool estimated;
}

/// First run ("Kreator"): names the household, says who uses it, collects
/// the income, the recurring bills and the envelopes, and creates the first
/// period from them.
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _step = 0;
  bool _busy = false;

  // step 1
  final _nameController = TextEditingController();
  final Set<int> _skippedStarters = {};
  String? _nameError;

  // step 2
  bool _multi = false;

  // step 3
  final List<_Income> _incomes = [];
  final _incomeNameController = TextEditingController();
  final _incomeAmountController = TextEditingController();
  bool _incomeEstimated = false;

  // step 5
  final Map<String, TextEditingController> _planned = {};
  String? _incomeError;

  late final String _periodName;
  late final DateTime _start;
  late final DateTime _end;

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<PlannerState>().household?.name ?? '';
    final now = DateTime.now();
    final firstDay = context.read<AppSettings>().firstDayOfMonth;
    _start = DateTime(now.year, now.month, firstDay);
    // End = the day before the next period's start.
    _end = DateTime(
      now.year,
      now.month + 1,
      firstDay,
    ).subtract(const Duration(days: 1));
    _periodName = toBeginningOfSentenceCase(
      DateFormat.yMMMM('pl').format(_start),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  /// Step 1: names the household and adds the starting categories that are
  /// not there yet.
  Future<void> _saveHousehold() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.enterName);
      return;
    }
    final state = context.read<PlannerState>();
    final existing = {for (final c in state.categories) c.name.toLowerCase()};
    final starters = _starters(l10n);
    setState(() => _busy = true);
    final saved = await attempt(context, () async {
      if (name != state.household?.name) await state.renameHousehold(name);
      for (final (i, s) in starters.indexed) {
        if (_skippedStarters.contains(i)) continue;
        if (existing.contains(s.name.toLowerCase())) continue;
        await state.addCategory(
          Category(name: s.name, color: s.color, icon: s.icon),
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
          estimated: _incomeEstimated,
        ),
      );
      _incomeNameController.clear();
      _incomeAmountController.clear();
      _incomeError = null;
    });
  }

  /// Step 5 starts from what the recurring bills already need.
  void _openEnvelopes() {
    final suggested = context.read<PlannerState>().plannedFromRecurring();
    suggested.forEach((categoryId, amount) {
      final controller = _planned.putIfAbsent(
        categoryId,
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
    setState(() => _busy = true);
    final created = await attempt(
      context,
      () => state.createPeriod(
        name: _periodName,
        startDate: _start,
        endDate: _end,
        income: _income,
        plannedByCategory: {
          for (final e in _planned.entries) e.key: _parseAmount(e.value.text),
        },
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (created) navigator.pop();
  }

  Future<void> _addCategory() async {
    final created = await showCategoryEditor(context);
    if (created != null && mounted) {
      final state = context.read<PlannerState>();
      await attempt(context, () => state.addCategory(created));
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
      0 => (_householdStep(context), l10n.next, _saveHousehold),
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

  // ---- step 1: the household -----------------------------------------------

  Widget _householdStep(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final starters = _starters(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardNameTitle, l10n.wizardNameBody),
        const SizedBox(height: 22),
        LabeledField(
          label: l10n.name,
          controller: _nameController,
          autofocus: _nameController.text.isEmpty,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        if (_nameError != null) _ErrorText(_nameError!),
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
              FieldLabel(l10n.starterCategories),
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
    final name = _nameController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardWhoTitle(name)),
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
        if (_multi) ...[
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LabeledField(
                  label: l10n.inviteByEmail,
                  hint: l10n.inviteHint,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: l10n.send,
                kind: ButtonKind.tonal,
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.sharingSoon,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.of(context).estimate,
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
          l10n.wizardIncomeBody(_periodName),
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
              details: income.estimated
                  ? l10n.estimatedAmount.toLowerCase()
                  : l10n.fixedAmount.toLowerCase(),
              amount:
                  '${income.estimated ? '~' : ''}${formatZloty(income.amount)}',
              tone: income.estimated ? AmountTone.estimate : AmountTone.income,
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
                options: [
                  (false, l10n.fixedAmount),
                  (true, l10n.estimatedAmount),
                ],
                selected: _incomeEstimated,
                onChanged: (v) => setState(() => _incomeEstimated = v),
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
          label: l10n.periodIncome,
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
    final categoriesById = {for (final c in state.categories) c.id: c};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n.wizardBillsTitle, l10n.wizardBillsBody),
        const SizedBox(height: 20),
        for (final rule in state.recurringRules) ...[
          TransactionRow(
            color:
                categoriesById[rule.categoryId]?.displayColor ??
                AppColors.of(context).textMuted,
            title: rule.note?.isNotEmpty == true
                ? rule.note!
                : categoriesById[rule.categoryId]?.name ?? '—',
            details: ruleDetails(l10n, rule, categoriesById[rule.categoryId]),
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
    final fromRecurring = state.plannedFromRecurring();
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
              for (final category in state.categories)
                _EnvelopeInput(
                  category: category,
                  note: fromRecurring[category.id] == null
                      ? null
                      : l10n.fromRecurring(
                          formatZloty(fromRecurring[category.id]!),
                        ),
                  controller: _planned.putIfAbsent(
                    category.id!,
                    TextEditingController.new,
                  ),
                  onChanged: () => setState(() {}),
                ),
              InkWell(
                onTap: _addCategory,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.addCategoryPlus,
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

/// A category with the amount planned for it, one row of step 5.
class _EnvelopeInput extends StatelessWidget {
  const _EnvelopeInput({
    required this.category,
    required this.note,
    required this.controller,
    required this.onChanged,
  });

  final Category category;

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
          CategoryDot(category.displayColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
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
