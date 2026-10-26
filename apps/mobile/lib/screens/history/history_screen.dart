import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../../util/pickers.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/transaction_row.dart';
import '../add_expense/add_expense_screen.dart';

/// History tab ("Historia"): the current period's expenses, newest first,
/// filtered by category and by date and time.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _categoryId; // null = all
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
    final period = state.currentPeriod;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: TabTitle(l10n.history, trailing: period?.name),
            ),
            Expanded(
              child: period == null
                  ? Center(child: Text(l10n.noTransactions))
                  : RemoteData<List<Transaction>>(
                      // fetched again when the period or what was spent
                      // changes, not on every filter tap
                      version: (period.id, state.totalSpent),
                      load: state.currentPeriodTransactions,
                      builder: (context, all) => _filtered(context, all),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtered(BuildContext context, List<Transaction> all) {
    final l10n = AppLocalizations.of(context);
    if (all.isEmpty) {
      return Center(child: Text(l10n.noTransactions));
    }

    // Distinct categories for the filter row (first-seen order).
    final categories = <String, String>{};
    for (final t in all) {
      categories.putIfAbsent(t.category.id!, () => t.category.name);
    }

    final from = _from;
    final to = _to;
    final visible = all.where((t) {
      if (_categoryId != null && t.category.id != _categoryId) return false;
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null && t.date.isAfter(to)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Overline(l10n.category),
        ),
        const SizedBox(height: 14),
        _ChipRow(
          children: [
            PillChip(
              label: l10n.all,
              selected: _categoryId == null,
              onTap: () => setState(() => _categoryId = null),
            ),
            for (final entry in categories.entries)
              PillChip(
                label: entry.value,
                selected: _categoryId == entry.key,
                onTap: () => setState(() => _categoryId = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _ChipRow(children: _dateChips(context)),
        const SizedBox(height: 10),
        Expanded(
          child: visible.isEmpty
              ? Center(child: Text(l10n.noMatchingExpenses))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _TransactionTile(transaction: visible[i]),
                ),
        ),
      ],
    );
  }

  /// A "date range" chip; once a range is picked, start and end time chips
  /// and one that clears them.
  List<Widget> _dateChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final range = _dateRange;
    final dateFmt = DateFormat.MMMd('pl');
    return [
      PillChip(
        label: range == null
            ? l10n.dateRange
            : '${dateFmt.format(range.start)} – ${dateFmt.format(range.end)}',
        selected: range != null,
        onTap: _pickRange,
      ),
      if (range != null) ...[
        PillChip(
          label: _startTime.format(context),
          selected: false,
          onTap: () => _pickTime(isStart: true),
        ),
        PillChip(
          label: _endTime.format(context),
          selected: false,
          onTap: () => _pickTime(isStart: false),
        ),
        PillChip(label: '×', selected: false, onTap: _clearDates),
      ],
    ];
  }
}

/// Chips in one line that scrolls sideways.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = transaction.note;
    final hasNote = note != null && note.isNotEmpty;
    final details = [
      DateFormat('dd.MM HH:mm').format(transaction.date),
      if (hasNote) transaction.category.name,
      if (transaction.recurringId != null) l10n.recurringMark,
    ].join(' · ');

    return TransactionRow(
      color: transaction.category.displayColor,
      title: hasNote ? note : transaction.category.name,
      details: details,
      amount: '−${formatZloty(transaction.amount)}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(existing: transaction.expense),
        ),
      ),
    );
  }
}
