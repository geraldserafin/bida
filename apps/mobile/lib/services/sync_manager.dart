import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/planner_repository.dart';
import 'crypto_service.dart';
import 'github_sync_service.dart';

/// Non-secret sync configuration, for display in Settings.
class SyncSettings {
  final String owner;
  final String repo;
  final String path;
  final DateTime? lastSync;

  const SyncSettings({
    required this.owner,
    required this.repo,
    required this.path,
    this.lastSync,
  });

  String get repoLabel => '$owner/$repo';
}

/// A decrypted, parsed cloud backup ready to apply, paired with row counts for
/// both the remote copy and the current local data so the user can review the
/// destructive replace before confirming.
class RestorePreview {
  final Map<String, Object?> export;
  final int remotePeriods;
  final int remoteExpenses;
  final int localPeriods;
  final int localExpenses;
  final DateTime? exportedAt;

  const RestorePreview({
    required this.export,
    required this.remotePeriods,
    required this.remoteExpenses,
    required this.localPeriods,
    required this.localExpenses,
    this.exportedAt,
  });
}

/// Orchestrates encrypted sync: export → encrypt → push, and pull → decrypt →
/// import. Credentials (GitHub token + passphrase) live in secure storage and
/// never touch the database or git history.
class SyncManager {
  static const _kToken = 'gh_token';
  static const _kOwner = 'gh_owner';
  static const _kRepo = 'gh_repo';
  static const _kPath = 'gh_path';
  static const _kPassphrase = 'gh_passphrase';
  static const _kLastSync = 'gh_last_sync';

  final PlannerRepository _repo;
  final CryptoService _crypto;
  final GitHubSyncService _github;
  final FlutterSecureStorage _storage;

  SyncManager({
    PlannerRepository? repository,
    CryptoService? crypto,
    GitHubSyncService? github,
    FlutterSecureStorage? storage,
  }) : _repo = repository ?? PlannerRepository(),
       _crypto = crypto ?? CryptoService(),
       _github = github ?? GitHubSyncService(),
       _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isConfigured() async =>
      (await _storage.read(key: _kToken)) != null;

  Future<void> saveConfig({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required String passphrase,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kOwner, value: owner);
    await _storage.write(key: _kRepo, value: repo);
    await _storage.write(key: _kPath, value: path.isEmpty ? 'data.enc' : path);
    await _storage.write(key: _kPassphrase, value: passphrase);
  }

  Future<void> disconnect() async {
    for (final key in [
      _kToken,
      _kOwner,
      _kRepo,
      _kPath,
      _kPassphrase,
      _kLastSync,
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<SyncSettings?> loadSettings() async {
    if (!await isConfigured()) return null;
    final lastSyncRaw = await _storage.read(key: _kLastSync);
    return SyncSettings(
      owner: await _storage.read(key: _kOwner) ?? '',
      repo: await _storage.read(key: _kRepo) ?? '',
      path: await _storage.read(key: _kPath) ?? 'data.enc',
      lastSync: lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw),
    );
  }

  Future<({GitHubConfig config, String passphrase})> _load() async {
    return (
      config: GitHubConfig(
        token: (await _storage.read(key: _kToken))!,
        owner: (await _storage.read(key: _kOwner))!,
        repo: (await _storage.read(key: _kRepo))!,
        path: await _storage.read(key: _kPath) ?? 'data.enc',
      ),
      passphrase: (await _storage.read(key: _kPassphrase))!,
    );
  }

  /// Exports the database, encrypts it, and pushes it to GitHub
  /// (last-write-wins: overwrites the remote copy).
  Future<void> push() async {
    final creds = await _load();
    final plaintext = jsonEncode(await _repo.exportData());
    final envelope = _crypto.encryptToEnvelope(plaintext, creds.passphrase);

    final existing = await _github.getFile(creds.config);
    await _github.putFile(creds.config, envelope, sha: existing?.sha);

    await _stampLastSync();
  }

  /// Fetches the remote blob and decrypts it *without* touching local data,
  /// returning a preview (remote vs. local row counts) so the caller can
  /// confirm the destructive replace. Returns null if there's nothing on the
  /// remote yet. Throws [DecryptionException] on a wrong passphrase or a
  /// corrupted/unreadable backup — local data stays intact in that case.
  Future<RestorePreview?> prepareRestore() async {
    final creds = await _load();
    final remote = await _github.getFile(creds.config);
    if (remote == null) return null;

    final plaintext = _crypto.decryptFromEnvelope(
      remote.content,
      creds.passphrase,
    );

    final Map<String, Object?> export;
    try {
      export = (jsonDecode(plaintext) as Map).cast<String, Object?>();
      // The backup must carry a data map, or it isn't safe to import.
      if (export['data'] is! Map) throw const FormatException('no data');
    } catch (_) {
      throw const DecryptionException();
    }

    final local = await _repo.exportData();
    final exportedAtRaw = export['exportedAt'];
    return RestorePreview(
      export: export,
      remotePeriods: _rowCount(export, 'periods'),
      remoteExpenses: _rowCount(export, 'expenses'),
      localPeriods: _rowCount(local, 'periods'),
      localExpenses: _rowCount(local, 'expenses'),
      exportedAt: exportedAtRaw is String
          ? DateTime.tryParse(exportedAtRaw)
          : null,
    );
  }

  /// Applies a previewed backup: first saves a local safety snapshot of the
  /// current data (recoverable if the restore turns out wrong), then replaces
  /// local data with the backup. Returns the snapshot file path.
  Future<String> applyRestore(RestorePreview preview) async {
    final snapshotPath = await _writeSnapshot();
    await _repo.importData(preview.export);
    await _stampLastSync();
    return snapshotPath;
  }

  /// Writes the current database to `pre_restore_backup.json` in the app
  /// documents directory before a restore overwrites it.
  Future<String> _writeSnapshot() async {
    final data = await _repo.exportData();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pre_restore_backup.json'));
    await file.writeAsString(jsonEncode(data));
    return file.path;
  }

  int _rowCount(Map<String, Object?> export, String table) {
    final data = export['data'];
    if (data is! Map) return 0;
    final rows = data[table];
    return rows is List ? rows.length : 0;
  }

  Future<void> _stampLastSync() =>
      _storage.write(key: _kLastSync, value: DateTime.now().toIso8601String());
}
