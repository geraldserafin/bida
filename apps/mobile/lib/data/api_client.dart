import 'package:dio/dio.dart';

/// Base URL of the backend. 10.0.2.2 is the host machine as seen from the
/// Android emulator; override with `--dart-define=API_URL=...`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// The HTTP client every request goes through.
Dio createDio({String baseUrl = apiUrl}) => Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ),
);
