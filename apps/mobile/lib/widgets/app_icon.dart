import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The icons of the design, exported from Figma into `assets/icons/`. Each is
/// drawn at the size it was exported at.
enum AppIcon {
  home('home', 28),
  navHome('nav_home', 22),
  navHomeActive('nav_home_active', 22),
  navHistory('nav_history', 22),
  navHistoryActive('nav_history_active', 22),
  navRecurring('nav_recurring', 22),
  navRecurringActive('nav_recurring_active', 22),
  navHousehold('nav_household', 22),
  navHouseholdActive('nav_household_active', 22),
  chevronDown('chevron_down', 18),
  chevronLeft('chevron_left', 20),
  chevronRight('chevron_right', 20),
  back('back', 22),
  close('close', 22);

  const AppIcon(this.file, this.size);

  final String file;
  final double size;

  String get asset => 'assets/icons/$file.svg';
}

/// Draws an [AppIcon] at its own size.
class AppIconView extends StatelessWidget {
  const AppIconView(this.icon, {super.key, this.semanticLabel});

  final AppIcon icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    icon.asset,
    width: icon.size,
    height: icon.size,
    semanticsLabel: semanticLabel,
  );
}

/// An [AppIcon] as a 44×44 tap target.
class AppIconButton extends StatelessWidget {
  const AppIconButton(
    this.icon, {
    super.key,
    required this.onPressed,
    required this.tooltip,
  });

  final AppIcon icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    icon: AppIconView(icon),
  );
}
