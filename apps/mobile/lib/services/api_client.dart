import 'package:bida_api_client/bida_api_client.dart';
import 'package:dio/dio.dart';

/// Base URL of the backend. 10.0.2.2 is the host machine as seen from the
/// Android emulator; override with `--dart-define=API_URL=...`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// Generated client for the backend (see packages/api-client-dart).
final api = BidaApi(
  Dio(
    BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  ),
);
