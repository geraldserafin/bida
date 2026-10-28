// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/recurring_income.dart';
import '../models/save_recurring_income.dart';

part 'recurring_incomes_client.g.dart';

@RestApi()
abstract class RecurringIncomesClient {
  factory RecurringIncomesClient(Dio dio, {String? baseUrl}) =
      _RecurringIncomesClient;

  /// List recurring incomes.
  ///
  /// The user's own, newest first.
  @GET('/recurring-incomes')
  Future<List<RecurringIncome>> recurringIncomesList();

  /// Create a recurring income
  @POST('/recurring-incomes')
  Future<RecurringIncome> recurringIncomesCreate({
    @Body() required SaveRecurringIncome body,
  });

  /// Edit a recurring income.
  ///
  /// Setting `active` to false pauses it.
  @PUT('/recurring-incomes/{id}')
  Future<RecurringIncome> recurringIncomesUpdate({
    @Path('id') required String id,
    @Body() required SaveRecurringIncome body,
  });

  /// Delete a recurring income.
  ///
  /// Income it already added is kept.
  @DELETE('/recurring-incomes/{id}')
  Future<void> recurringIncomesDelete({@Path('id') required String id});
}
