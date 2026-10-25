import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the SQLite connection and schema for the whole app.
///
/// Uses the standard `sqflite` plugin on Android/iOS and falls back to
/// `sqflite_common_ffi` on desktop (Windows/Linux/macOS) so the same code runs
/// everywhere during development.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'money_planner.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    // Desktop platforms need the FFI factory initialised before use.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE periods (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        start_date TEXT    NOT NULL,
        end_date   TEXT    NOT NULL,
        income     REAL    NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id    INTEGER PRIMARY KEY AUTOINCREMENT,
        name  TEXT    NOT NULL,
        color TEXT    NOT NULL,
        icon  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE splits (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        period_id      INTEGER NOT NULL,
        category_id    INTEGER NOT NULL,
        planned_amount REAL    NOT NULL DEFAULT 0,
        FOREIGN KEY (period_id)   REFERENCES periods (id)    ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_rules (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount      REAL    NOT NULL,
        frequency   TEXT    NOT NULL,
        note        TEXT,
        active      INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Expenses keep their split reference nullable-on-delete so historical
    // spending survives even when a split/category is removed mid-period.
    await db.execute('''
      CREATE TABLE expenses (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        split_id     INTEGER NOT NULL,
        amount       REAL    NOT NULL,
        date         TEXT    NOT NULL,
        note         TEXT,
        recurring_id INTEGER,
        FOREIGN KEY (split_id)     REFERENCES splits (id),
        FOREIGN KEY (recurring_id) REFERENCES recurring_rules (id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
