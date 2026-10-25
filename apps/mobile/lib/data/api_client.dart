import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'active_space.dart';
import 'session_store.dart';

/// Base URL of the backend. 10.0.2.2 is the host machine as seen from the
/// Android emulator; override with `--dart-define=API_URL=...`.
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

/// The HTTP client every request goes through. The session goes with each
/// request: as a bearer token on a device, as the cookie in a browser. With
/// [space] the requests name the budget they work in.
Dio createDio({
  String baseUrl = apiUrl,
  SessionStore? session,
  ActiveSpace? space,
}) {
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
  if (space != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final id = space.id;
          if (id != null) options.headers['X-Space-Id'] = id;
          handler.next(options);
        },
        onError: (error, handler) {
          final body = error.response?.data;
          final tag = body is Map ? body['_tag'] : null;
          // asked for a budget the user is not in (any more)
          if (error.response?.statusCode == 404 &&
              tag == 'SpaceNotFound' &&
              error.requestOptions.headers.containsKey('X-Space-Id')) {
            space.missing();
          }
          handler.next(error);
        },
      ),
    );
  }
  return dio;
}
