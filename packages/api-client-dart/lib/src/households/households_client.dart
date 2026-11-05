// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_household.dart';
import '../models/household.dart';
import '../models/log_entry.dart';
import '../models/move.dart';
import '../models/move_money.dart';
import '../models/move_result.dart';
import '../models/period.dart';
import '../models/period_summary.dart';
import '../models/rename_household.dart';
import '../models/set_cycle.dart';
import '../models/set_period_end.dart';

part 'households_client.g.dart';

@RestApi()
abstract class HouseholdsClient {
  factory HouseholdsClient(Dio dio, {String? baseUrl}) = _HouseholdsClient;

  /// My households (F06)
  @GET('/households')
  Future<List<Household>> householdsList();

  /// Create a household (F05).
  ///
  /// The user becomes its owner. It gets the default envelopes and opens its first, current period.
  @POST('/households')
  Future<Household> householdsCreate({@Body() required CreateHousehold body});

  /// Get a household
  @GET('/households/{id}')
  Future<Household> householdsGet({@Path('id') required String id});

  /// Rename a household.
  ///
  /// Owners only.
  @PUT('/households/{id}')
  Future<Household> householdsRename({
    @Path('id') required String id,
    @Body() required RenameHousehold body,
  });

  /// Delete a household.
  ///
  /// Owners only, and not while anybody has a negative share. Positive shares go back to the wallets.
  @DELETE('/households/{id}')
  Future<void> householdsDelete({@Path('id') required String id});

  /// Change the cycle of periods.
  ///
  /// Owners only. Applies from the end of the current period; an open next period is recounted.
  @PUT('/households/{id}/cycle')
  Future<Household> householdsSetCycle({
    @Path('id') required String id,
    @Body() required SetCycle body,
  });

  /// The periods of a household, newest first
  @GET('/households/{id}/periods')
  Future<List<Period>> householdsPeriods({@Path('id') required String id});

  /// Open the next period.
  ///
  /// Any member. Its plans are copied from the current one.
  @POST('/households/{id}/periods/next')
  Future<Period> householdsOpenNext({@Path('id') required String id});

  /// The piggy bank of a period (F16, F17, F18, F23)
  @GET('/periods/{id}')
  Future<PeriodSummary> householdsPeriod({
    @Path('id') required String id,
    @Query('forWhom') String? forWhom,
  });

  /// Move the end of the current period.
  ///
  /// Owners only. Not before today and leaving the next period at least a day. The next periods count from the new end; the money of the next period moves with it.
  @PUT('/periods/{id}/end')
  Future<Period> householdsSetEnd({
    @Path('id') required String id,
    @Body() required SetPeriodEnd body,
  });

  /// Transfers, withdrawals and the carry of a period
  @GET('/periods/{id}/moves')
  Future<List<Move>> householdsMoves({@Path('id') required String id});

  /// Transfer from the wallet into a period (F32).
  ///
  /// The current or the next one. Not more than the wallet holds, and not while the wallet is below zero.
  @POST('/periods/{id}/transfers')
  Future<MoveResult> householdsTransfer({
    @Path('id') required String id,
    @Body() required MoveMoney body,
  });

  /// Take money back to the wallet (F32).
  ///
  /// At most the user's share and at most what is in the piggy bank.
  @POST('/periods/{id}/withdrawals')
  Future<MoveResult> householdsWithdraw({
    @Path('id') required String id,
    @Body() required MoveMoney body,
  });

  /// The change log of the open periods (F37)
  @GET('/households/{id}/log')
  Future<List<LogEntry>> householdsLog({@Path('id') required String id});

  /// Undo a change.
  ///
  /// By somebody who may make that change. Refused when undoing it breaks a rule.
  @POST('/log/{id}/undo')
  Future<void> householdsUndo({@Path('id') required String id});
}
