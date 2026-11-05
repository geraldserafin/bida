// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/confirm_income.dart';
import '../models/create_income.dart';
import '../models/remove_income.dart';
import '../models/update_income.dart';
import '../models/wallet.dart';
import '../models/wallet_entry.dart';

part 'wallet_client.g.dart';

@RestApi()
abstract class WalletClient {
  factory WalletClient(Dio dio, {String? baseUrl}) = _WalletClient;

  /// My wallet (F31).
  ///
  /// wpływy − przelewy + wycofania, as of now.
  @GET('/wallet')
  Future<Wallet> walletGet();

  /// Wallet history: incomes, transfers, withdrawals, newest first
  @GET('/wallet/entries')
  Future<List<WalletEntry>> walletEntries({
    @Query('limit') String? limit,
    @Query('offset') String? offset,
  });

  /// Add an income, certain or estimated
  @POST('/wallet/incomes')
  Future<WalletEntry> walletAddIncome({@Body() required CreateIncome body});

  /// Correct an income.
  ///
  /// Down below zero only with the `correction`: keep the minus, or take the missing amount back from a period first.
  @PUT('/wallet/incomes/{id}')
  Future<WalletEntry> walletUpdateIncome({
    @Path('id') required String id,
    @Body() required UpdateIncome body,
  });

  /// Confirm the real amount of an estimated income
  @POST('/wallet/incomes/{id}/confirm')
  Future<WalletEntry> walletConfirmIncome({
    @Path('id') required String id,
    @Body() required ConfirmIncome body,
  });

  /// Delete an income (a correction down)
  @POST('/wallet/incomes/{id}/remove')
  Future<void> walletRemoveIncome({
    @Path('id') required String id,
    @Body() required RemoveIncome body,
  });
}
