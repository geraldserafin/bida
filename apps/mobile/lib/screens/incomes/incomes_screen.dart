import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/income.dart';
import '../../state/planner_state.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/remote_data.dart';
import 'income_sheet.dart';

/// Everything that came in, newest first. This is where the money enters the
/// app: it can then be put into envelopes.
class IncomesScreen extends StatefulWidget {
  const IncomesScreen({super.key});

  @override
  State<IncomesScreen> createState() => _IncomesScreenState();
}

class _IncomesScreenState extends State<IncomesScreen> {
  /// Bumped after a change so the list is fetched again.
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomes)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await showIncomeSheet(context)) setState(() => _version++);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addIncome),
      ),
      body: RemoteData<List<Income>>(
        version: _version,
        load: state.incomes,
        builder: (context, incomes) {
          if (incomes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noIncomes, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: incomes.length,
            itemBuilder: (context, i) => _IncomeTile(
              income: incomes[i],
              onChanged: () => setState(() => _version++),
            ),
          );
        },
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income, required this.onChanged});

  final Income income;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMd('pl').format(income.receivedOn);
    return ListTile(
      leading: Icon(Icons.south_west, color: scheme.primary),
      title: Text(
        formatZloty(income.amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        income.note == null || income.note!.isEmpty
            ? date
            : '$date · ${income.note}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.deleteIncome,
        onPressed: () => _delete(context),
      ),
      onTap: () async {
        if (await showIncomeSheet(context, existing: income)) onChanged();
      },
    );
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<PlannerState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteIncome),
        content: Text(l10n.deleteIncomeConfirm(formatZloty(income.amount))),
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
    final deleted = await attempt(
      context,
      () => state.deleteIncome(income.id!),
    );
    if (deleted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.incomeDeleted)));
      onChanged();
    }
  }
}
