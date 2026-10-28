import 'envelope.dart';
import 'expense.dart';

/// A logged expense joined with its envelope — a row in the history screen.
class Transaction {
  final Expense expense;
  final Envelope envelope;

  const Transaction({required this.expense, required this.envelope});

  String get id => expense.id!;
  double get amount => expense.amount;
  DateTime get date => expense.date;
  String? get note => expense.note;
  String? get recurringId => expense.recurringId;
}
