import 'package:flutter/material.dart';

/// Keeps the app phone-sized when it runs in a wide browser window: a rounded
/// device frame in the middle of the page instead of a stretched layout. On a
/// narrow window (an actual phone) the app fills it.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  static const width = 400.0;
  static const _bezel = 10.0;
  static const _margin = 24.0;
  static const _radius = 44.0;

  /// Windows up to this wide show the app full screen.
  static const _breakpoint = width + 2 * (_bezel + _margin);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width < _breakpoint) return child;

    final height = (media.size.height - 2 * _margin).clamp(480.0, 860.0);
    final screen = Size(width, height - 2 * _bezel);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: dark ? const Color(0xFF05070A) : const Color(0xFFE5E9EF),
      child: Center(
        child: Container(
          width: width + 2 * _bezel,
          height: height,
          padding: const EdgeInsets.all(_bezel),
          decoration: BoxDecoration(
            color: const Color(0xFF111418),
            borderRadius: BorderRadius.circular(_radius + _bezel),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            // the app lays itself out for the screen, not for the window
            child: MediaQuery(
              data: media.copyWith(size: screen),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
