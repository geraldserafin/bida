import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/planner_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/envelope_visuals.dart';
import '../../util/api_errors.dart';
import '../../util/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_row.dart';
import '../envelope_detail/envelope_detail_screen.dart';
import '../incomes/incomes_screen.dart';
import '../months/months_screen.dart';
import '../settings/settings_screen.dart';
import '../sharing/invitations_card.dart';
import 'envelope_editor.dart';
import 'envelopes_screen.dart';

/// Envelopes tab ("Koperty"): the invitations waiting for an answer, every
/// top-level envelope with who shares it and what is in it, and the way to
/// income, months and settings. Sharing is done per envelope, from its
/// detail screen.
class EnvelopesTab extends StatelessWidget {
  const EnvelopesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final top = state.topLevelProgress;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TabTitle(l10n.envelopesTab),
            ),
            const SizedBox(height: 14),
            const InvitationsCard(),
            if (top.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.noEnvelopes, textAlign: TextAlign.center),
              ),
            for (final p in top) ...[
              _EnvelopeCard(progress: p),
              const SizedBox(height: 8),
            ],
            AppButton(
              label: l10n.newEnvelopePlus,
              kind: ButtonKind.dashed,
              onPressed: () => _addEnvelope(context),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.sharingPerEnvelope,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Overline(l10n.more),
            const SizedBox(height: 8),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _LinkRow(label: l10n.incomes, screen: const IncomesScreen()),
                  _LinkRow(label: l10n.months, screen: const MonthsScreen()),
                  _LinkRow(
                    label: l10n.manageEnvelopes,
                    screen: const EnvelopesScreen(),
                  ),
                  _LinkRow(
                    label: l10n.settings,
                    screen: const SettingsScreen(),
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEnvelope(BuildContext context) async {
    final created = await showEnvelopeEditor(context);
    if (created == null || !context.mounted) return;
    final state = context.read<PlannerState>();
    await attempt(context, () => state.addEnvelope(created));
  }
}

/// A top-level envelope: its name, who shares it and its balance.
class _EnvelopeCard extends StatelessWidget {
  const _EnvelopeCard({required this.progress});
  final EnvelopeProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final envelope = progress.envelope;
    return SurfaceCard(
      outline: progress.isShared ? CardOutline.selected : CardOutline.normal,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnvelopeDetailScreen(envelopeId: envelope.id!),
        ),
      ),
      child: Row(
        children: [
          CategoryDot(envelope.displayColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  envelope.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  progress.isShared
                      ? l10n.sharedWith(progress.memberCount)
                      : l10n.soloSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            formatZloty(progress.balance),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: progress.isOverspent ? c.danger : c.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of the "more" card that opens [screen].
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.screen,
    this.last = false,
  });

  final String label;
  final Widget screen;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, height: 1.5, color: c.text),
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
