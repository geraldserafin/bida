import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// The four places of the app, in the order of the bottom menu.
enum AppTab { dashboard, history, recurring, envelopes }

/// The bottom menu ("Menu dolne"): Pulpit, Historia, Cykliczne, Koperty.
class BottomMenu extends StatelessWidget {
  const BottomMenu({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _item(
                AppTab.dashboard,
                l10n.dashboard,
                AppIcon.navHome,
                AppIcon.navHomeActive,
              ),
              _item(
                AppTab.history,
                l10n.history,
                AppIcon.navHistory,
                AppIcon.navHistoryActive,
              ),
              _item(
                AppTab.recurring,
                l10n.recurringTab,
                AppIcon.navRecurring,
                AppIcon.navRecurringActive,
              ),
              _item(
                AppTab.envelopes,
                l10n.envelopesTab,
                AppIcon.navHousehold,
                AppIcon.navHouseholdActive,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(AppTab tab, String label, AppIcon icon, AppIcon activeIcon) {
    return Expanded(
      child: _MenuItem(
        label: label,
        icon: tab == current ? activeIcon : icon,
        active: tab == current,
        onTap: () => onSelect(tab),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final AppIcon icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      selected: active,
      button: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconView(icon),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                height: active ? null : 1.45,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? c.primary : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
