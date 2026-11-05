import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../widgets/pill_chip.dart';

/// "co miesiąc od 1.", "co 2 tygodnie", "ręcznie".
String cycleLabel(AppLocalizations l10n, Cycle cycle) => switch (cycle.kind) {
  CycleKind.monthly => l10n.cycleMonthlyFrom(cycle.day ?? 1),
  CycleKind.weeks => l10n.cycleEveryWeeks(cycle.weeks ?? 1),
  CycleKind.manual => l10n.cycleManual,
};

/// Picks how a household cuts time into periods (F24).
class CycleEditor extends StatelessWidget {
  const CycleEditor({super.key, required this.cycle, required this.onChanged});

  final Cycle cycle;
  final ValueChanged<Cycle> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChipWrap(
          children: [
            PillChip(
              label: l10n.cycleMonthly,
              selected: cycle.kind == CycleKind.monthly,
              onTap: () => onChanged(Cycle.monthly(cycle.day ?? 1)),
            ),
            PillChip(
              label: l10n.cycleWeeks,
              selected: cycle.kind == CycleKind.weeks,
              onTap: () => onChanged(
                Cycle(
                  kind: CycleKind.weeks,
                  weeks: cycle.weeks ?? 2,
                  anchorOn: cycle.anchorOn ?? DateTime.now(),
                ),
              ),
            ),
            PillChip(
              label: l10n.cycleManual,
              selected: cycle.kind == CycleKind.manual,
              onTap: () => onChanged(const Cycle(kind: CycleKind.manual)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (cycle.kind == CycleKind.monthly)
          DropdownButton<int>(
            value: cycle.day ?? 1,
            items: [
              for (var d = 1; d <= 31; d++)
                DropdownMenuItem(
                  value: d,
                  child: Text(l10n.cycleMonthlyFrom(d)),
                ),
            ],
            onChanged: (d) => onChanged(Cycle.monthly(d ?? 1)),
          ),
        if (cycle.kind == CycleKind.weeks)
          Row(
            children: [
              DropdownButton<int>(
                value: cycle.weeks ?? 1,
                items: [
                  for (var w = 1; w <= 8; w++)
                    DropdownMenuItem(
                      value: w,
                      child: Text(l10n.cycleEveryWeeks(w)),
                    ),
                ],
                onChanged: (w) => onChanged(
                  Cycle(
                    kind: CycleKind.weeks,
                    weeks: w,
                    anchorOn: cycle.anchorOn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: cycle.anchorOn ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    onChanged(
                      Cycle(
                        kind: CycleKind.weeks,
                        weeks: cycle.weeks,
                        anchorOn: picked,
                      ),
                    );
                  }
                },
                child: Text(
                  l10n.cycleFromDay(
                    DateFormat(
                      'd.MM.yyyy',
                    ).format(cycle.anchorOn ?? DateTime.now()),
                  ),
                ),
              ),
            ],
          ),
        if (cycle.kind == CycleKind.manual) Text(l10n.cycleManualHint),
      ],
    );
  }
}

Future<Cycle?> showCyclePicker(BuildContext context, Cycle initial) {
  var cycle = initial;
  final l10n = AppLocalizations.of(context);
  return showDialog<Cycle>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l10n.cycle),
        content: CycleEditor(
          cycle: cycle,
          onChanged: (c) => setState(() => cycle = c),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(cycle),
            child: Text(l10n.save),
          ),
        ],
      ),
    ),
  );
}
