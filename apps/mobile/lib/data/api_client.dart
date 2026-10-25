import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'session_store.dart';

/// Base URL of the backend. 10.0.2.2 is the host machine as seen from the
/// Android emulator; override with `--dart-define=API_URL=...`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// The HTTP client every request goes through. The session goes with each
/// request: as a bearer token on a device, as the cookie in a browser.
Dio createDio({String baseUrl = apiUrl, SessionStore? session}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      // makes a browser send and accept the session cookie
      extra: {'withCredentials': kIsWeb},
    ),
  );
  if (session != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await session.token();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          // signing in is allowed to answer 401 (a wrong code); anything else
          // answering it means the session is gone
          final tag = error.response?.data is Map
              ? (error.response?.data as Map)['_tag']
              : null;
          if (error.response?.statusCode == 401 && tag == 'Unauthorized') {
            session.expire();
          }
          handler.next(error);
        },
      ),
    );
  }
  return dio;
}
