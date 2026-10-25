import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/expense.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../add_expense/add_expense_screen.dart';
import 'widgets/spending_line_chart.dart';

/// Opens the expense editor and, if the expense was saved to a *different*
/// envelope than the one being viewed, follows it to that envelope's detail —
/// so you always land on the category you actually added to.
Future<void> _openExpense(
  BuildContext context, {
  int? initialSplitId,
  Expense? existing,
  int? currentSplitId,
}) async {
  final from = currentSplitId ?? initialSplitId;
  final saved = await Navigator.of(context).push<int>(
    MaterialPageRoute(
      builder: (_) =>
          AddExpenseScreen(initialSplitId: initialSplitId, existing: existing),
    ),
  );
  if (saved != null && saved != from && context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CategoryDetailScreen(splitId: saved)),
    );
  }
}

/// Detail for a single envelope: planned/spent/remaining plus the list of
/// expenses logged against it, each of which can be deleted.
class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key, required this.splitId});

  final int splitId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    // Resolve the live progress row for this split (updates after a delete).
    final matches = state.progress.where((p) => p.split.id == splitId);
    if (matches.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final progress = matches.first;

    return Scaffold(
      appBar: AppBar(title: Text(progress.category.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpense(context, initialSplitId: splitId),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: Column(
        children: [
          _Header(progress: progress),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Expense>>(
              // Keyed on spent so the data re-queries after add/delete.
              key: ValueKey(progress.spent),
              future: state.expensesForSplit(splitId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final expenses = snapshot.data!;
                final color = progress.category.displayColor;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SpendingLineChart(expenses: expenses, color: color),
                    const SizedBox(height: 16),
                    Text(
                      l10n.expenses,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (expenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text(l10n.noExpenses)),
                      )
                    else
                      for (var i = 0; i < expenses.length; i++) ...[
                        _ExpenseTile(expense: expenses[i], color: color),
                        if (i < expenses.length - 1) const Divider(height: 1),
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.progress});
  final CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Stat(label: l10n.planned, value: formatZloty(progress.planned)),
              _Stat(label: l10n.spent, value: formatZloty(progress.spent)),
              _Stat(
                label: progress.isOverspent
                    ? l10n.overAllocated
                    : l10n.remaining,
                value: formatZloty(progress.remaining),
                color: progress.isOverspent ? scheme.error : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: progress.isOverspent
                  ? scheme.error
                  : progress.category.displayColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.color});
  final Expense expense;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd('pl');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(Icons.receipt_long_outlined, color: color, size: 20),
      ),
      title: Text(
        formatZloty(expense.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        expense.note == null || expense.note!.isEmpty
            ? dateFmt.format(expense.date)
            : '${dateFmt.format(expense.date)} · ${expense.note}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.deleteExpense,
        onPressed: () => _confirmDelete(context),
      ),
      onTap: () => _openExpense(
        context,
        existing: expense,
        currentSplitId: expense.splitId,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final planner = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteExpense),
        content: Text(l10n.deleteExpenseConfirm(formatZloty(expense.amount))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await planner.deleteExpense(expense.id!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.expenseDeleted)));
    }
  }
}
