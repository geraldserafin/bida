import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../util/money_steps.dart';
import '../../widgets/remote_data.dart';
import '../../widgets/screen_header.dart';

final _at = DateFormat('dd.MM, HH:mm');

/// Who did what in the open periods (F37), with an undo for those who may
/// make that change. Entries of a closed period are gone.
class LogScreen extends StatelessWidget {
  const LogScreen({super.key, required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final state = context.watch<BudgetState>();
    return Scaffold(
      appBar: FormTopBar(title: l10n.changeLog, where: household.name),
      body: RemoteData<List<LogEntry>>(
        version: state.version,
        load: () => state.repository.log(household.id),
        builder: (context, entries) => entries.isEmpty
            ? Center(child: Text(l10n.logEmpty))
            : ListView(
                children: [
                  for (final e in entries)
                    ListTile(
                      title: Text(
                        e.summary,
                        style: TextStyle(
                          decoration: e.undone
                              ? TextDecoration.lineThrough
                              : null,
                          color: e.undone ? c.textMuted : null,
                        ),
                      ),
                      subtitle: Text(
                        '${e.userName} · ${_at.format(e.createdAt)}',
                      ),
                      trailing: e.canUndo
                          ? TextButton(
                              onPressed: () => attemptMoney(
                                context,
                                () => state.change((repo) => repo.undo(e.id)),
                              ),
                              child: Text(l10n.undo),
                            )
                          : null,
                    ),
                ],
              ),
      ),
    );
  }
}
