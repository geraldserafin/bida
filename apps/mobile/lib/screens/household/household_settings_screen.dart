import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../util/money_steps.dart';
import '../../widgets/screen_header.dart';
import '../setup_wizard/cycle_picker.dart';

final _day = DateFormat('d.MM.yyyy');

/// What owners change about a household (F06, F24): its name, its cycle of
/// periods, the end of the current period; and deleting it.
class HouseholdSettingsScreen extends StatelessWidget {
  const HouseholdSettingsScreen({super.key, required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<BudgetState>();
    final h =
        state.households.where((x) => x.id == household.id).firstOrNull ??
        household;
    final owner = h.isOwner;
    return Scaffold(
      appBar: FormTopBar(title: l10n.householdSettings, where: h.name),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.name),
            subtitle: Text(h.name),
            enabled: owner,
            onTap: () => _rename(context, h),
          ),
          ListTile(
            title: Text(l10n.cycle),
            subtitle: Text(cycleLabel(l10n, h.cycle)),
            enabled: owner,
            onTap: () async {
              final cycle = await showCyclePicker(context, h.cycle);
              if (cycle == null || !context.mounted) return;
              await attemptMoney(
                context,
                () => state.change((repo) => repo.setCycle(h.id, cycle)),
              );
            },
          ),
          ListTile(
            title: Text(l10n.currentPeriodEnd),
            subtitle: Text(_day.format(h.current.endsOn)),
            enabled: owner,
            onTap: () async {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final last =
                  h.next?.endsOn.subtract(const Duration(days: 1)) ??
                  DateTime(now.year + 2);
              final picked = await showDatePicker(
                context: context,
                initialDate: h.current.endsOn.isBefore(today)
                    ? today
                    : h.current.endsOn,
                firstDate: today,
                lastDate: last,
                helpText: l10n.currentPeriodEndHint,
              );
              if (picked == null || !context.mounted) return;
              await attemptMoney(
                context,
                () => state.change(
                  (repo) => repo.setPeriodEnd(h.current.id, picked),
                ),
              );
            },
          ),
          const Divider(),
          if (owner)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deleteHousehold),
              subtitle: Text(l10n.deleteHouseholdHint),
              onTap: () async {
                final yes = await confirmDanger(
                  context,
                  title: l10n.deleteHousehold,
                  body: l10n.deleteHouseholdConfirm(h.name),
                  action: l10n.delete,
                );
                if (!yes || !context.mounted) return;
                final navigator = Navigator.of(context);
                final ok = await attemptMoney(
                  context,
                  () => state.deleteHousehold(h.id),
                );
                if (ok) navigator.pop();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, Household h) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final name = TextEditingController(text: h.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.name),
        content: TextField(controller: name, autofocus: true, maxLength: 50),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (ok != true || text.isEmpty || !context.mounted) return;
    await attemptMoney(
      context,
      () => state.change((repo) => repo.renameHousehold(h.id, text)),
    );
  }
}
