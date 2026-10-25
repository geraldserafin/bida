import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/planner_repository.dart';

/// Exports all logged expenses to a CSV file in the app documents directory.
class CsvExporter {
  final PlannerRepository _repo;
  CsvExporter({PlannerRepository? repository})
    : _repo = repository ?? PlannerRepository();

  /// Builds the CSV text for every logged expense.
  Future<String> buildCsv() async {
    final rows = await _repo.expenseExportRows();

    final buffer = StringBuffer()..writeln('Period,Category,Amount,Date,Note');
    for (final row in rows) {
      final date = (row['date'] as String).split('T').first; // yyyy-MM-dd
      buffer.writeln(
        [
          _field(row['period'] as String?),
          _field(row['category'] as String?),
          (row['amount'] as num).toStringAsFixed(2),
          date,
          _field(row['note'] as String?),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  /// Writes the CSV to a specific path and returns it.
  Future<String> exportToPath(String path) async {
    await File(path).writeAsString(await buildCsv());
    return path;
  }

  /// Writes the CSV to the default file in the app documents directory
  /// (used when the platform has no save dialog).
  Future<String> exportToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return exportToPath(p.join(dir.path, 'money_planner_export.csv'));
  }

  /// Escapes a CSV field (wraps in quotes when it contains a comma/quote/newline).
  String _field(String? value) {
    final v = value ?? '';
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
