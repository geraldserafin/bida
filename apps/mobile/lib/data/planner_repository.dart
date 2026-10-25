import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/models.dart';
import '../models/category_progress.dart';
import '../models/period_summary.dart';
import 'database_helper.dart';

/// Single entry point for all persistence: periods, categories, splits and
/// expenses. Keeps SQL out of the UI/state layers.
class PlannerRepository {
  PlannerRepository({DatabaseHelper? helper})
    : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  Future<Database> get _db async => _helper.database;

  // ---------------------------------------------------------------- categories

  Future<List<Category>> getCategories() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await _db;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  Future<void> updateCategory(Category category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Whether a category is referenced by any split (in any period).
  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM splits WHERE category_id = ?',
      [categoryId],
    );
    return ((rows.first['n'] as int?) ?? 0) > 0;
  }

  Future<void> deleteCategory(int categoryId) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  // ------------------------------------------------------------------- periods

  Future<List<Period>> getPeriods() async {
    final db = await _db;
    final rows = await db.query('periods', orderBy: 'start_date DESC');
    return rows.map(Period.fromMap).toList();
  }

  /// The most recent period by start date, or null if none exist yet.
  Future<Period?> getCurrentPeriod() async {
    final db = await _db;
    final rows = await db.query(
      'periods',
      orderBy: 'start_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Period.fromMap(rows.first);
  }

  Future<int> insertPeriod(Period period) async {
    final db = await _db;
    return db.insert('periods', period.toMap()..remove('id'));
  }

  Future<void> updatePeriod(Period period) async {
    final db = await _db;
    await db.update(
      'periods',
      period.toMap(),
      where: 'id = ?',
      whereArgs: [period.id],
    );
  }

  /// Deletes a period along with its splits and their expenses, in a
  /// transaction (child-first so foreign keys stay satisfied).
  Future<void> deletePeriod(int periodId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.rawDelete(
        'DELETE FROM expenses WHERE split_id IN '
        '(SELECT id FROM splits WHERE period_id = ?)',
        [periodId],
      );
      await txn.delete('splits', where: 'period_id = ?', whereArgs: [periodId]);
      await txn.delete('periods', where: 'id = ?', whereArgs: [periodId]);
    });
  }

  // -------------------------------------------------------------------- splits

  Future<List<Split>> getSplitsForPeriod(int periodId) async {
    final db = await _db;
    final rows = await db.query(
      'splits',
      where: 'period_id = ?',
      whereArgs: [periodId],
    );
    return rows.map(Split.fromMap).toList();
  }

  Future<int> insertSplit(Split split) async {
    final db = await _db;
    return db.insert('splits', split.toMap()..remove('id'));
  }

  Future<void> updateSplit(Split split) async {
    final db = await _db;
    await db.update(
      'splits',
      split.toMap(),
      where: 'id = ?',
      whereArgs: [split.id],
    );
  }

  Future<void> deleteSplit(int splitId) async {
    final db = await _db;
    await db.delete('splits', where: 'id = ?', whereArgs: [splitId]);
  }

  /// The split for a category within a period, or null if none exists yet.
  Future<Split?> getSplitForCategory(int periodId, int categoryId) async {
    final db = await _db;
    final rows = await db.query(
      'splits',
      where: 'period_id = ? AND category_id = ?',
      whereArgs: [periodId, categoryId],
      limit: 1,
    );
    return rows.isEmpty ? null : Split.fromMap(rows.first);
  }

  // ----------------------------------------------------------- recurring rules

  Future<List<RecurringRule>> getRecurringRules() async {
    final db = await _db;
    final rows = await db.query('recurring_rules', orderBy: 'id DESC');
    return rows.map(RecurringRule.fromMap).toList();
  }

  Future<int> insertRecurringRule(RecurringRule rule) async {
    final db = await _db;
    return db.insert('recurring_rules', rule.toMap()..remove('id'));
  }

  Future<void> updateRecurringRule(RecurringRule rule) async {
    final db = await _db;
    await db.update(
      'recurring_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> deleteRecurringRule(int ruleId) async {
    final db = await _db;
    await db.delete('recurring_rules', where: 'id = ?', whereArgs: [ruleId]);
  }

  /// Recurring rule ids that have already produced an expense in this period,
  /// so applying rules twice doesn't create duplicates.
  Future<Set<int>> appliedRecurringIds(int periodId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT e.recurring_id AS rid
      FROM expenses e
      JOIN splits s ON s.id = e.split_id
      WHERE s.period_id = ? AND e.recurring_id IS NOT NULL
    ''',
      [periodId],
    );
    return {for (final row in rows) row['rid'] as int};
  }

  // ------------------------------------------------------------------ expenses

  Future<int> insertExpense(Expense expense) async {
    final db = await _db;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<List<Expense>> getExpensesForSplit(int splitId) async {
    final db = await _db;
    final rows = await db.query(
      'expenses',
      where: 'split_id = ?',
      whereArgs: [splitId],
      orderBy: 'date DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _db;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await _db;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expenseId]);
  }

  /// All expenses in a period joined with their category, newest first — for
  /// the transaction history screen.
  Future<List<Map<String, Object?>>> periodTransactions(int periodId) async {
    final db = await _db;
    return db.rawQuery(
      '''
      SELECT e.id AS id, e.amount AS amount, e.date AS date, e.note AS note,
             e.split_id AS split_id, e.recurring_id AS recurring_id,
             c.id AS category_id, c.name AS category, c.color AS color,
             c.icon AS icon
      FROM expenses e
      JOIN splits s ON s.id = e.split_id
      JOIN categories c ON c.id = s.category_id
      WHERE s.period_id = ?
      ORDER BY e.date DESC, e.id DESC
    ''',
      [periodId],
    );
  }

  /// Total spent per split id across a whole period, in one grouped query.
  Future<Map<int, double>> spentBySplit(int periodId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT e.split_id AS split_id, SUM(e.amount) AS total
      FROM expenses e
      JOIN splits s ON s.id = e.split_id
      WHERE s.period_id = ?
      GROUP BY e.split_id
    ''',
      [periodId],
    );

    return {
      for (final row in rows)
        row['split_id'] as int: (row['total'] as num).toDouble(),
    };
  }

  /// Flat rows for CSV export: one line per expense with human-readable period
  /// and category names.
  Future<List<Map<String, Object?>>> expenseExportRows() async {
    final db = await _db;
    return db.rawQuery('''
      SELECT p.name AS period, c.name AS category, e.amount AS amount,
             e.date AS date, e.note AS note
      FROM expenses e
      JOIN splits s ON s.id = e.split_id
      JOIN periods p ON p.id = s.period_id
      JOIN categories c ON c.id = s.category_id
      ORDER BY e.date DESC
    ''');
  }

  // -------------------------------------------------------------- export/import

  /// Tables in parent-first order (safe to insert in this order).
  static const _exportTables = [
    'periods',
    'categories',
    'recurring_rules',
    'splits',
    'expenses',
  ];

  /// Dumps the whole database to a plain map, ready to be JSON-encoded.
  Future<Map<String, Object?>> exportData() async {
    final db = await _db;
    final data = <String, Object?>{};
    for (final table in _exportTables) {
      data[table] = await db.query(table);
    }
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
  }

  /// Replaces all local data with the contents of a previously exported map.
  /// Runs in a transaction so a failure leaves the database untouched.
  Future<void> importData(Map<String, Object?> export) async {
    final data = (export['data'] as Map).cast<String, Object?>();
    final db = await _db;
    await db.transaction((txn) async {
      // Delete child-first to satisfy foreign keys.
      for (final table in _exportTables.reversed) {
        await txn.delete(table);
      }
      // Insert parent-first.
      for (final table in _exportTables) {
        final rows = (data[table] as List?) ?? const [];
        for (final row in rows) {
          await txn.insert(table, (row as Map).cast<String, Object?>());
        }
      }
    });
  }

  // ----------------------------------------------------------------- aggregate

  /// Planned + spent totals for every period, in three queries.
  Future<List<PeriodSummary>> periodSummaries() async {
    final periods = await getPeriods();
    if (periods.isEmpty) return const [];

    final db = await _db;
    final plannedRows = await db.rawQuery(
      'SELECT period_id AS pid, SUM(planned_amount) AS total '
      'FROM splits GROUP BY period_id',
    );
    final spentRows = await db.rawQuery('''
      SELECT s.period_id AS pid, SUM(e.amount) AS total
      FROM expenses e JOIN splits s ON s.id = e.split_id
      GROUP BY s.period_id
    ''');

    final plannedBy = {
      for (final r in plannedRows)
        r['pid'] as int: (r['total'] as num).toDouble(),
    };
    final spentBy = {
      for (final r in spentRows)
        r['pid'] as int: (r['total'] as num).toDouble(),
    };

    return [
      for (final p in periods)
        PeriodSummary(
          period: p,
          planned: plannedBy[p.id] ?? 0,
          spent: spentBy[p.id] ?? 0,
        ),
    ];
  }

  /// Assembles the per-category planned/spent/remaining view for a period.
  Future<List<CategoryProgress>> categoryProgress(int periodId) async {
    final splits = await getSplitsForPeriod(periodId);
    if (splits.isEmpty) return const [];

    final categories = {for (final c in await getCategories()) c.id: c};
    final spent = await spentBySplit(periodId);

    return [
      for (final split in splits)
        if (categories[split.categoryId] != null)
          CategoryProgress(
            category: categories[split.categoryId]!,
            split: split,
            spent: spent[split.id] ?? 0,
          ),
    ];
  }
}
