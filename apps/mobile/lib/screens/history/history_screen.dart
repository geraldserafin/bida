import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../../util/pickers.dart';
import '../add_expense/add_expense_screen.dart';

/// History (Historia): the current period's transactions grouped by day, with
/// a category filter.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _categoryId; // null = all
  DateTimeRange? _dateRange; // null = any date
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 59);

  /// Lower bound of the active date+time filter, or null when no range is set.
  DateTime? get _from {
    final r = _dateRange;
    if (r == null) return null;
    return DateTime(
      r.start.year,
      r.start.month,
      r.start.day,
      _startTime.hour,
      _startTime.minute,
    );
  }

  /// Upper bound of the active date+time filter, or null when no range is set.
  DateTime? get _to {
    final r = _dateRange;
    if (r == null) return null;
    return DateTime(
      r.end.year,
      r.end.month,
      r.end.day,
      _endTime.hour,
      _endTime.minute,
    );
  }

  Future<void> _pickRange() async {
    final picked = await pickDateRange(context, initial: _dateRange);
    if (picked != null) setState(() => _dateRange = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _clearDates() => setState(() {
    _dateRange = null;
    _startTime = const TimeOfDay(hour: 0, minute: 0);
    _endTime = const TimeOfDay(hour: 23, minute: 59);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: FutureBuilder<List<Transaction>>(
        key: ValueKey(state.totalSpent),
        future: state.currentPeriodTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          if (all.isEmpty) {
            return Center(child: Text(l10n.noExpenses));
          }

          // Distinct categories for the filter row (first-seen order).
          final categories = <int, String>{};
          for (final t in all) {
            categories.putIfAbsent(t.category.id!, () => t.category.name);
          }

          final from = _from;
          final to = _to;
          final visible = all.where((t) {
            if (_categoryId != null && t.category.id != _categoryId) {
              return false;
            }
            if (from != null && t.date.isBefore(from)) return false;
            if (to != null && t.date.isAfter(to)) return false;
            return true;
          }).toList();

          return Column(
            children: [
              _FilterBar(
                categories: categories,
                selected: _categoryId,
                onSelect: (id) => setState(() => _categoryId = id),
              ),
              _DateFilterBar(
                range: _dateRange,
                startTime: _startTime,
                endTime: _endTime,
                onPickRange: _pickRange,
                onPickStartTime: () => _pickTime(isStart: true),
                onPickEndTime: () => _pickTime(isStart: false),
                onClear: _clearDates,
              ),
              const Divider(height: 1),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(l10n.noMatchingExpenses))
                    : _DayGroups(transactions: visible),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Date-range + time-of-day filter row. When no range is set it shows a single
/// "date range" pill; once a range is picked, start/end time pills and a clear
/// button appear.
class _DateFilterBar extends StatelessWidget {
  const _DateFilterBar({
    required this.range,
    required this.startTime,
    required this.endTime,
    required this.onPickRange,
    required this.onPickStartTime,
    required this.onPickEndTime,
    required this.onClear,
  });

  final DateTimeRange? range;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onPickRange;
  final VoidCallback onPickStartTime;
  final VoidCallback onPickEndTime;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.MMMd('pl');
    final active = range != null;
    final rangeLabel = active
        ? '${dateFmt.format(range!.start)} – ${dateFmt.format(range!.end)}'
        : l10n.dateRange;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          _PillButton(
            icon: Icons.date_range_outlined,
            label: rangeLabel,
            highlighted: active,
            onTap: onPickRange,
          ),
          if (active) ...[
            _PillButton(
              icon: Icons.schedule_outlined,
              label: startTime.format(context),
              onTap: onPickStartTime,
            ),
            _PillButton(
              icon: Icons.schedule_outlined,
              label: endTime.format(context),
              onTap: onPickEndTime,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: scheme.surfaceContainerHigh),
                  ),
                  child: Icon(Icons.close, size: 16, color: scheme.onSurface),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = highlighted ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: highlighted ? scheme.primary : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted ? scheme.primary : scheme.surfaceContainerHigh,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final Map<int, String> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(
            label: l10n.all,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final entry in categories.entries)
            _Chip(
              label: entry.value,
              selected: selected == entry.key,
              onTap: () => onSelect(entry.key),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? scheme.primary : scheme.surfaceContainerHigh,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayGroups extends StatelessWidget {
  const _DayGroups({required this.transactions});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Group by calendar day, preserving newest-first order.
    final groups = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label(DateTime day) {
      final md = DateFormat.MMMMd('pl').format(day);
      if (day == today) return '${l10n.today} · $md';
      if (day == yesterday) return '${l10n.yesterday} · $md';
      return md;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              label(day).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < groups[day]!.length; i++) ...[
                  _TransactionTile(transaction: groups[day]![i]),
                  if (i < groups[day]!.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = transaction.category.displayColor;
    final timeFmt = DateFormat.Hm('pl');

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(existing: transaction.toExpense()),
        ),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(transaction.category.displayIcon, color: color, size: 20),
      ),
      title: Text(
        transaction.category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: transaction.note == null || transaction.note!.isEmpty
          ? null
          : Text(
              transaction.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '−${formatZloty(transaction.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            timeFmt.format(transaction.date),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
