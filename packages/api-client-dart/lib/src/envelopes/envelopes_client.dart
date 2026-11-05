// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/envelope.dart';
import '../models/period_summary.dart';
import '../models/save_envelope.dart';
import '../models/set_plan.dart';

part 'envelopes_client.g.dart';

@RestApi()
abstract class EnvelopesClient {
  factory EnvelopesClient(Dio dio, {String? baseUrl}) = _EnvelopesClient;

  /// Envelopes of a household, archived ones too
  @GET('/households/{id}/envelopes')
  Future<List<Envelope>> envelopesList({@Path('id') required String id});

  /// Add an envelope (F12).
  ///
  /// Any member.
  @POST('/households/{id}/envelopes')
  Future<Envelope> envelopesCreate({
    @Path('id') required String id,
    @Body() required SaveEnvelope body,
  });

  /// Rename or recolour an envelope
  @PUT('/envelopes/{id}')
  Future<Envelope> envelopesUpdate({
    @Path('id') required String id,
    @Body() required SaveEnvelope body,
  });

  /// Delete an envelope.
  ///
  /// Only one without expenses; archive the others.
  @DELETE('/envelopes/{id}')
  Future<void> envelopesDelete({@Path('id') required String id});

  /// Archive an envelope.
  ///
  /// Its expenses stay; its plans in the open periods drop to what was spent.
  @POST('/envelopes/{id}/archive')
  Future<Envelope> envelopesArchive({@Path('id') required String id});

  /// Bring an envelope back
  @POST('/envelopes/{id}/unarchive')
  Future<Envelope> envelopesUnarchive({@Path('id') required String id});

  /// Set the plan of an envelope in an open period (F19).
  ///
  /// Any member. Not below what was spent. The sum of plans may exceed the balance; the summary says so.
  @PUT('/periods/{id}/plans/{envelopeId}')
  Future<PeriodSummary> envelopesSetPlan({
    @Path('id') required String id,
    @Path('envelopeId') required String envelopeId,
    @Body() required SetPlan body,
  });
}
