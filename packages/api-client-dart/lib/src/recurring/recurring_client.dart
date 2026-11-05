// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/apply_result.dart';
import '../models/apply_rule.dart';
import '../models/recurring_rule.dart';
import '../models/save_rule.dart';

part 'recurring_client.g.dart';

@RestApi()
abstract class RecurringClient {
  factory RecurringClient(Dio dio, {String? baseUrl}) = _RecurringClient;

  /// Recurring rules.
  ///
  /// The user's incomes and transfers, and the expense rules of their households.
  @GET('/recurring-rules')
  Future<List<RecurringRule>> recurringList();

  /// Add a recurring rule (F25, F26, F27)
  @POST('/recurring-rules')
  Future<RecurringRule> recurringCreate({@Body() required SaveRule body});

  /// Edit a rule.
  ///
  /// Expense rules: their author or an owner.
  @PUT('/recurring-rules/{id}')
  Future<RecurringRule> recurringUpdate({
    @Path('id') required String id,
    @Body() required SaveRule body,
  });

  /// Delete a rule.
  ///
  /// What it made stays.
  @DELETE('/recurring-rules/{id}')
  Future<void> recurringDelete({@Path('id') required String id});

  /// Apply a rule early.
  ///
  /// Its next occurrence: an income (an estimated one with the real amount), or an expense in the current period.
  @POST('/recurring-rules/{id}/apply')
  Future<ApplyResult> recurringApply({
    @Path('id') required String id,
    @Body() required ApplyRule body,
  });

  /// Apply every expense rule of a household early.
  ///
  /// Their occurrences left in the current period.
  @POST('/households/{id}/recurring-rules/apply')
  Future<ApplyResult> recurringApplyAll({@Path('id') required String id});
}
