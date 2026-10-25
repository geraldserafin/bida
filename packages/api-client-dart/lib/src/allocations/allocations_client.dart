// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/allocation.dart';
import '../models/create_allocation.dart';
import '../models/update_allocation.dart';

part 'allocations_client.g.dart';

@RestApi()
abstract class AllocationsClient {
  factory AllocationsClient(Dio dio, {String? baseUrl}) = _AllocationsClient;

  /// List allocations.
  ///
  /// Of the envelope and, for a top-level one, its sub-envelopes (all envelopes when none is named). Newest first.
  @GET('/allocations')
  Future<List<Allocation>> allocationsList({
    @Query('envelopeId') String? envelopeId,
    @Query('from') String? from,
    @Query('to') String? to,
  });

  /// Put money into an envelope or take it out.
  ///
  /// A negative amount takes money back. Fails with 409 when an envelope would not have it, or when more would be assigned to sub-envelopes than the user put into the parent. A pool that goes below zero is allowed.
  @POST('/allocations')
  Future<Allocation> allocationsCreate({
    @Body() required CreateAllocation body,
  });

  /// Edit an allocation.
  ///
  /// Only the user who made it can.
  @PUT('/allocations/{id}')
  Future<Allocation> allocationsUpdate({
    @Path('id') required String id,
    @Body() required UpdateAllocation body,
  });

  /// Delete an allocation.
  ///
  /// Only the user who made it can.
  @DELETE('/allocations/{id}')
  Future<void> allocationsDelete({@Path('id') required String id});
}
