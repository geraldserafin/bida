import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../l10n/app_localizations.dart';

/// What to tell the user when a request failed.
String apiErrorMessage(AppLocalizations l10n, ApiException error) =>
    switch (error.failure) {
      ApiFailure.unreachable => l10n.errorUnreachable,
      ApiFailure.notFound => l10n.errorNotFound,
      ApiFailure.conflict => l10n.errorConflict,
      ApiFailure.invalid => l10n.errorInvalid,
      ApiFailure.server => l10n.errorServer,
    };

/// Runs [action] and, when the server cannot do it, tells the user and
/// returns false. The app needs the server, so there is nothing to fall back
/// to: the user sees why and can try again.
Future<bool> attempt(
  BuildContext context,
  Future<void> Function() action,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    return true;
  } on ApiException catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(apiErrorMessage(l10n, error))),
    );
    return false;
  }
}
