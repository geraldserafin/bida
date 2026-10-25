import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:money_planner/data/planner_repository.dart';

/// What a route answers with.
class Reply {
  const Reply(this.body, {this.status = 200});

  /// The server cannot be reached at all.
  const Reply.unreachable() : body = null, status = -1;

  /// Anything `jsonEncode` accepts, or a [String] sent as plain text.
  final Object? body;
  final int status;

  /// An error body shaped like the API's: `{ "_tag": ..., ... }`.
  factory Reply.error(int status, String tag, [Map<String, Object?>? fields]) =>
      Reply({'_tag': tag, ...?fields}, status: status);
}

/// A request that reached the fake, with its body decoded.
class Seen {
  Seen(
    this.method,
    this.path,
    this.query,
    this.body,
    this.contentType, [
    this.headers = const {},
  ]);

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;
  final String? contentType;
  final Map<String, Object?> headers;

  String get route => '$method $path';
}

typedef Handler = Reply Function(Seen request);

/// Stands in for the server: answers by `METHOD /path` and remembers what was
/// asked. Runs the real generated client and Dio underneath, so tests also
/// cover how requests and responses are encoded.
class FakeBackend implements HttpClientAdapter {
  final Map<String, Handler> routes = {};
  final List<Seen> requests = [];

  /// Registers a route, e.g. `on('GET /categories', (_) => Reply([...]))`.
  void on(String route, Handler handler) => routes[route] = handler;

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'http://fake'))..httpClientAdapter = this;

  PlannerRepository repository({int pageSize = 200}) =>
      PlannerRepository(dio(), pageSize: pageSize);

  Iterable<Seen> sent(String route) => requests.where((r) => r.route == route);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final raw = requestStream == null
        ? ''
        : utf8.decode(await requestStream.expand((c) => c).toList());
    final contentType = options.contentType;
    final body = raw.isEmpty
        ? null
        : (contentType?.contains('json') ?? false)
        ? jsonDecode(raw)
        : raw;
    final seen = Seen(
      options.method,
      options.uri.path,
      options.uri.queryParameters,
      body,
      contentType,
      options.headers,
    );
    requests.add(seen);

    final handler = routes[seen.route];
    if (handler == null) {
      throw StateError('no fake route for ${seen.route}');
    }
    final reply = handler(seen);
    if (reply.status == -1) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'fake: unreachable',
      );
    }
    final text = reply.body is String
        ? reply.body as String
        : jsonEncode(reply.body);
    final isText = reply.body is String;
    return ResponseBody.fromString(
      reply.body == null ? '' : text,
      reply.status,
      headers: {
        Headers.contentTypeHeader: [
          isText ? 'text/csv' : Headers.jsonContentType,
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ----------------------------------------------------------- canned API bodies

Map<String, Object?> categoryJson(
  String id,
  String name, {
  String color = '#22C55E',
  String? icon,
}) => {
  'id': id,
  'name': name,
  'color': color,
  'icon': icon,
  'createdAt': '2026-07-01T00:00:00.000Z',
  'updatedAt': '2026-07-01T00:00:00.000Z',
};

Map<String, Object?> periodJson(
  String id,
  String name, {
  int incomeMinor = 500000,
  String currency = 'PLN',
  String start = '2026-07-01',
  String end = '2026-07-31',
}) => {
  'id': id,
  'name': name,
  'startDate': start,
  'endDate': end,
  'incomeMinor': incomeMinor,
  'currency': currency,
  'createdAt': '2026-07-01T00:00:00.000Z',
  'updatedAt': '2026-07-01T00:00:00.000Z',
};

Map<String, Object?> periodDetailJson(
  Map<String, Object?> period, {
  List<Map<String, Object?>> envelopes = const [],
}) => {
  'period': period,
  'envelopes': envelopes,
  'plannedMinor': 0,
  'unallocatedMinor': 0,
};

Map<String, Object?> envelopeProgressJson(
  String envelopeId,
  String categoryId, {
  required int plannedMinor,
  required int spentMinor,
}) => {
  'envelopeId': envelopeId,
  'categoryId': categoryId,
  'plannedMinor': plannedMinor,
  'spentMinor': spentMinor,
  'remainingMinor': plannedMinor - spentMinor,
};

Map<String, Object?> progressJson(
  String periodId,
  List<Map<String, Object?>> envelopes,
) => {
  'periodId': periodId,
  'incomeMinor': 0,
  'plannedMinor': 0,
  'spentMinor': 0,
  'remainingMinor': 0,
  'unallocatedMinor': 0,
  'envelopes': envelopes,
};

Map<String, Object?> expenseJson(
  String id,
  String envelopeId,
  int amountMinor, {
  String periodId = 'p1',
  String spentAt = '2026-07-03T10:30:00.000Z',
  String? note,
  String? recurringId,
}) => {
  'id': id,
  'envelopeId': envelopeId,
  'periodId': periodId,
  'amountMinor': amountMinor,
  'originalAmountMinor': null,
  'originalCurrency': null,
  'spentAt': spentAt,
  'note': note,
  'recurringId': recurringId,
  'createdAt': '2026-07-03T10:30:00.000Z',
  'updatedAt': '2026-07-03T10:30:00.000Z',
};

Map<String, Object?> userJson(String email) => {
  'id': '019845e1-682f-4b02-a706-3b2422d13aec',
  'email': email,
  'name': null,
  'createdAt': '2026-01-01T00:00:00Z',
};
