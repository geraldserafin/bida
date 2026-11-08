import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../add_expense/add_expense_screen.dart';

final _time = DateFormat('HH:mm');

/// The filters of the history; null is "any".
@immutable
class HistoryFilters {
  const HistoryFilters({this.envelopeId, this.authorId, this.forWhom});
  final String? envelopeId;
  final String? authorId;

  /// 'shared' or a user id.
  final String? forWhom;

  int get count => [envelopeId, authorId, forWhom].nonNulls.length;

  @override
  bool operator ==(Object other) =>
      other is HistoryFilters &&
      other.envelopeId == envelopeId &&
      other.authorId == authorId &&
      other.forWhom == forWhom;

  @override
  int get hashCode => Object.hash(envelopeId, authorId, forWhom);
}

/// The expenses of the household on screen (F10): newest first, a day at a
/// time, with the period chosen at the top and the rest of the filters
/// (envelope, author, for whom) one tap away. The wallet has its own history.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _wholeHistory = false;
  HistoryFilters _filters = const HistoryFilters();

  Future<void> _chooseFilters() async {
    final chosen = await showModalBottomSheet<HistoryFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (chosen != null) setState(() => _filters = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    if (household == null) return const SizedBox.shrink();
    final period = state.period;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RemoteData<List<Expense>>(
          version: Object.hash(
            state.version,
            household.id,
            _wholeHistory,
            _filters,
            period?.id,
          ),
          load: () => state.repository.expenses(
            householdId: household.id,
            periodId: _wholeHistory ? null : period?.id,
            envelopeId: _filters.envelopeId,
            authorId: _filters.authorId,
            forWhom: _filters.forWhom,
          ),
          builder: (context, expenses) {
            final total = expenses.fold(0, (sum, x) => sum + x.amountMinor);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                TabTitle(l10n.history, trailing: household.name),
                const SizedBox(height: 12),
                SegmentedPills<bool>(
                  options: [(false, l10n.thisPeriod), (true, l10n.allPeriods)],
                  selected: _wholeHistory,
                  onChanged: (v) => setState(() => _wholeHistory = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatMinor(total),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            l10n.expensesCount(expenses.length),
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    SmallButton(
                      label: _filters.count == 0
                          ? l10n.filters
                          : l10n.filtersActive(_filters.count),
                      outlined: _filters.count == 0,
                      onPressed: _chooseFilters,
                    ),
                  ],
                ),
                if (_filters.count > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _describe(l10n, state, _filters),
                          style: TextStyle(color: c.textMuted, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _filters = const HistoryFilters()),
                        child: Text(l10n.clearFilters),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      l10n.noExpensesForFilters,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textMuted),
                    ),
                  )
                else
                  for (final day in _byDay(expenses))
                    _DayGroup(day: day.$1, expenses: day.$2),
              ],
            );
          },
        ),
      ),
    );
  }

  /// "Jedzenie · Ann · wspólne": the filters in words.
  static String _describe(
    AppLocalizations l10n,
    BudgetState state,
    HistoryFilters f,
  ) {
    String? member(String? id) =>
        state.members.where((m) => m.userId == id).firstOrNull?.displayName;
    return [
      if (f.envelopeId != null) state.envelopeById(f.envelopeId!)?.name ?? '',
      if (f.authorId != null) l10n.byAuthor(member(f.authorId) ?? ''),
      if (f.forWhom == 'shared') l10n.forWhomShared,
      if (f.forWhom != null && f.forWhom != 'shared')
        l10n.forMember(member(f.forWhom) ?? ''),
    ].where((s) => s.isNotEmpty).join(' · ');
  }

  /// Newest first, as they come, grouped by the day they were spent on.
  static List<(DateTime, List<Expense>)> _byDay(List<Expense> expenses) {
    final days = <(DateTime, List<Expense>)>[];
    for (final x in expenses) {
      final local = x.spentAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (days.isEmpty || days.last.$1 != day) days.add((day, []));
      days.last.$2.add(x);
    }
    return days;
  }
}

/// One day: its name and total, then its expenses in one card.
class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.expenses});
  final DateTime day;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final name = day == today
        ? l10n.today
        : day == today.subtract(const Duration(days: 1))
        ? l10n.yesterday
        : DateFormat('EEEE, d MMMM', 'pl').format(day);
    final total = expenses.fold(0, (sum, x) => sum + x.amountMinor);
    final label = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: c.textMuted,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              children: [
                Expanded(child: Text(name, style: label)),
                Text(formatMinor(total), style: label),
              ],
            ),
          ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < expenses.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 38, color: c.border),
                  _ExpenseLine(expense: expenses[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseLine extends StatelessWidget {
  const _ExpenseLine({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.read<BudgetState>();
    final envelope = state.envelopeById(expense.envelopeId);
    final details = [
      if (expense.title != null) envelope?.name ?? '',
      _time.format(expense.spentAt.toLocal()),
      if (state.members.length > 1) expense.authorName,
      if (expense.forWhom == ForWhom.shared) l10n.forWhomShared,
      if (expense.forWhomName != null) l10n.forMember(expense.forWhomName!),
      if (expense.estimated) l10n.estimated,
    ].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: expense)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CategoryDot(envelope?.displayColor ?? Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title ?? envelope?.name ?? l10n.expense,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  Text(details, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatMinor(expense.amountMinor),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: expense.estimated ? c.estimate : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Envelope, author and for whom, chosen together and applied at once.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final HistoryFilters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _envelopeId = widget.initial.envelopeId;
  late String? _authorId = widget.initial.authorId;
  late String? _forWhom = widget.initial.forWhom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final members = state.members;
    final title = Theme.of(context).textTheme.titleSmall;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.filters, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(l10n.envelope, style: title),
            const SizedBox(height: 8),
            ChipWrap(
              children: [
                PillChip(
                  label: l10n.allEnvelopes,
                  selected: _envelopeId == null,
                  onTap: () => setState(() => _envelopeId = null),
                ),
                for (final e in state.envelopes)
                  PillChip(
                    label: e.name,
                    selected: _envelopeId == e.id,
                    onTap: () => setState(() => _envelopeId = e.id),
                  ),
              ],
            ),
            if (members.length > 1) ...[
              const SizedBox(height: 16),
              Text(l10n.author, style: title),
              const SizedBox(height: 8),
              ChipWrap(
                children: [
                  PillChip(
                    label: l10n.anyAuthor,
                    selected: _authorId == null,
                    onTap: () => setState(() => _authorId = null),
                  ),
                  for (final m in members)
                    PillChip(
                      label: m.displayName,
                      selected: _authorId == m.userId,
                      onTap: () => setState(() => _authorId = m.userId),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.forWhom, style: title),
              const SizedBox(height: 8),
              ChipWrap(
                children: [
                  PillChip(
                    label: l10n.forAnybody,
                    selected: _forWhom == null,
                    onTap: () => setState(() => _forWhom = null),
                  ),
                  PillChip(
                    label: l10n.forWhomShared,
                    selected: _forWhom == 'shared',
                    onTap: () => setState(() => _forWhom = 'shared'),
                  ),
                  for (final m in members)
                    PillChip(
                      label: m.displayName,
                      selected: _forWhom == m.userId,
                      onTap: () => setState(() => _forWhom = m.userId),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: l10n.showResults,
              onPressed: () => Navigator.of(context).pop(
                HistoryFilters(
                  envelopeId: _envelopeId,
                  authorId: _authorId,
                  forWhom: _forWhom,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
