import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import 'api_errors.dart';
import 'money_format.dart';

/// Sends an expense and walks the user through the steps of F08 when the
/// server says it does not fit:
///
/// 1. the plan grows by itself out of free money (the server does it);
/// 2. "Trzeba podnieść plan": bring the missing money from the wallet and
///    raise the plan (or only raise it, when the balance holds the expense);
/// 3. the wallet would go below zero: confirm it.
///
/// Returns null when the user gave up or the request failed (and was shown).
Future<T?> sendWithSteps<T>(
  BuildContext context,
  int amountMinor,
  Future<T> Function(Decision? decision) send,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  Decision? decision;
  for (var step = 0; step < 4; step++) {
    try {
      return await send(decision);
    } on ApiException catch (error) {
      if (!context.mounted) return null;
      switch (error.tag) {
        case 'PlanTooSmall':
          final transfer = error.transferMinor ?? 0;
          final short = error.planShortMinor ?? 0;
          final balance = error.balanceMinor ?? 0;
          // the balance holds the expense: the plans may then exceed it
          final raiseOnly = balance >= amountMinor;
          final choice = await _choose(
            context,
            title: l10n.stepPlanTooSmallTitle,
            body: l10n.stepPlanTooSmallBody(formatMinor(short)),
            options: [
              if (transfer > 0)
                (l10n.stepBringAndRaise(formatMinor(transfer)), 'bring'),
              if (raiseOnly) (l10n.stepRaiseOnly, 'raise'),
            ],
          );
          if (choice == null) return null;
          decision = Decision(
            raisePlan: true,
            transferMinor: choice == 'bring' ? transfer : 0,
          );
        case 'NotEnoughInPeriod':
          final transfer = error.transferMinor ?? 0;
          final choice = await _choose(
            context,
            title: l10n.stepNotEnoughTitle,
            body: l10n.stepNotEnoughBody(formatMinor(error.balanceMinor ?? 0)),
            options: [(l10n.stepBring(formatMinor(transfer)), 'bring')],
          );
          if (choice == null) return null;
          decision = Decision(raisePlan: true, transferMinor: transfer);
        case 'WalletWouldGoNegative':
          final ok = await _confirm(
            context,
            title: l10n.stepWalletNegativeTitle,
            body: l10n.stepWalletNegativeBody(
              formatMinor((error.walletMinor ?? 0) - (error.neededMinor ?? 0)),
            ),
            action: l10n.stepWalletNegativeConfirm,
          );
          if (!ok || decision == null) return null;
          decision = decision.copyWith(allowNegativeWallet: true);
        default:
          messenger.showSnackBar(
            SnackBar(content: Text(moneyErrorMessage(l10n, error))),
          );
          return null;
      }
    }
  }
  return null;
}

/// Sends a correction of an income (F25). When it would put the wallet below
/// zero the user chooses: take the missing amount back from a household, or
/// keep the minus until the next income. Returns whether it went through.
Future<bool> sendWithCorrection(
  BuildContext context,
  List<Household> households,
  Future<void> Function(Correction? correction) send,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await send(null);
    return true;
  } on ApiException catch (error) {
    if (!context.mounted) return false;
    if (error.tag != 'WalletWouldGoNegative') {
      messenger.showSnackBar(
        SnackBar(content: Text(moneyErrorMessage(l10n, error))),
      );
      return false;
    }
    final choice = await _choose(
      context,
      title: l10n.correctionTitle,
      body: l10n.correctionBody(formatMinor(error.neededMinor ?? 0)),
      options: [
        for (final h in households)
          (l10n.correctionWithdrawFrom(h.name), h.current.id),
        (l10n.correctionKeepMinus, ''),
      ],
    );
    if (choice == null || !context.mounted) return false;
    return attemptMoney(
      context,
      () => send(
        choice.isEmpty
            ? const Correction.keepMinus()
            : Correction.withdrawFrom(choice),
      ),
    );
  }
}

/// Like `attempt`, with the messages of the money rules.
Future<bool> attemptMoney(
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
      SnackBar(content: Text(moneyErrorMessage(l10n, error))),
    );
    return false;
  }
}

/// What a refusal of the money rules means, in words; the generic message
/// for the others.
String moneyErrorMessage(AppLocalizations l10n, ApiException error) =>
    switch (error.tag) {
      'NotEnoughMoney' => l10n.errNotEnoughMoney(
        formatMinor(error.availableMinor ?? 0),
      ),
      'WalletNegative' => l10n.errWalletNegative,
      'PlanBelowSpent' => l10n.errPlanBelowSpent,
      'PeriodClosed' => l10n.errPeriodClosed,
      'PeriodNotCurrent' => l10n.errPeriodNotCurrent,
      'DateOutsidePeriod' => l10n.errDateOutsidePeriod,
      'MemberFrozen' => l10n.errMemberFrozen,
      'LastOwner' => l10n.errLastOwner,
      'LastEnvelope' => l10n.errLastEnvelope,
      'EnvelopeHasExpenses' => l10n.errEnvelopeHasExpenses,
      'DuplicateEnvelopeName' => l10n.errDuplicateEnvelope,
      'AlreadyMember' => l10n.errAlreadyMember,
      'NextPeriodOpen' => l10n.errNextPeriodOpen,
      'InvalidPeriodEnd' => l10n.errInvalidPeriodEnd,
      'CannotUndo' => l10n.errCannotUndo,
      'ConfirmationMismatch' => l10n.errConfirmationMismatch,
      'NegativeShare' => l10n.errNegativeShare(
        error.negativeShares
            .map(
              (e) => '${e.name} (${e.household}): ${formatMinor(e.shareMinor)}',
            )
            .join(', '),
      ),
      _ => apiErrorMessage(l10n, error),
    };

Future<String?> _choose(
  BuildContext context, {
  required String title,
  required String body,
  required List<(String, String)> options,
}) => showDialog<String>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(body),
    actionsOverflowDirection: VerticalDirection.down,
    actionsOverflowButtonSpacing: 8,
    actions: [
      TextButton(
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(AppLocalizations.of(ctx).cancel),
      ),
      for (final (label, value) in options)
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(value),
          child: Text(label),
        ),
    ],
  ),
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ==
    true;

/// Asks before something that cannot be taken back.
Future<bool> confirmDanger(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) => _confirm(context, title: title, body: body, action: action);

/// Asks for an amount in złoty; returns it in grosze.
Future<int?> askAmount(
  BuildContext context, {
  required String title,
  String? message,
  int? initialMinor,
  String? action,
}) async {
  final controller = TextEditingController(
    text: initialMinor == null
        ? ''
        : (initialMinor / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[Text(message), const SizedBox(height: 12)],
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'zł',
              labelText: l10n.amount,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(
              controller.text.trim().replaceAll(',', '.').replaceAll(' ', ''),
            );
            if (value == null || value < 0) return;
            Navigator.of(ctx).pop((value * 100).round());
          },
          child: Text(action ?? l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
