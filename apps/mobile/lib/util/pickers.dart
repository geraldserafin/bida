import 'package:flutter/material.dart';

/// The shared "double" date selector: one calendar that picks a start and end
/// day together. Used for the new-period range and the History date filter.
Future<DateTimeRange?> pickDateRange(
  BuildContext context, {
  DateTimeRange? initial,
}) {
  return showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    initialDateRange: initial,
  );
}
