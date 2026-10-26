import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashed_border.dart';

/// The kinds of buttons ("Przycisk") in the design.
enum ButtonKind {
  /// near-white pill: the one action the screen is about
  primary,

  /// outlined pill
  secondary,

  /// grey pill, for actions inside a card
  tonal,

  /// grey outlined pill floating over content ("+ Wpłata")
  raised,

  /// dashed rounded rectangle, for "+ add" actions in a list
  dashed,
}

/// A full-height (52) button in one of the design's [ButtonKind]s. Shows a
/// spinner instead of the label while [busy].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.busy = false,
    this.height = 52,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = onPressed != null && !busy;
    final (Color fill, Color fg, BorderSide side) = switch (kind) {
      ButtonKind.primary => (c.primary, c.onPrimary, BorderSide.none),
      ButtonKind.secondary => (
        Colors.transparent,
        c.text,
        BorderSide(color: c.borderStrong),
      ),
      ButtonKind.tonal => (c.surface2, c.text, BorderSide.none),
      ButtonKind.raised => (
        c.surface2,
        c.text,
        BorderSide(color: c.borderStrong),
      ),
      ButtonKind.dashed => (Colors.transparent, c.text, BorderSide.none),
    };
    final radius = kind == ButtonKind.dashed ? 14.0 : height / 2;

    Widget button = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
    if (kind == ButtonKind.dashed) {
      button = DashedBorder(
        color: c.borderStrong,
        radius: radius,
        child: button,
      );
    }
    return Opacity(opacity: enabled || busy ? 1 : 0.45, child: button);
  }
}

/// The small rounded button inside list rows ("Potwierdź", "Usuń", "Anuluj").
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Outlined (Usuń, Anuluj) rather than filled grey (Potwierdź).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: Material(
        color: outlined ? Colors.transparent : c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(outlined ? 12 : 18),
          side: outlined ? BorderSide(color: c.borderStrong) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: outlined ? 40 : 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: outlined ? c.textSoft : c.text,
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
