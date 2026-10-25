// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/invitation.dart';
import '../models/invite.dart';
import '../models/member.dart';

part 'invitations_client.g.dart';

@RestApi()
abstract class InvitationsClient {
  factory InvitationsClient(Dio dio, {String? baseUrl}) = _InvitationsClient;

  /// Invite somebody by e-mail.
  ///
  /// Owners only, to shared spaces. The address gets an e-mail and sees the invitation once signed in with it. Inviting an address again renews its invitation and sets the new role.
  @POST('/spaces/{id}/invitations')
  Future<Invitation> invitationsInvite({
    @Path('id') required String id,
    @Body() required Invite body,
  });

  /// List the open invitations of a space.
  ///
  /// Owners only: those waiting for an answer and those waiting for approval.
  @GET('/spaces/{id}/invitations')
  Future<List<Invitation>> invitationsForSpace({
    @Path('id') required String id,
  });

  /// Revoke an invitation, or turn down an accepted one.
  ///
  /// Owners only.
  @DELETE('/spaces/{id}/invitations/{invitationId}')
  Future<void> invitationsRevoke({
    @Path('id') required String id,
    @Path('invitationId') required String invitationId,
  });

  /// Let in somebody who accepted an invitation.
  ///
  /// Owners only. The person becomes a member.
  @POST('/spaces/{id}/invitations/{invitationId}/approve')
  Future<Member> invitationsApprove({
    @Path('id') required String id,
    @Path('invitationId') required String invitationId,
  });

  /// Invitations for my address.
  ///
  /// Only those still waiting for my answer.
  @GET('/invitations')
  Future<List<Invitation>> invitationsMine();

  /// Accept an invitation.
  ///
  /// Does not give access yet: an owner of the space has to approve it, and is told by e-mail.
  @POST('/invitations/{invitationId}/accept')
  Future<Invitation> invitationsAccept({
    @Path('invitationId') required String invitationId,
  });

  /// Decline an invitation
  @POST('/invitations/{invitationId}/decline')
  Future<void> invitationsDecline({
    @Path('invitationId') required String invitationId,
  });
}
