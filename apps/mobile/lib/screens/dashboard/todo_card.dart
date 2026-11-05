import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../util/money_format.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/surface_card.dart';

/// "Do załatwienia" (F34): what the app start could not do on its own, one
/// button per item instead of a row of dialogs.
class TodoCard extends StatelessWidget {
  const TodoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    if (state.todo.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.todoTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Badge(label: Text('${state.todo.length}')),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in state.todo)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TodoRow(item: item),
            ),
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.item});
  final TodoItem item;

  String _text(AppLocalizations l10n) {
    final what = item.title ?? '';
    final amount = formatMinor(item.amountMinor);
    return switch (item.kind) {
      TodoKind.incomeEstimate => l10n.todoIncomeEstimate(what, amount),
      TodoKind.transferNoMoney => l10n.todoTransferNoMoney(what, amount),
      TodoKind.expenseNotFit => l10n.todoExpenseNotFit(what, amount),
      TodoKind.expenseEstimate => l10n.todoExpenseEstimate(what, amount),
      TodoKind.expenseMissed => l10n.todoExpenseMissed(what, amount),
    };
  }

  String _action(AppLocalizations l10n) => switch (item.kind) {
    TodoKind.incomeEstimate ||
    TodoKind.expenseEstimate => l10n.todoConfirmAmount,
    TodoKind.transferNoMoney => l10n.todoTransfer,
    TodoKind.expenseNotFit || TodoKind.expenseMissed => l10n.todoAddExpense,
  };

  Future<void> _resolve(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final amount = await askAmount(
      context,
      title: _action(l10n),
      message: _text(l10n),
      initialMinor: item.amountMinor,
      action: l10n.todoDo,
    );
    if (amount == null || amount <= 0 || !context.mounted) return;
    final repo = state.repository;
    final bool done;
    if (item.kind == TodoKind.incomeEstimate) {
      done = await sendWithCorrection(
        context,
        state.households,
        (correction) => repo.resolveTodo(
          item.id,
          amountMinor: amount,
          correction: correction,
        ),
      );
    } else if (item.kind == TodoKind.transferNoMoney) {
      done = await attemptMoney(
        context,
        () => repo.resolveTodo(item.id, amountMinor: amount),
      );
    } else {
      done =
          await sendWithSteps(context, amount, (decision) async {
            await repo.resolveTodo(
              item.id,
              amountMinor: amount,
              decision: decision,
            );
            return true;
          }) ==
          true;
    }
    if (done) await state.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.read<BudgetState>();
    return SurfaceCard(
      outline: CardOutline.estimate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.householdName != null)
            Text(
              item.householdName!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textMuted),
            ),
          Text(_text(l10n)),
          const SizedBox(height: 10),
          Row(
            children: [
              SmallButton(
                label: _action(l10n),
                onPressed: () => _resolve(context),
              ),
              const SizedBox(width: 8),
              SmallButton(
                label: l10n.todoDismiss,
                outlined: true,
                onPressed: () => attemptMoney(
                  context,
                  () => state.change((repo) => repo.dismissTodo(item.id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
