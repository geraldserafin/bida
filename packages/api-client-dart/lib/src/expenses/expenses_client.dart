// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_expense.dart';
import '../models/expense.dart';
import '../models/period_progress.dart';
import '../models/period_summary.dart';
import '../models/update_expense.dart';

part 'expenses_client.g.dart';

@RestApi()
abstract class ExpensesClient {
  factory ExpensesClient(Dio dio, {String? baseUrl}) = _ExpensesClient;

  /// Add an expense
  @POST('/expenses')
  Future<Expense> expensesCreate({@Body() required CreateExpense body});

  /// Get an expense
  @GET('/expenses/{id}')
  Future<Expense> expensesGet({@Path('id') required String id});

  /// Edit an expense
  @PUT('/expenses/{id}')
  Future<Expense> expensesUpdate({
    @Path('id') required String id,
    @Body() required UpdateExpense body,
  });

  /// Delete an expense
  @DELETE('/expenses/{id}')
  Future<void> expensesDelete({@Path('id') required String id});

  /// List the expenses of a period.
  ///
  /// Newest first. Defaults to 50 rows, at most 200.
  @GET('/periods/{periodId}/expenses')
  Future<List<Expense>> expensesListForPeriod({
    @Path('periodId') required String periodId,
    @Query('categoryId') String? categoryId,
    @Query('envelopeId') String? envelopeId,
    @Query('from') String? from,
    @Query('to') String? to,
    @Query('limit') String? limit,
    @Query('offset') String? offset,
  });

  /// Planned and spent for every period.
  ///
  /// Newest first. One call instead of one per period.
  @GET('/periods/summaries')
  Future<List<PeriodSummary>> expensesPeriodSummaries();

  /// Planned versus spent.
  ///
  /// Totals for the period and for each envelope.
  @GET('/periods/{periodId}/progress')
  Future<PeriodProgress> expensesProgress({
    @Path('periodId') required String periodId,
  });
}
