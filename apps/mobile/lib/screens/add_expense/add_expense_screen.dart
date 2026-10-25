import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/expense.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../categories/category_editor.dart';

String _amountText(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  return s.replaceAll('.', ',');
}

/// Amount-first entry for logging a real expense against an envelope, or
/// editing an existing one when [existing] is provided.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialSplitId, this.existing});

  final int? initialSplitId;
  final Expense? existing;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _splitId;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _amountError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _splitId = e.splitId;
      _amountController.text = _amountText(e.amount);
      _date = e.date;
      _noteController.text = e.note ?? '';
    } else {
      _splitId = widget.initialSplitId;
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
    if (_splitId == null) {
      setState(() {}); // surface the "pick an envelope" hint
      return;
    }

    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (_isEdit) {
      await state.updateExpense(
        widget.existing!.copyWith(
          splitId: _splitId!,
          amount: _amount,
          date: _date,
          note: note,
        ),
      );
    } else {
      await state.addExpense(
        splitId: _splitId!,
        amount: _amount,
        date: _date,
        note: note,
      );
    }
    // Return the envelope that was saved to, so callers can follow it.
    if (mounted) Navigator.of(context).pop(_splitId);
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
    await context.read<PlannerState>().deleteExpense(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop(_splitId);
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
    final splitId = await context.read<PlannerState>().quickAddEnvelope(
      created,
    );
    if (mounted && splitId != null) setState(() => _splitId = splitId);
  }

  String _dateLabel(AppLocalizations l10n) {
    final now = DateTime.now();
    final isToday =
        _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final formatted = DateFormat.MMMMd('pl').format(_date);
    return isToday ? '${l10n.today}, $formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final progress = context.watch<PlannerState>().progress;
    CategoryProgress? selected;
    for (final p in progress) {
      if (p.split.id == _splitId) {
        selected = p;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(_isEdit ? l10n.editExpense : l10n.newExpense),
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
          16,
          8,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? l10n.saveChanges : l10n.saveExpense),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // ---- amount ----
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.amount,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  autofocus: !_isEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    border: InputBorder.none,
                    hintText: '0,00',
                  ),
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'zł',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (_amountError != null)
            Center(
              child: Text(
                _amountError!,
                style: TextStyle(color: scheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 20),

          // ---- category grid ----
          Text(
            l10n.category,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (progress.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.noEnvelopesForExpense,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          else
            _CategoryGrid(
              progress: progress,
              selectedSplitId: _splitId,
              onSelect: (id) => setState(() {
                _splitId = id;
                _amountError = null;
              }),
              onAddNew: _addNewCategory,
            ),
          const SizedBox(height: 16),

          // ---- remaining in selected envelope ----
          if (selected != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.remainingInCategory(selected.category.name),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      formatZloty(selected.remaining),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected.remaining < 0
                            ? scheme.error
                            : selected.category.displayColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // ---- note ----
          Text(
            l10n.note,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(hintText: l10n.noteHint),
          ),
          const SizedBox(height: 12),

          // ---- date ----
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_dateLabel(l10n))),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.progress,
    required this.selectedSplitId,
    required this.onSelect,
    required this.onAddNew,
  });

  final List<CategoryProgress> progress;
  final int? selectedSplitId;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 6,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final p in progress)
          _CategoryChip(
            progress: p,
            selected: p.split.id == selectedSplitId,
            onTap: () => onSelect(p.split.id!),
          ),
        _AddChip(onTap: onAddNew),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.progress,
    required this.selected,
    required this.onTap,
  });

  final CategoryProgress progress;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.category.displayColor;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.18)
                  : scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : scheme.surfaceContainerHigh,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(
              progress.category.displayIcon,
              color: selected ? color : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progress.category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: DottedBorderBox(
            color: scheme.outline,
            child: Icon(Icons.add, color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.addNew,
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// A 56×56 rounded box with a dashed border, for the "add new" affordance.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color),
      child: SizedBox(width: 56, height: 56, child: Center(child: child)),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
