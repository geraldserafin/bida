import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../util/api_errors.dart';

/// A request failed: says why and offers to try again.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: theme.hintColor),
            const SizedBox(height: 12),
            Text(l10n.loadFailed, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              apiErrorMessage(l10n, error),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
