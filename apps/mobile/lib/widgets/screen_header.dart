import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';

/// The big title at the top of a tab ("Historia", "Cykliczne"), with an
/// optional muted note on the right.
class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(title, style: theme.textTheme.headlineMedium)),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.of(context).textMuted,
            ),
          ),
      ],
    );
  }
}

/// The top bar of a form opened over a tab: a close cross, the title, and
/// where the entry goes ("Dom · Listopad").
class FormTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FormTopBar({
    super.key,
    required this.title,
    this.where,
    this.actions = const [],
  });

  final String title;

  /// Where the entry goes, shown muted on the right.
  final String? where;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
        child: Row(
          children: [
            AppIconButton(
              AppIcon.close,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...actions,
            if (where != null)
              Text(
                where!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The amount typed into a form, large and centred ("Kwota/XL").
class BigAmountField extends StatelessWidget {
  const BigAmountField({
    super.key,
    required this.label,
    required this.controller,
    this.color,
    this.prefix,
    this.error,
    this.autofocus = false,
    this.onChanged,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final Color? color;

  /// Put before the number, e.g. "~" for an estimate.
  final String? prefix;
  final String? error;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final style = TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      color: color ?? c.text,
      height: 1.2,
    );
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            if (prefix != null) Text(prefix!, style: style),
            IntrinsicWidth(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: inputFormatters,
                textAlign: TextAlign.right,
                style: style,
                cursorColor: color ?? c.text,
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '0,00',
                  hintStyle: style.copyWith(color: c.borderStrong),
                ),
                onChanged: onChanged,
              ),
            ),
            Text(' zł', style: style),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: TextStyle(color: c.danger, fontSize: 12)),
        ],
      ],
    );
  }
}
