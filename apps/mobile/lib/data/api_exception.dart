import 'package:dio/dio.dart';

/// Why a request to the backend failed, in terms the UI can react to.
enum ApiFailure {
  /// No connection, or the server did not answer in time.
  unreachable,
  notFound,

  /// The request clashes with the current data (e.g. not enough money in an envelope).
  conflict,

  /// The server refused the values that were sent.
  invalid,
  server,

  /// Not signed in, or the session is over.
  unauthorized,

  /// Too many requests; wait before trying again.
  rateLimited,
}

class ApiException implements Exception {
  const ApiException(
    this.failure, {
    this.tag,
    this.status,
    this.details = const {},
  });

  final ApiFailure failure;

  /// The `_tag` of the API's error body, e.g. `NotEnoughMoney`.
  final String? tag;
  final int? status;

  /// The other fields of the error body, e.g. `availableMinor` of `NotEnoughMoney`.
  final Map<String, Object?> details;

  /// For `NotEnoughMoney`: how much the envelope can give, in grosze.
  int? get availableMinor => details['availableMinor'] as int?;

  factory ApiException.from(DioException error) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final tag = body is Map ? body['_tag'] as String? : null;
    final failure = switch (status) {
      null => ApiFailure.unreachable,
      404 => ApiFailure.notFound,
      401 => ApiFailure.unauthorized,
      409 => ApiFailure.conflict,
      429 => ApiFailure.rateLimited,
      400 || 422 => ApiFailure.invalid,
      _ => ApiFailure.server,
    };
    return ApiException(
      failure,
      tag: tag,
      status: status,
      details: body is Map ? body.cast<String, Object?>() : const {},
    );
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
