// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/category.dart';
import '../models/create_category.dart';
import '../models/update_category.dart';

part 'categories_client.g.dart';

@RestApi()
abstract class CategoriesClient {
  factory CategoriesClient(Dio dio, {String? baseUrl}) = _CategoriesClient;

  /// List categories
  @GET('/categories')
  Future<List<Category>> categoriesList();

  /// Create a category
  @POST('/categories')
  Future<Category> categoriesCreate({@Body() required CreateCategory body});

  /// Get a category
  @GET('/categories/{id}')
  Future<Category> categoriesGet({@Path('id') required String id});

  /// Update a category
  @PATCH('/categories/{id}')
  Future<Category> categoriesUpdate({
    @Path('id') required String id,
    @Body() required UpdateCategory body,
  });

  /// Delete a category.
  ///
  /// Fails with 409 while any envelope still uses the category.
  @DELETE('/categories/{id}')
  Future<void> categoriesDelete({@Path('id') required String id});
}
