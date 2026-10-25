// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_expense.dart';
import '../models/expense.dart';
import '../models/update_expense.dart';

part 'expenses_client.g.dart';

@RestApi()
abstract class ExpensesClient {
  factory ExpensesClient(Dio dio, {String? baseUrl}) = _ExpensesClient;

  /// Add an expense
  @POST('/expenses')
  Future<Expense> expensesCreate({@Body() required CreateExpense body});

  /// List expenses.
  ///
  /// Of the envelopes the user can see, newest first. Defaults to 50 rows, at most 200.
  @GET('/expenses')
  Future<List<Expense>> expensesList({
    @Query('envelopeId') String? envelopeId,
    @Query('from') String? from,
    @Query('to') String? to,
    @Query('limit') String? limit,
    @Query('offset') String? offset,
  });

  /// Get an expense
  @GET('/expenses/{id}')
  Future<Expense> expensesGet({@Path('id') required String id});

  /// Edit an expense.
  ///
  /// Its author and the owner of the envelope can. The new envelope has to be one the user can see.
  @PUT('/expenses/{id}')
  Future<Expense> expensesUpdate({
    @Path('id') required String id,
    @Body() required UpdateExpense body,
  });

  /// Delete an expense.
  ///
  /// Its author and the owner of the envelope can.
  @DELETE('/expenses/{id}')
  Future<void> expensesDelete({@Path('id') required String id});
}
