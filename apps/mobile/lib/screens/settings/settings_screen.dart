import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/csv_exporter.dart';
import '../../services/csv_importer.dart';
import '../../state/app_settings.dart';
import '../../state/planner_state.dart';
import '../categories/categories_screen.dart';
import 'backup_screen.dart';

/// App settings: general, appearance, security, data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _auth.hasPin();
    final available = await _auth.canUseBiometrics();
    final enabled = await _auth.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loading = false;
    });
  }

  // ---- security -------------------------------------------------------------

  Future<void> _toggleLock(bool enable) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (enable) {
      final pin = await _showPinSetup();
      if (pin == null) return;
      await _auth.setPin(pin);
      messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
    } else {
      await _auth.clearPin();
      messenger.showSnackBar(SnackBar(content: Text(l10n.lockDisabled)));
    }
    await _load();
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pin = await _showPinSetup();
    if (pin == null) return;
    await _auth.setPin(pin);
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
  }

  Future<void> _toggleBiometric(bool enabled) async {
    await _auth.setBiometricEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<String?> _showPinSetup() => showDialog<String>(
    context: context,
    builder: (_) => const _PinSetupDialog(),
  );

  // ---- data -----------------------------------------------------------------

  static const _csvTypeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String path;
    try {
      final location = await getSaveLocation(
        suggestedName: 'plning_export.csv',
        acceptedTypeGroups: const [_csvTypeGroup],
      );
      if (location == null) return; // user cancelled the dialog
      path = await CsvExporter().exportToPath(location.path);
    } on UnimplementedError {
      // Platform without a save dialog (e.g. Android): use the default file.
      path = await CsvExporter().exportToFile();
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.csvExported(path))));
  }

  Future<void> _importCsv() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final planner = context.read<PlannerState>();

    final file = await openFile(acceptedTypeGroups: const [_csvTypeGroup]);
    if (file == null) return; // user cancelled the dialog

    final result = await CsvImporter().importFromPath(file.path);
    if (result == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noExportFound)));
      return;
    }
    await planner.load();
    final message =
        l10n.importResult(result.imported) +
        (result.skipped > 0 ? l10n.importSkipped(result.skipped) : '');
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- Appearance ----
          _SectionHeader(l10n.appearance),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.theme,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(l10n.themeDark),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(l10n.themeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(l10n.themeAuto),
                          ),
                        ],
                        selected: {settings.themeMode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            settings.setThemeMode(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ---- Security ----
          _SectionHeader(l10n.security),
          _Group(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: Text(l10n.appLock),
                subtitle: Text(l10n.appLockSubtitle),
                value: _hasPin,
                onChanged: _toggleLock,
              ),
              if (_hasPin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(l10n.changePin),
                  onTap: _changePin,
                ),
              ],
              if (_hasPin && _biometricAvailable) ...[
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(l10n.biometricUnlock),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ],
            ],
          ),

          // ---- Data ----
          _SectionHeader(l10n.dataSection),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: Text(l10n.exportCsv),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportCsv,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: Text(l10n.importCsv),
                trailing: const Icon(Icons.chevron_right),
                onTap: _importCsv,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text(l10n.backup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.grid_view_outlined),
                title: Text(l10n.manageCategories),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _Group(
            children: [
              ListTile(
                title: Text(l10n.about),
                trailing: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A card that groups related rows, like the design's rounded sections.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text;
    if (pin.length < 6) {
      setState(() => _error = l10n.pinTooShort);
      return;
    }
    if (pin != _confirmController.text) {
      setState(() => _error = l10n.pinsDontMatch);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.setPin),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.enterPin,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.confirmPin,
              errorText: _error,
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
