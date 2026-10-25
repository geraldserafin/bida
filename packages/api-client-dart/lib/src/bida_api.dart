// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'system/system_client.dart';
import 'spaces/spaces_client.dart';
import 'categories/categories_client.dart';
import 'budgets/budgets_client.dart';
import 'expenses/expenses_client.dart';
import 'recurring/recurring_client.dart';
import 'transfer/transfer_client.dart';

/// Money Planner API `v0.0.0`.
///
/// Everything except `/health` and the space list works inside a space. Pick it with the `X-Space-Id` header; without the header the default space is used. Amounts are integers in the minor unit of their currency (12.34 PLN is 1234).
class BidaApi {
  BidaApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0';

  SystemClient? _system;
  SpacesClient? _spaces;
  CategoriesClient? _categories;
  BudgetsClient? _budgets;
  ExpensesClient? _expenses;
  RecurringClient? _recurring;
  TransferClient? _transfer;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  SpacesClient get spaces => _spaces ??= SpacesClient(_dio, baseUrl: _baseUrl);

  CategoriesClient get categories =>
      _categories ??= CategoriesClient(_dio, baseUrl: _baseUrl);

  BudgetsClient get budgets =>
      _budgets ??= BudgetsClient(_dio, baseUrl: _baseUrl);

  ExpensesClient get expenses =>
      _expenses ??= ExpensesClient(_dio, baseUrl: _baseUrl);

  RecurringClient get recurring =>
      _recurring ??= RecurringClient(_dio, baseUrl: _baseUrl);

  TransferClient get transfer =>
      _transfer ??= TransferClient(_dio, baseUrl: _baseUrl);
}
