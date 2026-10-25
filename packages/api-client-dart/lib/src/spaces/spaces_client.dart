// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/save_space.dart';
import '../models/space.dart';

part 'spaces_client.g.dart';

@RestApi()
abstract class SpacesClient {
  factory SpacesClient(Dio dio, {String? baseUrl}) = _SpacesClient;

  /// List spaces
  @GET('/spaces')
  Future<List<Space>> spacesList();

  /// Create a space
  @POST('/spaces')
  Future<Space> spacesCreate({@Body() required SaveSpace body});

  /// Get the space of this request.
  ///
  /// Chosen by the `X-Space-Id` header, the default space when it is missing.
  @GET('/spaces/current')
  Future<Space> spacesCurrent();

  /// Edit a space.
  ///
  /// The default currency only applies to what is created afterwards.
  @PUT('/spaces/{id}')
  Future<Space> spacesUpdate({
    @Path('id') required String id,
    @Body() required SaveSpace body,
  });
}
