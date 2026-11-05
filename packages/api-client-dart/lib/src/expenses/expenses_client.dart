// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/expense.dart';
import '../models/expense_result.dart';
import '../models/save_expense.dart';

part 'expenses_client.g.dart';

@RestApi()
abstract class ExpensesClient {
  factory ExpensesClient(Dio dio, {String? baseUrl}) = _ExpensesClient;

  /// Add an expense (F08).
  ///
  /// It has to fit the plan of the envelope and the balance of the current period. A plan that is too small grows by itself out of free money; otherwise 409 PlanTooSmall or NotEnoughInPeriod say what to bring from the wallet, and WalletWouldGoNegative asks to confirm a minus. Send the `decision` to go ahead.
  @POST('/households/{id}/expenses')
  Future<ExpenseResult> expensesCreate({
    @Path('id') required String id,
    @Body() required SaveExpense body,
  });

  /// Get an expense
  @GET('/expenses/{id}')
  Future<Expense> expensesGet({@Path('id') required String id});

  /// Edit an expense (F09).
  ///
  /// Its author, or an owner. In an open period through the steps of F08; in a closed one only the title.
  @PUT('/expenses/{id}')
  Future<ExpenseResult> expensesUpdate({
    @Path('id') required String id,
    @Body() required SaveExpense body,
  });

  /// Delete an expense.
  ///
  /// The money goes back to the piggy bank.
  @DELETE('/expenses/{id}')
  Future<void> expensesDelete({@Path('id') required String id});

  /// Expense history (F10).
  ///
  /// Of the user's households, newest first. 50 rows unless `limit` says otherwise (at most 200).
  @GET('/expenses')
  Future<List<Expense>> expensesList({
    @Query('householdId') String? householdId,
    @Query('periodId') String? periodId,
    @Query('envelopeId') String? envelopeId,
    @Query('authorId') String? authorId,
    @Query('forWhom') String? forWhom,
    @Query('from') String? from,
    @Query('to') String? to,
    @Query('limit') String? limit,
    @Query('offset') String? offset,
  });
}
