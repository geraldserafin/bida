import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/budget_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/amounts.dart';
import '../../util/money_format.dart';
import '../../util/money_steps.dart';
import '../../widgets/app_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';

final _day = DateFormat('d.MM');

/// The plans of all envelopes of a period at once (F17, F19), with what is
/// left to plan worked out as the amounts are typed.
class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key, required this.summary});
  final PeriodSummary summary;

  static Key fieldKey(String envelopeId) => Key('plan-$envelopeId');

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late final List<EnvelopeFigures> _envelopes = [
    for (final e in widget.summary.envelopes)
      if (!e.archived) e,
  ];
  late final Map<String, TextEditingController> _fields = {
    for (final e in _envelopes)
      e.envelopeId: TextEditingController(
        text: e.planMinor == 0 ? '' : amountText(e.planMinor / 100),
      ),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  /// The typed plan; an empty field is no plan.
  int _typed(EnvelopeFigures e) =>
      ((parseAmount(_fields[e.envelopeId]!.text) ?? 0) * 100).round();

  /// Wolne pieniądze once the typed plans are in: the balance less what is
  /// still to spend of every plan.
  int get _free {
    var free = widget.summary.freeMinor;
    for (final e in _envelopes) {
      int rest(int plan) => plan > e.spentMinor ? plan - e.spentMinor : 0;
      free -= rest(_typed(e)) - rest(e.planMinor);
    }
    return free;
  }

  Future<void> _save() async {
    final state = context.read<BudgetState>();
    final navigator = Navigator.of(context);
    final changed = [
      for (final e in _envelopes)
        if (_typed(e) != e.planMinor) e,
    ];
    // the ones that go down first: they free money for the others
    changed.sort(
      (a, b) => (_typed(a) - a.planMinor).compareTo(_typed(b) - b.planMinor),
    );
    setState(() => _saving = true);
    var ok = true;
    for (final e in changed) {
      ok = await attemptMoney(
        context,
        () => state.repository.setPlan(
          widget.summary.period.id,
          e.envelopeId,
          _typed(e),
        ),
      );
      if (!ok || !mounted) break;
    }
    await state.refresh();
    if (!mounted) return;
    if (ok) {
      navigator.pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final period = widget.summary.period;
    final free = _free;
    return Scaffold(
      appBar: FormTopBar(
        title: l10n.editPlan,
        where:
            '${_day.format(period.startsOn)} – ${_day.format(period.endsOn)}',
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AppButton(
            label: l10n.savePlan,
            busy: _saving,
            onPressed: _save,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SurfaceCard(
            outline: free < 0 ? CardOutline.estimate : CardOutline.selected,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.freeMoneyLabel, style: theme.textTheme.bodySmall),
                Text(
                  formatMinor(free),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: free < 0 ? c.warning : c.accent,
                  ),
                ),
                Text(
                  free < 0
                      ? l10n.plansExceedBalance
                      : l10n.planBalanceOf(
                          formatMinor(widget.summary.balanceMinor),
                        ),
                  style: TextStyle(
                    color: free < 0 ? c.warning : c.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final e in _envelopes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    CategoryDot(e.envelope.displayColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: theme.textTheme.titleSmall),
                          Text(
                            [
                              l10n.spentAmount(formatMinor(e.spentMinor)),
                              if (e.recurringMinor > 0)
                                l10n.recurringInPlan(
                                  formatMinor(e.recurringMinor),
                                ),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        key: PlanEditorScreen.fieldKey(e.envelopeId),
                        controller: _fields[e.envelopeId],
                        enabled: period.isOpen && !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          hintText: '0',
                          suffixText: 'zł',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
