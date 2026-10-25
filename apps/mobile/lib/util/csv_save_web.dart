import 'dart:convert';

import 'package:file_selector/file_selector.dart';

const _fileName = 'plning_export.csv';

/// Hands the file to the browser as a download. Returns its name.
Future<String?> saveCsv(String csv) async {
  final file = XFile.fromData(
    utf8.encode(csv),
    mimeType: 'text/csv',
    name: _fileName,
  );
  await file.saveTo(_fileName);
  return _fileName;
}
