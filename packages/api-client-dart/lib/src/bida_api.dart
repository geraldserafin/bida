// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'system/system_client.dart';
import 'categories/categories_client.dart';

/// Money Planner API `v0.0.0`
class BidaApi {
  BidaApi(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0';

  SystemClient? _system;
  CategoriesClient? _categories;

  SystemClient get system => _system ??= SystemClient(_dio, baseUrl: _baseUrl);

  CategoriesClient get categories =>
      _categories ??= CategoriesClient(_dio, baseUrl: _baseUrl);
}
