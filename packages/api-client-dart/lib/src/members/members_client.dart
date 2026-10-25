// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/contribution.dart';
import '../models/member.dart';
import '../models/set_role.dart';

part 'members_client.g.dart';

@RestApi()
abstract class MembersClient {
  factory MembersClient(Dio dio, {String? baseUrl}) = _MembersClient;

  /// List the members of an envelope.
  ///
  /// For a sub-envelope these are the members of its parent. Any member can ask.
  @GET('/envelopes/{id}/members')
  Future<List<Member>> membersList({@Path('id') required String id});

  /// Change the role of a member.
  ///
  /// Owners only. An envelope always keeps at least one owner.
  @PUT('/envelopes/{id}/members/{userId}')
  Future<Member> membersSetRole({
    @Path('id') required String id,
    @Path('userId') required String userId,
    @Body() required SetRole body,
  });

  /// Remove a member, or leave an envelope.
  ///
  /// Owners remove anybody; anybody removes themselves. What a member put into the envelope stays in it, and so do their expenses. An envelope always keeps at least one owner.
  @DELETE('/envelopes/{id}/members/{userId}')
  Future<void> membersRemove({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });

  /// Who put how much into an envelope.
  ///
  /// Per member and per envelope: the envelope itself and its sub-envelopes, all time, net of what was taken back.
  @GET('/envelopes/{id}/contributions')
  Future<List<Contribution>> membersContributions({
    @Path('id') required String id,
  });
}
