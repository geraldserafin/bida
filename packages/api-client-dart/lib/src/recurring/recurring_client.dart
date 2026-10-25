// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/apply_result.dart';
import '../models/currency.dart';
import '../models/envelope_plan.dart';
import '../models/recurring_rule.dart';
import '../models/save_recurring_rule.dart';

part 'recurring_client.g.dart';

@RestApi()
abstract class RecurringClient {
  factory RecurringClient(Dio dio, {String? baseUrl}) = _RecurringClient;

  /// List recurring rules.
  ///
  /// Newest first.
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

  /// Suggested envelope amounts.
  ///
  /// Sum of the active rules in one currency per category, to prefill a new period's plan.
  @GET('/recurring-rules/suggested-plan')
  Future<List<EnvelopePlan>> recurringSuggestedPlan({
    @Query('currency') Currency? currency,
  });

  /// Apply recurring rules to a period.
  ///
  /// Adds one expense for every active rule not applied in this period yet, creating a missing envelope with the rule's amount as its plan. Safe to call repeatedly.
  @POST('/periods/{periodId}/recurring/apply')
  Future<ApplyResult> recurringApply({
    @Path('periodId') required String periodId,
  });
}
