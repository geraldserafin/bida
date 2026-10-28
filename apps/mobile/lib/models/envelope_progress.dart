import 'envelope.dart';
import 'sharing.dart';

/// How much is in an envelope over a month: what was left from before, what
/// came in, what was spent, and what is left now. Not stored anywhere — the
/// server computes it (`GET /overview`) and the repository joins it with the
/// envelope.
///
/// For a top-level envelope everything includes its sub-envelopes, so
/// [balance] is all the money in it and [free] the part not assigned to a
/// sub-envelope. A sub-envelope has [free] equal to [balance].
class EnvelopeProgress {
  final Envelope envelope;
  final double opening;
  final double allocated;
  final double spent;
  final double balance;
  final double free;

  /// What the user may do with the envelope.
  final EnvelopeRole role;

  /// How many people share the envelope; 1 when it is only theirs.
  final int memberCount;

  const EnvelopeProgress({
    required this.envelope,
    required this.opening,
    required this.allocated,
    required this.spent,
    required this.balance,
    required this.free,
    this.role = EnvelopeRole.owner,
    this.memberCount = 1,
  });

  bool get isShared => memberCount > 1;

  bool get isOwner => role == EnvelopeRole.owner;

  /// What there was to spend this month: the rest from before plus what came in.
  double get available => opening + allocated;

  /// Fraction of what was available that is spent, 0..1 for progress bars.
  double get fraction => available <= 0
      ? (spent > 0 ? 1 : 0)
      : (spent / available).clamp(0.0, 1.0);

  bool get isOverspent => balance < 0;
}
