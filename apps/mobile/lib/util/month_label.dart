import 'package:intl/intl.dart';

import '../models/budget_month.dart';

/// "październik 2026" for a calendar month, "10 paź – 9 lis" for a month that
/// starts on another day.
String monthLabel(BudgetMonth month) {
  if (month.firstDay == 1) {
    final text = DateFormat.yMMMM('pl').format(month.from);
    return text[0].toUpperCase() + text.substring(1);
  }
  final day = DateFormat.MMMd('pl');
  return '${day.format(month.from)} – ${day.format(month.to)}';
}
