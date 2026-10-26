import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The design's on/off switch ("Przełącznik"), 52×32, drawn from the two
/// states exported from Figma.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SvgPicture.asset(
          value ? 'assets/icons/switch_on.svg' : 'assets/icons/switch_off.svg',
          width: 52,
          height: 32,
        ),
      ),
    );
  }
}
