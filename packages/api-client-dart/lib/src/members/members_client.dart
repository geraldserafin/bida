// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/household.dart';
import '../models/invitation.dart';
import '../models/invite.dart';
import '../models/leave.dart';
import '../models/member.dart';
import '../models/set_role.dart';

part 'members_client.g.dart';

@RestApi()
abstract class MembersClient {
  factory MembersClient(Dio dio, {String? baseUrl}) = _MembersClient;

  /// The members, with their share (F14)
  @GET('/households/{id}/members')
  Future<List<Member>> membersList({@Path('id') required String id});

  /// Give or take the owner role (F22).
  ///
  /// Owners only; there is always at least one owner.
  @PUT('/households/{id}/members/{userId}')
  Future<Member> membersSetRole({
    @Path('id') required String id,
    @Path('userId') required String userId,
    @Body() required SetRole body,
  });

  /// Remove a member.
  ///
  /// Owners only. Not with a negative share (freeze them instead); a positive share goes back to their wallet.
  @DELETE('/households/{id}/members/{userId}')
  Future<void> membersRemove({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });

  /// Freeze a member (F36).
  ///
  /// Owners only. A frozen member cannot spend and is removed once their share is no longer negative.
  @POST('/households/{id}/members/{userId}/freeze')
  Future<Member> membersFreeze({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });

  /// Unfreeze a member
  @POST('/households/{id}/members/{userId}/unfreeze')
  Future<Member> membersUnfreeze({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });

  /// Leave a household (F36).
  ///
  /// Not with a negative share. The last owner first gives the role to somebody; the last member deletes the household.
  @POST('/households/{id}/leave')
  Future<void> membersLeave({
    @Path('id') required String id,
    @Body() required Leave body,
  });

  /// Invite somebody by e-mail (F13).
  ///
  /// Owners only. Valid 7 days; inviting the address again renews it.
  @POST('/households/{id}/invitations')
  Future<Invitation> membersInvite({
    @Path('id') required String id,
    @Body() required Invite body,
  });

  /// Open invitations of a household.
  ///
  /// Owners only.
  @GET('/households/{id}/invitations')
  Future<List<Invitation>> membersInvitations({@Path('id') required String id});

  /// Revoke an invitation.
  ///
  /// Owners only.
  @DELETE('/households/{id}/invitations/{invitationId}')
  Future<void> membersRevoke({
    @Path('id') required String id,
    @Path('invitationId') required String invitationId,
  });

  /// Invitations for my address
  @GET('/invitations')
  Future<List<Invitation>> membersMine();

  /// Accept an invitation.
  ///
  /// The user becomes a member at once.
  @POST('/invitations/{id}/accept')
  Future<Household> membersAccept({@Path('id') required String id});

  /// Decline an invitation
  @POST('/invitations/{id}/decline')
  Future<void> membersDecline({@Path('id') required String id});
}
