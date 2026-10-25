import 'category.dart';
import 'expense.dart';

/// A logged expense joined with its category — a row in the history screen.
class Transaction {
  final int id;
  final int splitId;
  final double amount;
  final DateTime date;
  final String? note;
  final int? recurringId;
  final Category category;

  const Transaction({
    required this.id,
    required this.splitId,
    required this.amount,
    required this.date,
    required this.note,
    required this.recurringId,
    required this.category,
  });

  factory Transaction.fromMap(Map<String, Object?> map) => Transaction(
    id: map['id'] as int,
    splitId: map['split_id'] as int,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date'] as String),
    note: map['note'] as String?,
    recurringId: map['recurring_id'] as int?,
    category: Category(
      id: map['category_id'] as int,
      name: map['category'] as String,
      color: map['color'] as String,
      icon: map['icon'] as String?,
    ),
  );

  Expense toExpense() => Expense(
    id: id,
    splitId: splitId,
    amount: amount,
    date: date,
    note: note,
    recurringId: recurringId,
  );
}
