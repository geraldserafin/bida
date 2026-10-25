import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../state/spaces_state.dart';
import '../../widgets/space_chooser.dart';

/// On the first start of a user with only a personal budget, asks what they
/// want to use: only their own budget, a shared one, or both. Shows the child
/// otherwise, and asks only once per device.
class FirstRunPrompt extends StatefulWidget {
  const FirstRunPrompt({super.key, required this.child, this.storage});

  final Widget child;
  final FlutterSecureStorage? storage;

  @override
  State<FirstRunPrompt> createState() => _FirstRunPromptState();
}

enum _Choice { personal, shared, both }

class _FirstRunPromptState extends State<FirstRunPrompt> {
  static const _kDone = 'onboarding_done';

  bool _asked = false;

  FlutterSecureStorage get _storage =>
      widget.storage ?? const FlutterSecureStorage();

  Future<void> _ask() async {
    final l10n = AppLocalizations.of(context);
    final spaces = context.read<SpacesState>();
    if (await _storage.read(key: _kDone) != null) return;
    if (!mounted) return;

    final choice = await showDialog<_Choice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.onboardingTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_Choice.personal),
            child: Text(l10n.onboardingPersonal),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_Choice.shared),
            child: Text(l10n.onboardingShared),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(_Choice.both),
            child: Text(l10n.onboardingBoth),
          ),
        ],
      ),
    );
    await _storage.write(key: _kDone, value: 'yes');
    if (choice == null || choice == _Choice.personal || !mounted) return;

    final personalId = spaces.current?.id;
    await createSharedBudget(context);
    // "both" starts in the personal budget, "shared" in the new one
    if (choice == _Choice.both && personalId != null) {
      await spaces.select(personalId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaces = context.watch<SpacesState>();
    final ready =
        !spaces.isLoading &&
        spaces.loadError == null &&
        spaces.current != null &&
        spaces.spaces.length == 1 &&
        spaces.invitations.isEmpty;
    if (ready && !_asked) {
      _asked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ask();
      });
    }
    return widget.child;
  }
}
