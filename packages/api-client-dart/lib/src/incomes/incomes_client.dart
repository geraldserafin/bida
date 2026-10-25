// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/income.dart';
import '../models/save_income.dart';

part 'incomes_client.g.dart';

@RestApi()
abstract class IncomesClient {
  factory IncomesClient(Dio dio, {String? baseUrl}) = _IncomesClient;

  /// List the user's income.
  ///
  /// Newest first.
  @GET('/incomes')
  Future<List<Income>> incomesList({
    @Query('from') String? from,
    @Query('to') String? to,
  });

  /// Add income
  @POST('/incomes')
  Future<Income> incomesCreate({@Body() required SaveIncome body});

  /// Edit income
  @PUT('/incomes/{id}')
  Future<Income> incomesUpdate({
    @Path('id') required String id,
    @Body() required SaveIncome body,
  });

  /// Delete income
  @DELETE('/incomes/{id}')
  Future<void> incomesDelete({@Path('id') required String id});
}
