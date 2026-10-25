import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import 'category_editor.dart';

/// Manage the reusable categories (envelopes) used across periods.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: categories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noCategories, textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final category = categories[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: category.displayColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      category.displayIcon,
                      color: category.displayColor,
                      size: 20,
                    ),
                  ),
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, state, category.id!),
                  ),
                  onTap: () async {
                    final planner = context.read<PlannerState>();
                    final edited = await showCategoryEditor(
                      context,
                      existing: category,
                    );
                    if (edited != null) {
                      await planner.updateCategory(edited);
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCategoryEditor(context);
          if (created != null && context.mounted) {
            await context.read<PlannerState>().addCategory(created);
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    PlannerState state,
    int categoryId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await state.deleteCategory(categoryId);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.categoryInUse)));
    }
  }
}
