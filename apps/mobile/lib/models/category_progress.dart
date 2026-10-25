import 'category.dart';
import 'envelope.dart';

/// A computed view of one category's envelope within a period: how much was
/// planned, how much has been spent, and what's left.
///
/// Not stored anywhere — assembled by the repository from the API's progress
/// for the dashboard and category detail screens.
class CategoryProgress {
  final Category category;
  final Envelope envelope;
  final double spent;

  const CategoryProgress({
    required this.category,
    required this.envelope,
    required this.spent,
  });

  double get planned => envelope.plannedAmount;
  double get remaining => planned - spent;

  /// Fraction of the envelope used, clamped to 0..1 for progress bars.
  double get fraction => planned <= 0 ? 0 : (spent / planned).clamp(0.0, 1.0);

  bool get isOverspent => spent > planned;
}
