// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'system/system_client.dart';
import 'auth/auth_client.dart';
import 'envelopes/envelopes_client.dart';
import 'allocations/allocations_client.dart';
import 'incomes/incomes_client.dart';
import 'expenses/expenses_client.dart';
import 'recurring/recurring_client.dart';
import 'overview/overview_client.dart';
import 'transfer/transfer_client.dart';

/// Money Planner API `v0.0.0`.
///
/// Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Amounts are integers in grosze (12.34 PLN is 1234).
class BidaApi {
  BidaApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0';

  SystemClient? _system;
  AuthClient? _auth;
  EnvelopesClient? _envelopes;
  AllocationsClient? _allocations;
  IncomesClient? _incomes;
  ExpensesClient? _expenses;
  RecurringClient? _recurring;
  OverviewClient? _overview;
  TransferClient? _transfer;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  EnvelopesClient get envelopes =>
      _envelopes ??= EnvelopesClient(_dio, baseUrl: _baseUrl);

  AllocationsClient get allocations =>
      _allocations ??= AllocationsClient(_dio, baseUrl: _baseUrl);

  IncomesClient get incomes =>
      _incomes ??= IncomesClient(_dio, baseUrl: _baseUrl);

  ExpensesClient get expenses =>
      _expenses ??= ExpensesClient(_dio, baseUrl: _baseUrl);

  RecurringClient get recurring =>
      _recurring ??= RecurringClient(_dio, baseUrl: _baseUrl);

  OverviewClient get overview =>
      _overview ??= OverviewClient(_dio, baseUrl: _baseUrl);

  TransferClient get transfer =>
      _transfer ??= TransferClient(_dio, baseUrl: _baseUrl);
}
