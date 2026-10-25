import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/sync_manager.dart';
import '../../state/planner_state.dart';
import 'sync_setup_screen.dart';

/// Encrypted GitHub backup: set up, sync now, restore, disconnect.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final SyncManager _sync = SyncManager();
  bool _loading = true;
  bool _busy = false;
  SyncSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _sync.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _setUp() async {
    final configured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SyncSetupScreen(sync: _sync)),
    );
    if (configured == true) await _load();
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await _sync.push();
      await _load();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncComplete)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncFailed('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final planner = context.read<PlannerState>();

    // Step 1: fetch + decrypt the backup without touching local data, so we
    // can show the user exactly what will be replaced before they commit.
    setState(() => _busy = true);
    RestorePreview? preview;
    try {
      preview = await _sync.prepareRestore();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncFailed('$e'))));
      return;
    }
    if (mounted) setState(() => _busy = false);

    if (preview == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.nothingToRestore)));
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.restorePreviewCloud(
                preview!.remotePeriods,
                preview.remoteExpenses,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.restorePreviewLocal(
                preview.localPeriods,
                preview.localExpenses,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.restoreSnapshotNote,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Step 2: snapshot the current data, then apply the backup.
    setState(() => _busy = true);
    try {
      final snapshotPath = await _sync.applyRestore(preview);
      await planner.load();
      await _load();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.snapshotKept(snapshotPath))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncFailed('$e'))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    await _sync.disconnect();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backup)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: _buildBody(l10n)),
    );
  }

  List<Widget> _buildBody(AppLocalizations l10n) {
    final settings = _settings;
    if (settings == null) {
      return [
        ListTile(
          leading: const Icon(Icons.cloud_upload_outlined),
          title: Text(l10n.setUpSync),
          subtitle: Text(l10n.syncSubtitle),
          onTap: _setUp,
        ),
      ];
    }

    final lastSync = settings.lastSync == null
        ? l10n.neverSynced
        : l10n.lastSynced(
            DateFormat.yMMMd(
              'pl',
            ).add_Hm().format(settings.lastSync!.toLocal()),
          );

    return [
      ListTile(
        leading: const Icon(Icons.cloud_done_outlined),
        title: Text(settings.repoLabel),
        subtitle: Text(lastSync),
      ),
      if (_busy) const LinearProgressIndicator(),
      ListTile(
        leading: const Icon(Icons.cloud_upload_outlined),
        title: Text(l10n.syncNow),
        enabled: !_busy,
        onTap: _syncNow,
      ),
      ListTile(
        leading: const Icon(Icons.cloud_download_outlined),
        title: Text(l10n.restoreFromCloud),
        enabled: !_busy,
        onTap: _restore,
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.link_off),
        title: Text(l10n.disconnect),
        onTap: _disconnect,
      ),
    ];
  }
}
