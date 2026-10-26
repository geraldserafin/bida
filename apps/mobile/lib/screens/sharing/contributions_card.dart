import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../state/auth_state.dart';
import '../../state/planner_state.dart';
import '../../util/money_format.dart';
import '../../widgets/remote_data.dart';

/// Who put how much into a shared envelope, and into each of its
/// sub-envelopes. The user comes first, as "Ty".
class ContributionsCard extends StatelessWidget {
  const ContributionsCard({
    super.key,
    required this.envelopeId,
    required this.version,
  });

  final String envelopeId;

  /// Changes when the money in the envelope does, so the numbers are fetched
  /// again.
  final Object version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final myEmail = context.watch<AuthState>().email;

    return RemoteData<(List<Member>, List<Contribution>)>(
      version: version,
      load: () async {
        final (members, contributions) = await (
          state.membersOf(envelopeId),
          state.contributionsOf(envelopeId),
        ).wait;
        return (members, contributions);
      },
      builder: (context, data) {
        final (members, contributions) = data;
        // the envelope itself first, then its sub-envelopes
        final byEnvelope = <String, List<Contribution>>{};
        for (final c in contributions) {
          byEnvelope.putIfAbsent(c.envelopeId, () => []).add(c);
        }
        if (byEnvelope.isEmpty) return const SizedBox.shrink();

        String nameOf(String userId) {
          final member = members.where((m) => m.userId == userId).firstOrNull;
          if (member == null) return l10n.formerMember;
          return member.email == myEmail ? l10n.you : member.displayName;
        }

        bool mine(String userId) =>
            members.where((m) => m.userId == userId).firstOrNull?.email ==
            myEmail;

        List<Widget> rows(List<Contribution> list) {
          final sorted = [...list]
            ..sort((a, b) {
              if (mine(a.userId) != mine(b.userId)) {
                return mine(a.userId) ? -1 : 1;
              }
              return b.amount.compareTo(a.amount);
            });
          return [
            for (final c in sorted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(nameOf(c.userId)),
                    Text(
                      formatZloty(c.amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ];
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.whoPutHowMuch,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final entry in byEnvelope.entries) ...[
                  if (entry.key != envelopeId)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Text(
                        state.envelopeById(entry.key)?.name ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ...rows(entry.value),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
