import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/recurring/recurring_rules_screen.dart';
import '../screens/settings/settings_screen.dart';

/// App-wide navigation drawer, keeping the dashboard app bar uncluttered.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    void go(Widget screen) {
      Navigator.of(context).pop(); // close the drawer
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: scheme.primaryContainer),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 40,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: Text(l10n.dashboard),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.history),
            onTap: () => go(const HistoryScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l10n.categories),
            onTap: () => go(const CategoriesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(l10n.recurringRules),
            onTap: () => go(const RecurringRulesScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settings),
            onTap: () => go(const SettingsScreen()),
          ),
        ],
      ),
    );
  }
}
