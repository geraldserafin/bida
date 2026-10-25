import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_exception.dart';
import 'mappers.dart';
import 'money.dart';

SpaceRole _role(api.Role role) =>
    role == api.Role.owner ? SpaceRole.owner : SpaceRole.member;

api.Role _roleOf(SpaceRole role) =>
    role == SpaceRole.owner ? api.Role.owner : api.Role.member;

AppSpace spaceFrom(api.MySpace s) => AppSpace(
  id: s.space.id,
  name: s.space.name,
  currency: currencyCode(s.space.defaultCurrency),
  kind: s.space.kind == api.SpaceKind.personal
      ? SpaceKind.personal
      : SpaceKind.shared,
  role: _role(s.role),
  memberCount: s.memberCount,
);

SpaceMember memberFrom(api.Member m) => SpaceMember(
  userId: m.userId,
  email: m.email,
  name: m.name,
  role: _role(m.role),
  joinedAt: DateTime.parse(m.joinedAt).toLocal(),
);

SpaceInvitation invitationFrom(api.Invitation i) => SpaceInvitation(
  id: i.id,
  spaceId: i.spaceId,
  spaceName: i.spaceName,
  email: i.email,
  role: _role(i.role),
  status: i.status == api.InvitationStatus.accepted
      ? InvitationStatus.accepted
      : InvitationStatus.invited,
  invitedBy: i.invitedBy == null
      ? null
      : (i.invitedBy!.name ?? i.invitedBy!.email),
  expiresAt: DateTime.parse(i.expiresAt).toLocal(),
);

Contribution contributionFrom(api.Contribution c, String currency) =>
    Contribution(
      id: c.id,
      periodId: c.periodId,
      userId: c.userId,
      amount: fromMinor(c.amountMinor, currency),
      date: DateTime.parse(c.contributedAt).toLocal(),
      note: c.note,
    );

/// The budgets of the signed-in user, who is in them, who they invited, and
/// what was paid into them. Every method either returns app models or throws
/// an [ApiException].
class SharingRepository {
  SharingRepository(Dio dio) : _api = api.BidaApi(dio);

  final api.BidaApi _api;

  // ---------------------------------------------------------------- spaces

  /// The personal budget first, then the shared ones.
  Future<List<AppSpace>> spaces() => guard(() async {
    final all = await _api.spaces.spacesList();
    return all.map(spaceFrom).toList();
  });

  Future<AppSpace> createSpace(String name, String currency) => guard(
    () async => spaceFrom(
      await _api.spaces.spacesCreate(
        body: api.SaveSpace(name: name, defaultCurrency: currencyOf(currency)),
      ),
    ),
  );

  Future<AppSpace> updateSpace(String id, String name, String currency) =>
      guard(
        () async => spaceFrom(
          await _api.spaces.spacesUpdate(
            id: id,
            body: api.SaveSpace(
              name: name,
              defaultCurrency: currencyOf(currency),
            ),
          ),
        ),
      );

  Future<void> deleteSpace(String id) =>
      guard(() => _api.spaces.spacesDelete(id: id));

  Future<void> leaveSpace(String id) =>
      guard(() => _api.spaces.spacesLeave(id: id));

  // --------------------------------------------------------------- members

  Future<List<SpaceMember>> members(String spaceId) => guard(() async {
    final all = await _api.spaces.spacesMembers(id: spaceId);
    return all.map(memberFrom).toList();
  });

  Future<void> setRole(String spaceId, String userId, SpaceRole role) => guard(
    () => _api.spaces.spacesSetRole(
      id: spaceId,
      userId: userId,
      body: api.SetRole(role: _roleOf(role)),
    ),
  );

  Future<void> removeMember(String spaceId, String userId) =>
      guard(() => _api.spaces.spacesRemoveMember(id: spaceId, userId: userId));

  // ----------------------------------------------------------- invitations

  /// Invites by e-mail address.
  Future<SpaceInvitation> invite(
    String spaceId,
    String email,
    SpaceRole role,
  ) => guard(
    () async => invitationFrom(
      await _api.invitations.invitationsInvite(
        id: spaceId,
        body: api.Invite(email: email, role: _roleOf(role)),
      ),
    ),
  );

  /// The open invitations of a space (owners only).
  Future<List<SpaceInvitation>> spaceInvitations(String spaceId) =>
      guard(() async {
        final all = await _api.invitations.invitationsForSpace(id: spaceId);
        return all.map(invitationFrom).toList();
      });

  Future<void> revokeInvitation(String spaceId, String invitationId) => guard(
    () => _api.invitations.invitationsRevoke(
      id: spaceId,
      invitationId: invitationId,
    ),
  );

  /// Lets in somebody who accepted an invitation.
  Future<void> approveInvitation(String spaceId, String invitationId) => guard(
    () => _api.invitations.invitationsApprove(
      id: spaceId,
      invitationId: invitationId,
    ),
  );

  /// The invitations for the address of the signed-in user.
  Future<List<SpaceInvitation>> myInvitations() => guard(() async {
    final all = await _api.invitations.invitationsMine();
    return all.map(invitationFrom).toList();
  });

  Future<void> acceptInvitation(String id) =>
      guard(() => _api.invitations.invitationsAccept(invitationId: id));

  Future<void> declineInvitation(String id) =>
      guard(() => _api.invitations.invitationsDecline(invitationId: id));

  // ---------------------------------------------------------- contributions

  /// Newest first. [currency] is the currency of the period.
  Future<List<Contribution>> contributions(String periodId, String currency) =>
      guard(() async {
        final all = await _api.contributions.contributionsList(id: periodId);
        return all.map((c) => contributionFrom(c, currency)).toList();
      });

  /// Money paid into the period, by you or (with [external]) by nobody of the
  /// budget.
  Future<void> addContribution(
    String periodId, {
    required double amount,
    required String currency,
    required DateTime date,
    String? note,
    bool external = false,
  }) => guard(
    () => _api.contributions.contributionsAdd(
      id: periodId,
      body: api.AddContribution(
        amountMinor: toMinor(amount, currency),
        contributedAt: date.toUtc().toIso8601String(),
        note: note,
        externalValue: external ? true : null,
      ),
    ),
  );

  Future<void> deleteContribution(String id) =>
      guard(() => _api.contributions.contributionsDelete(id: id));
}
