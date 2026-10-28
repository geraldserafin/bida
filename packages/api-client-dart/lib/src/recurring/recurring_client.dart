// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/apply_recurring.dart';
import '../models/apply_result.dart';
import '../models/recurring_rule.dart';
import '../models/save_recurring_rule.dart';

part 'recurring_client.g.dart';

@RestApi()
abstract class RecurringClient {
  factory RecurringClient(Dio dio, {String? baseUrl}) = _RecurringClient;

  /// List recurring rules.
  ///
  /// The user's own, newest first.
  @GET('/recurring-rules')
  Future<List<RecurringRule>> recurringList();

  /// Create a recurring rule
  @POST('/recurring-rules')
  Future<RecurringRule> recurringCreate({
    @Body() required SaveRecurringRule body,
  });

  /// Edit a recurring rule.
  ///
  /// Setting `active` to false pauses the rule.
  @PUT('/recurring-rules/{id}')
  Future<RecurringRule> recurringUpdate({
    @Path('id') required String id,
    @Body() required SaveRecurringRule body,
  });

  /// Delete a recurring rule.
  ///
  /// Expenses it already generated are kept.
  @DELETE('/recurring-rules/{id}')
  Future<void> recurringDelete({@Path('id') required String id});

  /// What applying would add.
  ///
  /// Counts of the recurring incomes, allocation rules and expenses that have not been applied to the stretch yet. Changes nothing.
  @GET('/recurring-rules/pending')
  Future<ApplyResult> recurringPending({
    @Query('from') required String from,
    @Query('to') required String to,
  });

  /// Apply the recurring rules to a stretch of time.
  ///
  /// Adds, for every active rule not applied for this `from` yet: the recurring incomes (dated on their day of the month), then the allocation rules (the same), then the expenses (dated today when today is in the stretch, else `from`). Safe to call repeatedly. An allocation the envelope cannot take is skipped and counted.
  @POST('/recurring-rules/apply')
  Future<ApplyResult> recurringApply({@Body() required ApplyRecurring body});
}
