import 'category.dart';
import 'split.dart';

/// A computed view of one category's envelope within the current period:
/// how much was planned, how much has been spent, and what's left.
///
/// Not persisted — assembled by the repository/state layer for the dashboard
/// and category detail screens.
class CategoryProgress {
  final Category category;
  final Split split;
  final double spent;

  const CategoryProgress({
    required this.category,
    required this.split,
    required this.spent,
  });

  double get planned => split.plannedAmount;
  double get remaining => planned - spent;

  /// Fraction of the envelope used, clamped to 0..1 for progress bars.
  double get fraction => planned <= 0 ? 0 : (spent / planned).clamp(0.0, 1.0);

  bool get isOverspent => spent > planned;
}
