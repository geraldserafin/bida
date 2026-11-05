// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/closed_summary.dart';
import '../models/overview.dart';
import '../models/resolve_todo.dart';
import '../models/sync_result.dart';
import '../models/todo_item.dart';

part 'sync_client.g.dart';

@RestApi()
abstract class SyncClient {
  factory SyncClient(Dio dio, {String? baseUrl}) = _SyncClient;

  /// Do what is due (call on every app start).
  ///
  /// Nothing happens on the server in the background. In this order: closes the periods that ended (their rest goes on as nobody's money, their log entries go), opens the new ones with the plans copied, then the user's recurring incomes, their recurring transfers and the recurring expenses of their households. Running it again does nothing twice. What needs a decision goes to the to-do list.
  @POST('/sync')
  Future<SyncResult> syncRun();

  /// Closed periods the user has not seen yet (F35)
  @GET('/summaries')
  Future<List<ClosedSummary>> syncSummaries();

  /// The user has seen the summary of a closed period
  @POST('/periods/{id}/summary/seen')
  Future<void> syncSeen({@Path('id') required String id});

  /// The to-do list (F34).
  ///
  /// Matters of the user's wallet and of their households, oldest first.
  @GET('/todo')
  Future<List<TodoItem>> syncTodo();

  /// Deal with an item.
  ///
  /// Confirms the amount of an estimated income or expense, makes the transfer that could not go, or adds the expense that did not fit, with the same steps as F08. Gone for everybody once done.
  @POST('/todo/{id}/resolve')
  Future<void> syncResolve({
    @Path('id') required String id,
    @Body() required ResolveTodo body,
  });

  /// Leave an item as it is.
  ///
  /// An estimate stays as estimated; a skipped transfer or expense is not made.
  @POST('/todo/{id}/dismiss')
  Future<void> syncDismiss({@Path('id') required String id});

  /// The dashboard (F38).
  ///
  /// The wallet as of today; every household with its current piggy bank and what was spent from it between `from` and `to` (both included).
  @GET('/overview')
  Future<Overview> syncOverview({
    @Query('from') required String from,
    @Query('to') required String to,
  });
}
