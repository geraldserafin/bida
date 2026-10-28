import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/data/legacy_migrator.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/fake_backend.dart';

/// The schema of the offline version, as it created it.
const _schema = [
  '''CREATE TABLE periods (
       id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
       start_date TEXT NOT NULL, end_date TEXT NOT NULL,
       income REAL NOT NULL DEFAULT 0)''',
  '''CREATE TABLE categories (
       id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
       color TEXT NOT NULL, icon TEXT)''',
  '''CREATE TABLE splits (
       id INTEGER PRIMARY KEY AUTOINCREMENT, period_id INTEGER NOT NULL,
       category_id INTEGER NOT NULL, planned_amount REAL NOT NULL DEFAULT 0)''',
  '''CREATE TABLE recurring_rules (
       id INTEGER PRIMARY KEY AUTOINCREMENT, category_id INTEGER NOT NULL,
       amount REAL NOT NULL, frequency TEXT NOT NULL, note TEXT,
       active INTEGER NOT NULL DEFAULT 1)''',
  '''CREATE TABLE expenses (
       id INTEGER PRIMARY KEY AUTOINCREMENT, split_id INTEGER NOT NULL,
       amount REAL NOT NULL, date TEXT NOT NULL, note TEXT, recurring_id INTEGER)''',
];

void main() {
  late Directory directory;
  late FakeBackend backend;
  late LegacyMigrator migrator;

  File database() => File(p.join(directory.path, LegacyMigrator.databaseName));

  /// Creates the old database, filled by [fill] unless it should stay empty.
  Future<void> createDatabase({
    Future<void> Function(Database db)? fill,
  }) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(database().path);
    for (final statement in _schema) {
      await db.execute(statement);
    }
    await fill?.call(db);
    await db.close();
  }

  Future<void> oneOfEverything(Database db) async {
    await db.insert('categories', {
      'name': 'Food',
      'color': '#22C55E',
      'icon': 'restaurant',
    });
    await db.insert('periods', {
      'name': 'July',
      'start_date': '2026-07-01T00:00:00.000',
      'end_date': '2026-07-31T00:00:00.000',
      'income': 5000.5,
    });
    await db.insert('splits', {
      'period_id': 1,
      'category_id': 1,
      'planned_amount': 1200.25,
    });
    await db.insert('recurring_rules', {
      'category_id': 1,
      'amount': 99.99,
      'frequency': 'monthly',
      'note': 'Gym',
      'active': 1,
    });
    await db.insert('expenses', {
      'split_id': 1,
      'amount': 45.99,
      'date': '2026-07-03T10:30:00.000',
      'note': 'Biedronka',
      'recurring_id': 1,
    });
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('legacy_migrator');
    backend = FakeBackend();
    migrator = LegacyMigrator(
      backend.repository(),
      directory: () async => directory,
    );
  });

  tearDown(() => directory.delete(recursive: true));

  void serverIsEmpty() {
    backend
      ..on('GET /envelopes', (_) => const Reply([]))
      ..on('GET /incomes', (_) => const Reply([]));
  }

  test('without an old database there is nothing to do', () async {
    expect(await migrator.migrateIfNeeded(), MigrationOutcome.nothingToMigrate);
    expect(backend.requests, isEmpty);
  });

  test('moves the data to the server and sets the file aside', () async {
    await createDatabase(fill: oneOfEverything);
    serverIsEmpty();
    backend.on(
      'POST /import/legacy',
      (_) => const Reply({
        'envelopes': 1,
        'allocations': 1,
        'incomes': 1,
        'expenses': 1,
        'recurringRules': 1,
        'recurringIncomes': 0,
        'allocationRules': 0,
      }),
    );

    expect(await migrator.migrateIfNeeded(), MigrationOutcome.migrated);

    final body = backend.sent('POST /import/legacy').single.body as Map;
    expect(body['backup'], {
      'version': 1,
      'data': {
        'periods': [
          {
            'id': 1,
            'name': 'July',
            'start_date': '2026-07-01T00:00:00.000',
            'end_date': '2026-07-31T00:00:00.000',
            'income': 5000.5,
          },
        ],
        'categories': [
          {'id': 1, 'name': 'Food', 'color': '#22C55E', 'icon': 'restaurant'},
        ],
        'recurring_rules': [
          {
            'id': 1,
            'category_id': 1,
            'amount': 99.99,
            'frequency': 'monthly',
            'note': 'Gym',
            'active': 1,
          },
        ],
        'splits': [
          {
            'id': 1,
            'period_id': 1,
            'category_id': 1,
            'planned_amount': 1200.25,
          },
        ],
        'expenses': [
          {
            'id': 1,
            'split_id': 1,
            'amount': 45.99,
            'date': '2026-07-03T10:30:00.000',
            'note': 'Biedronka',
            'recurring_id': 1,
          },
        ],
      },
    });
    // set aside, so the next launch does not upload it again
    expect(database().existsSync(), isFalse);
    expect(File('${database().path}.migrated').existsSync(), isTrue);

    expect(await migrator.migrateIfNeeded(), MigrationOutcome.nothingToMigrate);
  });

  test('never overwrites data the server already has', () async {
    await createDatabase(fill: oneOfEverything);
    backend
      ..on('GET /envelopes', (_) => Reply([envelopeJson('e1', 'Food')]))
      ..on('GET /incomes', (_) => const Reply([]));

    expect(await migrator.migrateIfNeeded(), MigrationOutcome.serverHasData);

    expect(backend.sent('POST /import/legacy'), isEmpty);
    expect(database().existsSync(), isTrue); // kept, nothing was lost
  });

  test(
    'an unreachable server keeps the database for the next launch',
    () async {
      await createDatabase(fill: oneOfEverything);
      backend.on('GET /envelopes', (_) => const Reply.unreachable());

      await expectLater(
        migrator.migrateIfNeeded(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.unreachable,
          ),
        ),
      );

      expect(database().existsSync(), isTrue);
    },
  );

  test('a rejected import keeps the database too', () async {
    await createDatabase(fill: oneOfEverything);
    serverIsEmpty();
    backend.on(
      'POST /import/legacy',
      (_) => Reply.error(422, 'InvalidImport', {'reason': 'x'}),
    );

    await expectLater(migrator.migrateIfNeeded(), throwsA(isA<ApiException>()));

    expect(database().existsSync(), isTrue);
  });

  test('an old database without data is just set aside', () async {
    await createDatabase();

    expect(await migrator.migrateIfNeeded(), MigrationOutcome.empty);

    expect(backend.requests, isEmpty);
    expect(File('${database().path}.migrated').existsSync(), isTrue);
  });

  test('a damaged file does not stop the app', () async {
    await database().writeAsString('this is not a database');

    expect(await migrator.migrateIfNeeded(), MigrationOutcome.unreadable);

    expect(backend.requests, isEmpty);
    expect(database().existsSync(), isTrue);
  });
}
