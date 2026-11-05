// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'system/system_client.dart';
import 'auth/auth_client.dart';
import 'account/account_client.dart';
import 'sync/sync_client.dart';
import 'wallet/wallet_client.dart';
import 'households/households_client.dart';
import 'members/members_client.dart';
import 'envelopes/envelopes_client.dart';
import 'expenses/expenses_client.dart';
import 'recurring/recurring_client.dart';

/// Money Planner API `v0.5.0`.
///
/// Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Amounts are integers in grosze (12.34 PLN is 1234). Call `POST /sync` when the app starts: nothing happens on the server in the background.
class BidaApi {
  BidaApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.5.0';

  SystemClient? _system;
  AuthClient? _auth;
  AccountClient? _account;
  SyncClient? _sync;
  WalletClient? _wallet;
  HouseholdsClient? _households;
  MembersClient? _members;
  EnvelopesClient? _envelopes;
  ExpensesClient? _expenses;
  RecurringClient? _recurring;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  AccountClient get account =>
      _account ??= AccountClient(_dio, baseUrl: _baseUrl);

  SyncClient get sync => _sync ??= SyncClient(_dio, baseUrl: _baseUrl);

  WalletClient get wallet => _wallet ??= WalletClient(_dio, baseUrl: _baseUrl);

  HouseholdsClient get households =>
      _households ??= HouseholdsClient(_dio, baseUrl: _baseUrl);

  MembersClient get members =>
      _members ??= MembersClient(_dio, baseUrl: _baseUrl);

  EnvelopesClient get envelopes =>
      _envelopes ??= EnvelopesClient(_dio, baseUrl: _baseUrl);

  ExpensesClient get expenses =>
      _expenses ??= ExpensesClient(_dio, baseUrl: _baseUrl);

  RecurringClient get recurring =>
      _recurring ??= RecurringClient(_dio, baseUrl: _baseUrl);
}
