import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A rounded choice ("Chip" in the design): white when [selected], a dark
/// outlined pill otherwise.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final bool selected;

  /// Null disables the chip.
  final VoidCallback? onTap;

  /// Centre the label in all the width given, for [SegmentedPills].
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = selected ? c.text : c.surface;
    return Opacity(
      opacity: onTap == null && !selected ? 0.45 : 1,
      child: Material(
        color: fill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? fill : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: expand ? null : 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? c.onPrimary : c.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chips that wrap onto as many lines as they need.
class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}

/// Two or more options side by side on a tray, one of them chosen: the
/// design's tab switch ("Stała / Szacunkowa", "Wpłaty / Wydatki").
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.trayColor,
    this.radius = 14,
  });

  /// The value and label of each option, in order.
  final List<(T, String)> options;
  final T selected;

  /// Null disables switching.
  final ValueChanged<T>? onChanged;
  final Color? trayColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: trayColor ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: PillChip(
                label: options[i].$2,
                selected: options[i].$1 == selected,
                expand: true,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(options[i].$1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
