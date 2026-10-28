/// What a member may do in a shared envelope.
enum EnvelopeRole { owner, member }

/// Somebody who shares an envelope.
class Member {
  final String userId;
  final String email;
  final String? name;
  final EnvelopeRole role;

  const Member({
    required this.userId,
    required this.email,
    this.name,
    required this.role,
  });

  /// What to call them: their name, or the address when they have none.
  String get displayName => name ?? email;
}

/// How much a member has put into an envelope, all time, net of what they
/// took back.
class Contribution {
  final String envelopeId;
  final String userId;
  final double amount;

  const Contribution({
    required this.envelopeId,
    required this.userId,
    required this.amount,
  });
}

enum InvitationStatus {
  /// Waiting for the person to answer.
  invited,

  /// They said yes; an owner still has to let them in.
  accepted,
}

/// An invitation to share an envelope.
class Invitation {
  final String id;
  final String envelopeId;
  final String envelopeName;

  /// The invited address.
  final String email;
  final EnvelopeRole role;
  final InvitationStatus status;

  /// Who invited, as a name or an address; null when they are gone.
  final String? invitedBy;

  const Invitation({
    required this.id,
    required this.envelopeId,
    required this.envelopeName,
    required this.email,
    required this.role,
    required this.status,
    this.invitedBy,
  });
}
