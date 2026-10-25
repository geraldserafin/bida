/// A budget: your own, or one shared with other people.
enum SpaceKind { personal, shared }

/// What somebody may do in a shared budget. Owners manage the space and its
/// members; members work with the budget.
enum SpaceRole { owner, member }

class AppSpace {
  const AppSpace({
    required this.id,
    required this.name,
    required this.currency,
    required this.kind,
    required this.role,
    required this.memberCount,
  });

  final String id;
  final String name;

  /// Default currency of new periods.
  final String currency;
  final SpaceKind kind;

  /// Your role in it.
  final SpaceRole role;
  final int memberCount;

  bool get isShared => kind == SpaceKind.shared;
  bool get isOwner => role == SpaceRole.owner;
}

class SpaceMember {
  const SpaceMember({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String email;
  final String? name;
  final SpaceRole role;
  final DateTime joinedAt;

  /// What to call them: their name, or the e-mail address when they set none.
  String get label => name ?? email;
}

/// Waiting for an answer from the invited person, or (accepted) for an owner
/// to let them in.
enum InvitationStatus { invited, accepted }

class SpaceInvitation {
  const SpaceInvitation({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.expiresAt,
  });

  final String id;
  final String spaceId;
  final String spaceName;
  final String email;
  final SpaceRole role;
  final InvitationStatus status;

  /// Who invited: their name or e-mail, null when they are gone.
  final String? invitedBy;
  final DateTime expiresAt;
}

/// Money paid into the budget of a shared space in a period.
class Contribution {
  const Contribution({
    required this.id,
    required this.periodId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String periodId;

  /// Who paid in; null for money from outside.
  final String? userId;

  /// In the currency of the period.
  final double amount;
  final DateTime date;
  final String? note;
}
