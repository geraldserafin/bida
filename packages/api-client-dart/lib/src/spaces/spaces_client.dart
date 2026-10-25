// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/member.dart';
import '../models/my_space.dart';
import '../models/save_space.dart';
import '../models/set_role.dart';

part 'spaces_client.g.dart';

@RestApi()
abstract class SpacesClient {
  factory SpacesClient(Dio dio, {String? baseUrl}) = _SpacesClient;

  /// List my spaces.
  ///
  /// The personal space first, then the shared ones in the order the user joined them.
  @GET('/spaces')
  Future<List<MySpace>> spacesList();

  /// Create a shared space.
  ///
  /// The user becomes its owner.
  @POST('/spaces')
  Future<MySpace> spacesCreate({@Body() required SaveSpace body});

  /// Get the space of this request.
  ///
  /// Chosen by the `X-Space-Id` header, the user's personal space when it is missing.
  @GET('/spaces/current')
  Future<MySpace> spacesCurrent();

  /// Edit a space.
  ///
  /// Owners only. The default currency only applies to what is created afterwards.
  @PUT('/spaces/{id}')
  Future<MySpace> spacesUpdate({
    @Path('id') required String id,
    @Body() required SaveSpace body,
  });

  /// Delete a shared space with all its data.
  ///
  /// Owners only, and only when nobody else is a member: remove the others first.
  @DELETE('/spaces/{id}')
  Future<void> spacesDelete({@Path('id') required String id});

  /// List the members
  @GET('/spaces/{id}/members')
  Future<List<Member>> spacesMembers({@Path('id') required String id});

  /// Change the role of a member.
  ///
  /// Owners only. A space keeps at least one owner.
  @PUT('/spaces/{id}/members/{userId}')
  Future<Member> spacesSetRole({
    @Path('id') required String id,
    @Path('userId') required String userId,
    @Body() required SetRole body,
  });

  /// Remove a member.
  ///
  /// Owners only. What the member added stays, marked as by a former member.
  @DELETE('/spaces/{id}/members/{userId}')
  Future<void> spacesRemoveMember({
    @Path('id') required String id,
    @Path('userId') required String userId,
  });

  /// Leave a shared space.
  ///
  /// The last owner has to hand over the role first.
  @POST('/spaces/{id}/leave')
  Future<void> spacesLeave({@Path('id') required String id});
}
