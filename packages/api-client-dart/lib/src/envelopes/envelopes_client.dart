// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_envelope.dart';
import '../models/envelope.dart';
import '../models/update_envelope.dart';

part 'envelopes_client.g.dart';

@RestApi()
abstract class EnvelopesClient {
  factory EnvelopesClient(Dio dio, {String? baseUrl}) = _EnvelopesClient;

  /// List envelopes.
  ///
  /// Every envelope the user can see, top-level ones and their sub-envelopes, by name.
  @GET('/envelopes')
  Future<List<Envelope>> envelopesList();

  /// Create an envelope
  @POST('/envelopes')
  Future<Envelope> envelopesCreate({@Body() required CreateEnvelope body});

  /// Get an envelope
  @GET('/envelopes/{id}')
  Future<Envelope> envelopesGet({@Path('id') required String id});

  /// Edit an envelope
  @PUT('/envelopes/{id}')
  Future<Envelope> envelopesUpdate({
    @Path('id') required String id,
    @Body() required UpdateEnvelope body,
  });

  /// Delete an envelope.
  ///
  /// Removes its sub-envelopes, expenses and allocations too; the money allocated to it goes back to the pools of the people who put it in.
  @DELETE('/envelopes/{id}')
  Future<void> envelopesDelete({@Path('id') required String id});
}
