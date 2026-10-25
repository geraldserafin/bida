// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_period.dart';
import '../models/envelope.dart';
import '../models/envelope_plan.dart';
import '../models/period.dart';
import '../models/period_detail.dart';
import '../models/set_plan.dart';
import '../models/update_period.dart';

part 'periods_client.g.dart';

@RestApi()
abstract class PeriodsClient {
  factory PeriodsClient(Dio dio, {String? baseUrl}) = _PeriodsClient;

  /// List periods.
  ///
  /// Newest first.
  @GET('/periods')
  Future<List<Period>> periodsList();

  /// Create a period.
  ///
  /// Creates the period together with its initial envelopes.
  @POST('/periods')
  Future<PeriodDetail> periodsCreate({@Body() required CreatePeriod body});

  /// Get the current period.
  ///
  /// The period with the latest start date.
  @GET('/periods/current')
  Future<PeriodDetail> periodsCurrent();

  /// Get a period
  @GET('/periods/{id}')
  Future<PeriodDetail> periodsGet({@Path('id') required String id});

  /// Edit a period.
  ///
  /// Changes the name and dates. Use the plan endpoint for money.
  @PUT('/periods/{id}')
  Future<PeriodDetail> periodsUpdate({
    @Path('id') required String id,
    @Body() required UpdatePeriod body,
  });

  /// Delete a period.
  ///
  /// Also deletes its envelopes.
  @DELETE('/periods/{id}')
  Future<void> periodsDelete({@Path('id') required String id});

  /// Set income and envelope amounts.
  ///
  /// A zero amount removes the envelope, or keeps it at zero when it already has expenses.
  @PUT('/periods/{id}/plan')
  Future<PeriodDetail> periodsSetPlan({
    @Path('id') required String id,
    @Body() required SetPlan body,
  });

  /// Add an envelope to a period
  @POST('/periods/{id}/envelopes')
  Future<Envelope> periodsAddEnvelope({
    @Path('id') required String id,
    @Body() required EnvelopePlan body,
  });
}
