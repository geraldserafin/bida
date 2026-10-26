import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../data/money.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/remote_data.dart';
import '../add_expense/add_expense_screen.dart';
import '../envelopes/envelope_editor.dart';
import '../envelopes/envelopes_screen.dart';
import '../funding/fund_sheet.dart';
import '../sharing/contributions_card.dart';
import '../sharing/members_screen.dart';
import 'widgets/spending_line_chart.dart';

/// Opens the expense editor and, if the expense was saved to a *different*
/// envelope than the one being viewed, follows it to that envelope's detail —
/// so you always land on the envelope you actually added to.
Future<void> _openExpense(
  BuildContext context, {
  String? initialEnvelopeId,
  Expense? existing,
  String? currentEnvelopeId,
}) async {
  final from = currentEnvelopeId ?? initialEnvelopeId;
  final saved = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => AddExpenseScreen(
        initialEnvelopeId: initialEnvelopeId,
        existing: existing,
      ),
    ),
  );
  if (saved != null && saved != from && context.mounted) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EnvelopeDetailScreen(envelopeId: saved),
      ),
    );
  }
}

/// Detail for a single envelope: its balance this month, what was put into it
/// and the expenses logged against it. A top-level envelope also lists its
/// sub-envelopes.
class EnvelopeDetailScreen extends StatelessWidget {
  const EnvelopeDetailScreen({super.key, required this.envelopeId});

  final String envelopeId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    // Resolve the live figures for this envelope (updates after a change).
    final progress = state.progressOf(envelopeId);
    if (progress == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final envelope = progress.envelope;
    final color = envelope.displayColor;
    final children = state.childrenProgressOf(envelopeId);

    return Scaffold(
      appBar: AppBar(
        title: Text(envelope.name),
        actions: [
          IconButton(
            tooltip: l10n.members,
            icon: const Icon(Icons.group_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MembersScreen(envelopeId: envelopeId),
              ),
            ),
          ),
          if (progress.isOwner)
            IconButton(
              tooltip: l10n.editEnvelope,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final edited = await showEnvelopeEditor(
                  context,
                  existing: envelope,
                );
                if (edited != null && context.mounted) {
                  await attempt(context, () => state.updateEnvelope(edited));
                }
              },
            ),
          if (progress.isOwner)
            IconButton(
              tooltip: l10n.deleteEnvelope,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (await confirmDeleteEnvelope(context, envelope)) {
                  navigator.pop();
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpense(context, initialEnvelopeId: envelopeId),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _Header(progress: progress, hasChildren: children.isNotEmpty),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      showFundSheet(context, envelopeId: envelopeId),
                  icon: const Icon(Icons.south_west, size: 18),
                  label: Text(l10n.allocate),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showFundSheet(
                    context,
                    envelopeId: envelopeId,
                    takeBack: true,
                  ),
                  icon: const Icon(Icons.north_east, size: 18),
                  label: Text(l10n.takeBack),
                ),
              ),
            ],
          ),
          if (progress.isShared) ...[
            const SizedBox(height: 16),
            ContributionsCard(
              envelopeId: envelopeId,
              version: (
                progress.allocated,
                progress.opening,
                progress.free,
                progress.memberCount,
              ),
            ),
          ],
          if (envelope.isTopLevel) ...[
            const SizedBox(height: 20),
            _SectionTitle(l10n.subEnvelopes),
            const SizedBox(height: 8),
            for (final child in children) _SubEnvelopeTile(progress: child),
            if (progress.isOwner)
              TextButton.icon(
                onPressed: () async {
                  final created = await showEnvelopeEditor(
                    context,
                    parentId: envelopeId,
                  );
                  if (created != null && context.mounted) {
                    await attempt(context, () => state.addEnvelope(created));
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addSubEnvelope),
              ),
          ],
          const SizedBox(height: 12),
          RemoteData<List<Allocation>>(
            // fetched again when the money in the envelope changes
            version: (progress.allocated, progress.opening, progress.free),
            load: () => state.allocationsFor(envelopeId),
            builder: (context, allocations) => _Allocations(
              allocations: allocations,
              envelopeNames: {for (final e in state.envelopes) e.id!: e.name},
              rootId: envelopeId,
            ),
          ),
          const SizedBox(height: 12),
          RemoteData<List<Expense>>(
            version: (progress.spent, state.month),
            load: () => state.expensesForEnvelope(envelopeId),
            builder: (context, expenses) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SpendingLineChart(expenses: expenses, color: color),
                const SizedBox(height: 16),
                _SectionTitle(l10n.expenses),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _Header extends StatelessWidget {
  const _Header({required this.progress, required this.hasChildren});
  final EnvelopeProgress progress;
  final bool hasChildren;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatZloty(progress.balance),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: progress.isOverspent ? scheme.error : null,
          ),
        ),
        Text(
          l10n.balance,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        if (progress.isShared)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.group_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.sharedWith(progress.memberCount),
                  style: TextStyle(color: scheme.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Stat(
              label: l10n.available,
              value: formatZloty(progress.available),
            ),
            _Stat(label: l10n.spent, value: formatZloty(progress.spent)),
            _Stat(
              label: hasChildren ? l10n.freeInEnvelope : l10n.fromEarlierMonths,
              value: formatZloty(
                hasChildren ? progress.free : progress.opening,
              ),
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
                : progress.envelope.displayColor,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SubEnvelopeTile extends StatelessWidget {
  const _SubEnvelopeTile({required this.progress});
  final EnvelopeProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final envelope = progress.envelope;
    final color = envelope.displayColor;
    return Card(
      child: ListTile(
        leading: Icon(envelope.displayIcon, color: color),
        title: Text(envelope.name),
        trailing: Text(
          formatZloty(progress.balance),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: progress.isOverspent ? scheme.error : null,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EnvelopeDetailScreen(envelopeId: envelope.id!),
          ),
        ),
      ),
    );
  }
}

class _Allocations extends StatelessWidget {
  const _Allocations({
    required this.allocations,
    required this.envelopeNames,
    required this.rootId,
  });

  final List<Allocation> allocations;
  final Map<String, String> envelopeNames;
  final String rootId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd('pl');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.allocations, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (allocations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text(l10n.noAllocations)),
          )
        else
          for (final a in allocations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                a.amount >= 0 ? Icons.south_west : Icons.north_east,
                size: 20,
              ),
              title: Text(
                '${a.amount >= 0 ? '+' : '−'}${formatZloty(a.amount.abs())}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  dateFmt.format(a.madeOn),
                  if (a.envelopeId != rootId) envelopeNames[a.envelopeId],
                  if (a.note != null && a.note!.isNotEmpty) a.note,
                ].join(' · '),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.deleteAllocation,
                onPressed: () => _delete(context, a),
              ),
            ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, Allocation allocation) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllocation),
        content: Text(
          l10n.deleteAllocationConfirm(formatZloty(allocation.amount.abs())),
        ),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await state.deleteAllocation(allocation.id!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.allocationDeleted)));
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.tag == 'NotEnoughMoney'
                ? l10n.notEnoughMoney(
                    formatZloty(fromMinor(error.availableMinor ?? 0)),
                  )
                : apiErrorMessage(l10n, error),
          ),
        ),
      );
    }
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
        currentEnvelopeId: expense.envelopeId,
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

    if (confirmed == true && context.mounted) {
      final deleted = await attempt(
        context,
        () => planner.deleteExpense(expense.id!),
      );
      if (deleted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.expenseDeleted)));
      }
    }
  }
}
