import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Colours of members' avatars, in the order members are shown.
const avatarColors = [
  Color(0xFFF59E0B), // kat/mieszkanie
  Color(0xFF60A5FA), // kat/transport
  Color(0xFFF472B6), // kat/różowy
];

/// A member's initial on a coloured circle.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 36,
    this.ring = false,
  });

  final String name;
  final Color color;
  final double size;

  /// A ring in the background colour, for avatars that overlap.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: c.background, width: 2) : null,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.onPrimary,
        ),
      ),
    );
  }
}
