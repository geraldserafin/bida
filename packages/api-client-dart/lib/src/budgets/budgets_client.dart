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

part 'budgets_client.g.dart';

@RestApi()
abstract class BudgetsClient {
  factory BudgetsClient(Dio dio, {String? baseUrl}) = _BudgetsClient;

  /// List periods.
  ///
  /// Newest first.
  @GET('/periods')
  Future<List<Period>> budgetsList();

  /// Create a period.
  ///
  /// Creates the period together with its initial envelopes.
  @POST('/periods')
  Future<PeriodDetail> budgetsCreate({@Body() required CreatePeriod body});

  /// Get the current period.
  ///
  /// The period with the latest start date.
  @GET('/periods/current')
  Future<PeriodDetail> budgetsCurrent();

  /// Get a period
  @GET('/periods/{id}')
  Future<PeriodDetail> budgetsGet({@Path('id') required String id});

  /// Delete a period.
  ///
  /// Also deletes its envelopes.
  @DELETE('/periods/{id}')
  Future<void> budgetsDelete({@Path('id') required String id});

  /// Set income and envelope amounts.
  ///
  /// A zero amount removes the envelope, or keeps it at zero when it already has expenses.
  @PUT('/periods/{id}/plan')
  Future<PeriodDetail> budgetsSetPlan({
    @Path('id') required String id,
    @Body() required SetPlan body,
  });

  /// Add an envelope to a period
  @POST('/periods/{id}/envelopes')
  Future<Envelope> budgetsAddEnvelope({
    @Path('id') required String id,
    @Body() required EnvelopePlan body,
  });
}
