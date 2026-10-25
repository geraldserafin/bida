import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../data/money.dart';
import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/amounts.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';

/// Puts money into an envelope, or takes it back out ([takeBack]). Asks for
/// the envelope unless [envelopeId] is given, then for how much and when.
/// Returns whether something was saved.
Future<bool> showFundSheet(
  BuildContext context, {
  String? envelopeId,
  bool takeBack = false,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FundSheet(envelopeId: envelopeId, takeBack: takeBack),
  );
  return saved ?? false;
}

class _FundSheet extends StatefulWidget {
  const _FundSheet({this.envelopeId, required this.takeBack});

  final String? envelopeId;
  final bool takeBack;

  @override
  State<_FundSheet> createState() => _FundSheetState();
}

class _FundSheetState extends State<_FundSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String? _envelopeId = widget.envelopeId;
  late bool _takeBack = widget.takeBack;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = l10n.enterAmount);
      return;
    }
    final envelopeId = _envelopeId;
    if (envelopeId == null) {
      setState(() => _error = l10n.pickEnvelope);
      return;
    }
    setState(() => _saving = true);
    final state = context.read<PlannerState>();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    try {
      await state.saveAllocation(
        Allocation(
          envelopeId: envelopeId,
          amount: _takeBack ? -amount : amount,
          madeOn: DateTime(_date.year, _date.month, _date.day),
          note: note,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.tag == 'NotEnoughMoney'
            ? l10n.notEnoughMoney(
                formatZloty(fromMinor(error.availableMinor ?? 0)),
              )
            : apiErrorMessage(l10n, error);
      });
    }
  }

  /// What the user can still move, in words.
  String? _caption(AppLocalizations l10n, PlannerState state) {
    final id = _envelopeId;
    if (id == null) return null;
    final progress = state.progressOf(id);
    if (progress == null) return null;
    if (_takeBack) return l10n.canTakeBack(formatZloty(progress.free));
    final parentId = progress.envelope.parentId;
    if (parentId == null) return l10n.poolCaption(formatZloty(state.pool));
    final parent = state.progressOf(parentId);
    if (parent == null) return null;
    return l10n.parentFreeCaption(
      parent.envelope.name,
      formatZloty(parent.free),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final caption = _caption(l10n, state);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _takeBack ? l10n.takeBack : l10n.allocate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.allocate)),
                ButtonSegment(value: true, label: Text(l10n.takeBack)),
              ],
              selected: {_takeBack},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() {
                _takeBack = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _envelopeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.envelope,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final top in state.topLevel) ...[
                  _item(top, ''),
                  for (final child in state.childrenOf(top.id!))
                    _item(child, '${top.name} › '),
                ],
              ],
              onChanged: (v) => setState(() {
                _envelopeId = v;
                _error = null;
              }),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  caption,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: 'zł',
                errorText: _error,
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(DateFormat.yMMMMd('pl').format(_date)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_takeBack ? l10n.takeBack : l10n.allocate),
            ),
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _item(Envelope envelope, String prefix) =>
      DropdownMenuItem(
        value: envelope.id,
        child: Row(
          children: [
            Icon(envelope.displayIcon, size: 18, color: envelope.displayColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$prefix${envelope.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
