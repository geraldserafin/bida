import 'package:flutter/material.dart';

/// The big buttons floating at the bottom of a screen, side by side and
/// across its width. Use with [FloatingActionButtonLocation.centerFloat]:
/// an [AppButton] alone in the floating slot stretches and drifts left.
class FabBar extends StatelessWidget {
  const FabBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
