import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/sync_manager.dart';

/// Collects GitHub credentials + an encryption passphrase and stores them.
/// Pops with `true` once the config is saved.
class SyncSetupScreen extends StatefulWidget {
  const SyncSetupScreen({super.key, required this.sync});

  final SyncManager sync;

  @override
  State<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends State<SyncSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _owner = TextEditingController();
  final _repo = TextEditingController();
  final _path = TextEditingController(text: 'data.enc');
  final _passphrase = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _token.dispose();
    _owner.dispose();
    _repo.dispose();
    _path.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.sync.saveConfig(
      token: _token.text.trim(),
      owner: _owner.text.trim(),
      repo: _repo.text.trim(),
      path: _path.text.trim(),
      passphrase: _passphrase.text,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? '—' : null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setUpSync)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_token, l10n.githubToken, obscure: true),
            _field(_owner, l10n.repoOwner),
            _field(_repo, l10n.repoName),
            _field(_path, l10n.filePath, requiredField: false),
            _field(_passphrase, l10n.syncPassphrase, obscure: true),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _connect,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(l10n.connect),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool requiredField = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: requiredField ? _required : null,
      ),
    );
  }
}
