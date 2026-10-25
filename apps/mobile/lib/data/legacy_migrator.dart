import 'dart:io';

import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'planner_repository.dart';

enum MigrationOutcome {
  /// There is no database from the offline version on this device.
  nothingToMigrate,

  /// The old database had no data, so it was just set aside.
  empty,

  /// The server already has data, so the old database was left alone.
  serverHasData,

  /// The old database could not be read, so nothing was changed.
  unreadable,

  /// The old data is on the server now.
  migrated,
}

/// Moves the data the offline version kept in a local SQLite database to the
/// server, once. After a successful move the database file is renamed, so it
/// is never uploaded twice and still exists as a backup.
class LegacyMigrator {
  LegacyMigrator(this._repository, {Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final PlannerRepository _repository;
  final Future<Directory> Function() _directory;

  static const databaseName = 'money_planner.db';
  static const migratedSuffix = '.migrated';

  /// Throws an `ApiException` when the server cannot be reached; the database
  /// is kept in that case and the next launch tries again.
  Future<MigrationOutcome> migrateIfNeeded() async {
    final file = File(p.join((await _directory()).path, databaseName));
    if (!await file.exists()) return MigrationOutcome.nothingToMigrate;

    final api.LegacyBackup? backup;
    try {
      backup = await _read(file);
    } on Object catch (error, stack) {
      // A damaged file must not stop the app from starting.
      debugPrint('legacy database unreadable: $error\n$stack');
      return MigrationOutcome.unreadable;
    }
    if (backup == null) {
      await _setAside(file);
      return MigrationOutcome.empty;
    }
    // Restoring replaces everything on the server, so never do it over data.
    if (!await _repository.isEmpty()) return MigrationOutcome.serverHasData;

    await _repository.importLegacy(backup);
    await _setAside(file);
    return MigrationOutcome.migrated;
  }

  Future<void> _setAside(File file) =>
      file.rename('${file.path}$migratedSuffix');

  /// The rows of every table, or null when there are none at all.
  Future<api.LegacyBackup?> _read(File file) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final db = await openReadOnlyDatabase(file.path);
    try {
      final periods = await db.query('periods');
      final categories = await db.query('categories');
      final rules = await db.query('recurring_rules');
      final splits = await db.query('splits');
      final expenses = await db.query('expenses');
      if ([
        periods,
        categories,
        rules,
        splits,
        expenses,
      ].every((rows) => rows.isEmpty)) {
        return null;
      }
      return api.LegacyBackup(
        version: 1,
        data: api.LegacyData(
          periods: [
            for (final r in periods)
              api.LegacyPeriod(
                id: r['id'] as int,
                name: r['name'] as String,
                startDate: r['start_date'] as String,
                endDate: r['end_date'] as String,
                income: r['income'] as num,
              ),
          ],
          categories: [
            for (final r in categories)
              api.LegacyCategory(
                id: r['id'] as int,
                name: r['name'] as String,
                color: r['color'] as String,
                icon: r['icon'] as String?,
              ),
          ],
          recurringRules: [
            for (final r in rules)
              api.LegacyRecurringRule(
                id: r['id'] as int,
                categoryId: r['category_id'] as int,
                amount: r['amount'] as num,
                frequency: r['frequency'] as String,
                note: r['note'] as String?,
                active: r['active'] as int,
              ),
          ],
          splits: [
            for (final r in splits)
              api.LegacySplit(
                id: r['id'] as int,
                periodId: r['period_id'] as int,
                categoryId: r['category_id'] as int,
                plannedAmount: r['planned_amount'] as num,
              ),
          ],
          expenses: [
            for (final r in expenses)
              api.LegacyExpense(
                id: r['id'] as int,
                splitId: r['split_id'] as int,
                amount: r['amount'] as num,
                date: r['date'] as String,
                note: r['note'] as String?,
                recurringId: r['recurring_id'] as int?,
              ),
          ],
        ),
      );
    } finally {
      await db.close();
    }
  }
}
