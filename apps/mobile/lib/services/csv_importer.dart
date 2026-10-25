import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/planner_repository.dart';
import '../models/models.dart';
import '../theme/category_visuals.dart';

/// Imports expenses from the CSV produced by [CsvExporter].
///
/// Matches sets and categories by name (creating them on demand), so a CSV can
/// round-trip the expense log. Note the CSV doesn't carry income or planned
/// amounts, so newly created sets/envelopes start at 0 — use the encrypted
/// backup for a full restore.
class CsvImporter {
  final PlannerRepository _repo;
  CsvImporter({PlannerRepository? repository})
    : _repo = repository ?? PlannerRepository();

  /// Imports the default export file in the app documents directory. Returns
  /// null if there is no export file.
  Future<({int imported, int skipped})?> importFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return importFromPath(p.join(dir.path, 'money_planner_export.csv'));
  }

  /// Imports a CSV from an explicit path (e.g. one the user picked). Rows that
  /// already exist (same envelope, amount, day and note) are skipped, so
  /// re-importing the same file won't create duplicates. Returns the counts of
  /// imported and skipped rows, or null if the file doesn't exist.
  Future<({int imported, int skipped})?> importFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final lines = (await file.readAsString())
        .split(RegExp(r'\r\n|\r|\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return (imported: 0, skipped: 0); // header only

    final periods = {for (final e in await _repo.getPeriods()) e.name: e};
    final categories = {
      for (final c in await _repo.getCategories()) c.name.toLowerCase(): c,
    };
    // Per-split set of existing expense fingerprints, loaded lazily; new
    // inserts are added so duplicates within the same file are caught too.
    final seenBySplit = <int, Set<String>>{};

    var imported = 0;
    var skipped = 0;
    for (final line in lines.skip(1)) {
      final cols = _parseLine(line);
      if (cols.length < 4) continue;
      final periodName = cols[0].trim();
      final categoryName = cols[1].trim();
      final amount = double.tryParse(cols[2].trim());
      final date = DateTime.tryParse(cols[3].trim());
      final note = cols.length > 4 ? cols[4].trim() : '';
      if (amount == null || date == null || categoryName.isEmpty) continue;

      final period = await _ensurePeriod(periods, periodName, date);
      final category = await _ensureCategory(categories, categoryName);
      var split = await _repo.getSplitForCategory(period.id!, category.id!);
      split ??= Split(
        id: await _repo.insertSplit(
          Split(
            periodId: period.id!,
            categoryId: category.id!,
            plannedAmount: 0,
          ),
        ),
        periodId: period.id!,
        categoryId: category.id!,
        plannedAmount: 0,
      );

      final seen = seenBySplit[split.id!] ??= {
        for (final e in await _repo.getExpensesForSplit(split.id!))
          _fingerprint(e.amount, e.date, e.note ?? ''),
      };
      final key = _fingerprint(amount, date, note);
      if (!seen.add(key)) {
        skipped++;
        continue; // identical expense already present
      }

      await _repo.insertExpense(
        Expense(
          splitId: split.id!,
          amount: amount,
          date: date,
          note: note.isEmpty ? null : note,
        ),
      );
      imported++;
    }
    return (imported: imported, skipped: skipped);
  }

  /// A duplicate key at day granularity — the CSV only carries the date, not
  /// the time, so two rows for the same day/amount/note are considered equal.
  String _fingerprint(double amount, DateTime date, String note) =>
      '${amount.toStringAsFixed(2)}|${date.year}-${date.month}-${date.day}|$note';

  Future<Period> _ensurePeriod(
    Map<String, Period> cache,
    String name,
    DateTime sampleDate,
  ) async {
    final existing = cache[name];
    if (existing != null) return existing;
    final start = DateTime(sampleDate.year, sampleDate.month, 1);
    final end = DateTime(sampleDate.year, sampleDate.month + 1, 0);
    final id = await _repo.insertPeriod(
      Period(name: name, startDate: start, endDate: end, income: 0),
    );
    return cache[name] = Period(
      id: id,
      name: name,
      startDate: start,
      endDate: end,
      income: 0,
    );
  }

  Future<Category> _ensureCategory(
    Map<String, Category> cache,
    String name,
  ) async {
    final key = name.toLowerCase();
    final existing = cache[key];
    if (existing != null) return existing;
    final color =
        categoryColorPalette[cache.length % categoryColorPalette.length];
    final id = await _repo.insertCategory(Category(name: name, color: color));
    return cache[key] = Category(id: id, name: name, color: color);
  }

  /// Parses a single CSV line, honouring quoted fields and escaped quotes.
  List<String> _parseLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            sb.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          sb.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
