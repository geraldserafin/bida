import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'surface_card.dart';

/// The 10 px dot in a category's colour that starts most rows.
class CategoryDot extends StatelessWidget {
  const CategoryDot(this.color, {super.key, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// What a [TransactionRow] shows the amount as.
enum AmountTone {
  /// spent, or an ordinary amount
  normal,

  /// money coming in: green
  income,

  /// only estimated so far: amber, with a dashed card
  estimate,
}

/// A transaction or rule as a card ("Wiersz transakcji"): a coloured dot, a
/// name with details under it, and the amount on the right.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    super.key,
    required this.color,
    required this.title,
    required this.details,
    required this.amount,
    this.tone = AmountTone.normal,
    this.onTap,
  });

  final Color color;
  final String title;
  final String details;
  final String amount;
  final AmountTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      outline: tone == AmountTone.estimate
          ? CardOutline.estimate
          : CardOutline.normal,
      onTap: onTap,
      child: Row(
        children: [
          CategoryDot(color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(details, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: switch (tone) {
                AmountTone.normal => c.text,
                AmountTone.income => c.accent,
                AmountTone.estimate => c.estimate,
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One envelope of the dashboard ("Koperta"): name, spent of planned, and a
/// bar in the category's colour.
class EnvelopeBar extends StatelessWidget {
  const EnvelopeBar({
    super.key,
    required this.color,
    required this.name,
    required this.amounts,
    required this.fraction,
    this.overspent = false,
    this.onTap,
  });

  final Color color;
  final String name;

  /// "spent / planned"
  final String amounts;

  /// How full the bar is, 0..1.
  final double fraction;
  final bool overspent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryDot(color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 14, height: 1.45, color: c.text),
                ),
              ),
              Text(
                amounts,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: overspent ? c.danger : c.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: c.surface2,
              color: overspent ? c.danger : color,
            ),
          ),
        ],
      ),
    );
  }
}
