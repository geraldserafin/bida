import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../models/period.dart';
import '../../state/app_settings.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../../util/pickers.dart';
import '../categories/category_editor.dart';

/// Set up a new planning period, or edit the current period's plan when
/// [editPeriod] is provided. Income and per-category allocations are editable;
/// over-allocation is warned about, never blocked.
class NewPeriodScreen extends StatefulWidget {
  const NewPeriodScreen({super.key, this.editPeriod});

  /// When non-null, the screen edits this (current) period instead of creating
  /// a new one.
  final Period? editPeriod;

  @override
  State<NewPeriodScreen> createState() => _NewPeriodScreenState();
}

String _amountText(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  return s.replaceAll('.', ',');
}

double _parseAmount(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

class _NewPeriodScreenState extends State<NewPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;

  /// categoryId -> planned amount text controller.
  final Map<int, TextEditingController> _plannedControllers = {};

  bool _saving = false;

  bool get _isEdit => widget.editPeriod != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editPeriod;
    if (edit != null) {
      _nameController.text = edit.name;
      _startDate = edit.startDate;
      _endDate = edit.endDate;
      _incomeController.text = _amountText(edit.income);
      // Pre-fill existing allocations from the current period's progress.
      for (final cp in context.read<PlannerState>().progress) {
        _plannedControllers[cp.category.id!] = TextEditingController(
          text: _amountText(cp.planned),
        );
      }
    } else {
      final now = DateTime.now();
      final firstDay = context.read<AppSettings>().firstDayOfMonth;
      _startDate = DateTime(now.year, now.month, firstDay);
      // End = the day before the next period's start.
      _endDate = DateTime(
        now.year,
        now.month + 1,
        firstDay,
      ).subtract(const Duration(days: 1));
      _nameController.text = toBeginningOfSentenceCase(
        DateFormat.yMMMM('pl').format(_startDate),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    for (final c in _plannedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _income => _parseAmount(_incomeController.text);

  double get _totalPlanned {
    var sum = 0.0;
    for (final c in _plannedControllers.values) {
      sum += _parseAmount(c.text);
    }
    return sum;
  }

  double get _unallocated => _income - _totalPlanned;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final state = context.read<PlannerState>();

    // Include every category (0 included) so edits can also clear allocations.
    final planned = <int, double>{
      for (final entry in _plannedControllers.entries)
        entry.key: _parseAmount(entry.value.text),
    };

    if (_isEdit) {
      await state.editCurrentPeriodPlan(
        income: _income,
        plannedByCategory: planned,
      );
    } else {
      await state.createPeriod(
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        income: _income,
        plannedByCategory: planned,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addCategory() async {
    final created = await showCategoryEditor(context);
    if (created != null && mounted) {
      await context.read<PlannerState>().addCategory(created);
    }
  }

  /// Fills the planned allocation fields from active recurring rules.
  void _prefillFromRecurring() {
    final planned = context.read<PlannerState>().plannedFromRecurring();
    setState(() {
      planned.forEach((categoryId, amount) {
        final controller = _plannedControllers.putIfAbsent(
          categoryId,
          TextEditingController.new,
        );
        controller.text = amount.toString().replaceAll('.', ',');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = context.watch<PlannerState>().categories;
    final dateFmt = DateFormat.yMMMd('pl');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editPlan : l10n.newPeriod)),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit) ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.periodName,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.enterName : null,
              ),
              const SizedBox(height: 12),
              _DateRangeField(
                label: l10n.dateRange,
                start: _startDate,
                end: _endDate,
                format: dateFmt,
                onPick: (range) => setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                }),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.incomeForPeriod,
                suffixText: 'zł',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final value = _parseAmount(v ?? '');
                if (value <= 0) return l10n.enterIncome;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              l10n.splitAcrossCategories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                if (context
                    .watch<PlannerState>()
                    .activeRecurringRules
                    .isNotEmpty)
                  TextButton.icon(
                    onPressed: _prefillFromRecurring,
                    icon: const Icon(Icons.repeat, size: 18),
                    label: Text(l10n.prefillFromRecurring),
                  ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCategory),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.noCategories),
              )
            else
              ...categories.map(_categoryRow),
            const SizedBox(height: 16),
            _AllocationSummary(
              planned: _totalPlanned,
              unallocated: _unallocated,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEdit ? l10n.saveChanges : l10n.createPeriod),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(Category category) {
    final controller = _plannedControllers.putIfAbsent(
      category.id!,
      TextEditingController.new,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: category.displayColor.withValues(alpha: 0.2),
            child: Icon(
              category.displayIcon,
              size: 16,
              color: category.displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name)),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                suffixText: 'zł',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.label,
    required this.start,
    required this.end,
    required this.format,
    required this.onPick,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final DateFormat format;
  final ValueChanged<DateTimeRange> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await pickDateRange(
          context,
          initial: DateTimeRange(start: start, end: end),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.date_range_outlined),
        ),
        child: Text('${format.format(start)} – ${format.format(end)}'),
      ),
    );
  }
}

class _AllocationSummary extends StatelessWidget {
  const _AllocationSummary({required this.planned, required this.unallocated});

  final double planned;
  final double unallocated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final over = unallocated < 0;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: over ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, l10n.planned, formatZloty(planned)),
            const SizedBox(height: 4),
            _row(
              context,
              over ? l10n.overAllocated : l10n.unallocated,
              formatZloty(unallocated),
              emphasize: true,
              color: over ? scheme.onErrorContainer : null,
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Text(
                l10n.overAllocationWarning(formatZloty(-unallocated)),
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
