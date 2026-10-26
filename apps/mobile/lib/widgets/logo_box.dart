import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';

/// The app's mark: a house on a rounded tile ("Logo").
class LogoBox extends StatelessWidget {
  const LogoBox({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: const AppIconView(AppIcon.home),
    );
  }
}
