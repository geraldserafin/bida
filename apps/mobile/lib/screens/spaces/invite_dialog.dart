import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';

/// Who to invite and in which role. Null when dismissed.
Future<({String email, SpaceRole role})?> showInviteDialog(
  BuildContext context,
) {
  return showDialog<({String email, SpaceRole role})>(
    context: context,
    builder: (_) => const _InviteDialog(),
  );
}

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class _InviteDialog extends StatefulWidget {
  const _InviteDialog();

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SpaceRole _role = SpaceRole.member;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((email: _controller.text.trim(), role: _role));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.inviteByEmail),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailAddress,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => _emailPattern.hasMatch((value ?? '').trim())
                  ? null
                  : l10n.enterValidEmail,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(l10n.role, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<SpaceRole>(
              segments: [
                ButtonSegment(
                  value: SpaceRole.member,
                  label: Text(l10n.roleMember),
                ),
                ButtonSegment(
                  value: SpaceRole.owner,
                  label: Text(l10n.roleOwner),
                ),
              ],
              selected: {_role},
              showSelectedIcon: false,
              onSelectionChanged: (selected) =>
                  setState(() => _role = selected.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.invite)),
      ],
    );
  }
}
