import '../data/api_exception.dart';
import '../l10n/app_localizations.dart';
import 'api_errors.dart';

/// What to tell the user when sharing something failed: the reasons that only
/// sharing has, and the general message for the rest.
String sharingErrorMessage(AppLocalizations l10n, ApiException error) =>
    switch (error.tag) {
      'LastOwner' => l10n.lastOwner,
      'AlreadyMember' => l10n.alreadyMember,
      'LimitReached' => l10n.limitReached,
      'NotShareable' => l10n.notShareable,
      _ => apiErrorMessage(l10n, error),
    };
