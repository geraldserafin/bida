import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashed_border.dart';

/// How a [SurfaceCard] is outlined.
enum CardOutline {
  /// the hairline border of every card
  normal,

  /// dashed amber: the card holds an estimated amount
  estimate,

  /// thick green: the card is the chosen one
  selected,

  /// no fill, a hairline border
  bare,
}

/// A rounded card on the "powierzchnia" surface, the building block of most
/// screens of the design.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.outline = CardOutline.normal,
    this.radius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.onTap,
  });

  final Widget child;
  final CardOutline outline;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: switch (outline) {
        CardOutline.normal || CardOutline.bare => BorderSide(color: c.border),
        CardOutline.selected => BorderSide(color: c.accent, width: 2),
        CardOutline.estimate => BorderSide.none,
      },
    );
    Widget card = Material(
      color: outline == CardOutline.bare ? Colors.transparent : c.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (outline == CardOutline.estimate) {
      card = DashedBorder(color: c.estimateBorder, radius: radius, child: card);
    }
    return card;
  }
}
