import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/money_format.dart';
import '../../widgets/pill_chip.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/transaction_row.dart';
import '../add_expense/add_expense_screen.dart';

final _at = DateFormat('dd.MM, HH:mm');

/// The expenses of the household on screen (F10): newest first, filtered by
/// period, envelope, author and "for whom". The wallet has its own history.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _wholeHistory = false;
  String? _envelopeId;
  String? _authorId;
  String? _forWhom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    final household = state.household;
    if (household == null) return const SizedBox.shrink();
    final period = state.period;
    final members = state.members;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            TabTitle(l10n.history, trailing: household.name),
            const SizedBox(height: 12),
            ChipWrap(
              children: [
                PillChip(
                  label: l10n.thisPeriod,
                  selected: !_wholeHistory,
                  onTap: () => setState(() => _wholeHistory = false),
                ),
                PillChip(
                  label: l10n.allPeriods,
                  selected: _wholeHistory,
                  onTap: () => setState(() => _wholeHistory = true),
                ),
              ],
            ),
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
                      label: l10n.byAuthor(m.displayName),
                      selected: _authorId == m.userId,
                      onTap: () => setState(() => _authorId = m.userId),
                    ),
                ],
              ),
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
                      label: l10n.forMember(m.displayName),
                      selected: _forWhom == m.userId,
                      onTap: () => setState(() => _forWhom = m.userId),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            RemoteData<List<Expense>>(
              version: Object.hash(
                state.version,
                household.id,
                _wholeHistory,
                _envelopeId,
                _authorId,
                _forWhom,
                period?.id,
              ),
              load: () => state.repository.expenses(
                householdId: household.id,
                periodId: _wholeHistory ? null : period?.id,
                envelopeId: _envelopeId,
                authorId: _authorId,
                forWhom: _forWhom,
              ),
              builder: (context, expenses) => expenses.isEmpty
                  ? Text(l10n.noExpensesForFilters)
                  : Column(
                      children: [
                        for (final x in expenses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ExpenseRow(expense: x),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final envelope = state.envelopeById(expense.envelopeId);
    final details = [
      _at.format(expense.spentAt),
      envelope?.name ?? '',
      expense.authorName,
      if (expense.forWhom == ForWhom.shared) l10n.forWhomShared,
      if (expense.forWhomName != null) l10n.forMember(expense.forWhomName!),
    ].where((s) => s.isNotEmpty).join(' · ');
    return TransactionRow(
      color: envelope?.displayColor ?? Colors.blueGrey,
      title: expense.title ?? envelope?.name ?? l10n.expense,
      details: details,
      amount: formatMinor(expense.amountMinor),
      tone: expense.estimated ? AmountTone.estimate : AmountTone.normal,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: expense)),
      ),
    );
  }
}
