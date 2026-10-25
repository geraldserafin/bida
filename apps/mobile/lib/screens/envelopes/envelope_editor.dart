import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/envelope.dart';
import '../../state/planner_state.dart';
import '../../theme/envelope_visuals.dart';

/// Modal editor for creating or editing an [Envelope]: name, icon and color,
/// and for a new one also whether it is a sub-envelope.
///
/// Returns the edited [Envelope] (id and parent preserved when editing) or
/// null if dismissed. Persistence is left to the caller. [parentId] makes a
/// new envelope a sub-envelope of that one from the start.
Future<Envelope?> showEnvelopeEditor(
  BuildContext context, {
  Envelope? existing,
  String? parentId,
}) {
  return showModalBottomSheet<Envelope>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _EnvelopeEditorSheet(existing: existing, parentId: parentId),
  );
}

class _EnvelopeEditorSheet extends StatefulWidget {
  const _EnvelopeEditorSheet({this.existing, this.parentId});
  final Envelope? existing;
  final String? parentId;

  @override
  State<_EnvelopeEditorSheet> createState() => _EnvelopeEditorSheetState();
}

class _EnvelopeEditorSheetState extends State<_EnvelopeEditorSheet> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late String _colorHex;
  String? _parentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _iconKey = widget.existing?.icon ?? envelopeIcons.keys.first;
    _colorHex = widget.existing?.color ?? envelopeColorPalette.first;
    _parentId = widget.existing?.parentId ?? widget.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color get _color {
    final hex = 'FF${_colorHex.replaceFirst('#', '')}';
    return Color(int.parse(hex, radix: 16));
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      Envelope(
        id: widget.existing?.id,
        parentId: _parentId,
        name: name,
        color: _colorHex,
        icon: _iconKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? l10n.newEnvelope : l10n.editEnvelope,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (widget.existing == null) ...[
              _ParentPicker(
                selected: _parentId,
                onSelected: (id) => setState(() => _parentId = id),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.name,
                prefixIcon: Icon(envelopeIcons[_iconKey], color: _color),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Text(l10n.icon, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _IconPicker(
              selected: _iconKey,
              color: _color,
              onSelected: (key) => setState(() => _iconKey = key),
            ),
            const SizedBox(height: 20),
            Text(l10n.color, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _colorHex,
              onSelected: (hex) => setState(() => _colorHex = hex),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in envelopeIcons.entries)
          InkWell(
            onTap: () => onSelected(entry.key),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.key == selected
                    ? color.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.key == selected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                entry.value,
                color: entry.key == selected ? color : scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final hex in envelopeColorPalette)
          GestureDetector(
            onTap: () => onSelected(hex),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(
                  int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hex == selected
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: hex == selected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Whether a new envelope is a top-level one or sits inside another.
class _ParentPicker extends StatelessWidget {
  const _ParentPicker({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parents = context.read<PlannerState>().topLevel;
    if (parents.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String?>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.parentEnvelope,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(l10n.noParent)),
        for (final e in parents)
          DropdownMenuItem<String?>(
            value: e.id,
            child: Row(
              children: [
                Icon(e.displayIcon, size: 18, color: e.displayColor),
                const SizedBox(width: 8),
                Flexible(child: Text(e.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: onSelected,
    );
  }
}
