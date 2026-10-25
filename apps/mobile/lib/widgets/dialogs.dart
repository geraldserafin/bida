import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Asks to confirm something. True when the user agrees.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks for one line of text. Null when dismissed, never an empty string.
Future<String?> textDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  String initial = '',
  String? hint,
  TextInputType? keyboardType,
  String? Function(String value)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      label: label,
      action: action,
      initial: initial,
      hint: hint,
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.action,
    required this.initial,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final String title;
  final String label;
  final String action;
  final String initial;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String value)? validator;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.hint,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return l10n.enterName;
            return widget.validator?.call(text);
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.action)),
      ],
    );
  }
}
