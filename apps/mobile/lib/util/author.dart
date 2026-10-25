import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../state/spaces_state.dart';

/// Who added the expense, for a shared budget: their name, or "former member"
/// when they left. Null in a personal budget, and for expenses nobody added
/// (imported ones).
String? authorOf(BuildContext context, Expense expense) {
  final spaces = context.watch<SpacesState>();
  final id = expense.createdBy;
  if (!(spaces.current?.isShared ?? false) || id == null) return null;
  return spaces.memberById(id)?.label ??
      AppLocalizations.of(context).formerMember;
}
