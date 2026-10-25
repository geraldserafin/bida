import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _csvTypeGroup = XTypeGroup(label: 'CSV', extensions: ['csv']);

/// Writes the file where the user says, or to the documents folder on
/// platforms without a save dialog (e.g. Android). Returns the path, or null
/// when cancelled.
Future<String?> saveCsv(String csv) async {
  String path;
  try {
    final location = await getSaveLocation(
      suggestedName: 'plning_export.csv',
      acceptedTypeGroups: const [_csvTypeGroup],
    );
    if (location == null) return null;
    path = location.path;
  } on UnimplementedError {
    final documents = await getApplicationDocumentsDirectory();
    path = p.join(documents.path, 'money_planner_export.csv');
  }
  await File(path).writeAsString(csv);
  return path;
}
