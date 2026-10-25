import 'package:dio/dio.dart';

/// Why a request to the backend failed, in terms the UI can react to.
enum ApiFailure {
  /// No connection, or the server did not answer in time.
  unreachable,
  notFound,

  /// The request clashes with the current data (e.g. category still in use).
  conflict,

  /// The server refused the values that were sent.
  invalid,
  server,
}

class ApiException implements Exception {
  const ApiException(this.failure, {this.tag, this.status});

  final ApiFailure failure;

  /// The `_tag` of the API's error body, e.g. `CategoryInUse`.
  final String? tag;
  final int? status;

  factory ApiException.from(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final tag = body is Map ? body['_tag'] as String? : null;
    final failure = switch (status) {
      null => ApiFailure.unreachable,
      404 => ApiFailure.notFound,
      409 => ApiFailure.conflict,
      400 || 422 => ApiFailure.invalid,
      _ => ApiFailure.server,
    };
    return ApiException(failure, tag: tag, status: status);
  }

  @override
  String toString() => 'ApiException($failure, status: $status, tag: $tag)';
}

/// Runs a request and turns Dio's errors into [ApiException]s.
Future<T> guard<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw ApiException.from(error);
  }
}
