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

  /// Answers the requests every load makes about recurring rules and
  /// invitations with "none", for tests that are about something else.
  void noRules() {
    on('GET /recurring-rules', (_) => const Reply([]));
    on('GET /recurring-incomes', (_) => const Reply([]));
    on('GET /allocation-rules', (_) => const Reply([]));
    on('GET /invitations', (_) => const Reply([]));
    on(
      'GET /recurring-rules/pending',
      (_) => const Reply({
        'incomes': 0,
        'allocations': 0,
        'expenses': 0,
        'skipped': 0,
      }),
    );
  }

  /// Registers a route, e.g. `on('GET /envelopes', (_) => Reply([...]))`.
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

const _stamp = '2026-07-01T00:00:00.000Z';

Map<String, Object?> envelopeJson(
  String id,
  String name, {
  String? parentId,
  String color = '#22C55E',
  String? icon,
}) => {
  'id': id,
  'ownerId': 'u1',
  'parentId': parentId,
  'name': name,
  'color': color,
  'icon': icon,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> figuresJson(
  String envelopeId, {
  String? parentId,
  int opening = 0,
  int allocated = 0,
  int spent = 0,
  int? balance,
  int? free,
  String role = 'owner',
  int memberCount = 1,
}) {
  final left = balance ?? opening + allocated - spent;
  return {
    'envelopeId': envelopeId,
    'parentId': parentId,
    'openingMinor': opening,
    'allocatedMinor': allocated,
    'spentMinor': spent,
    'balanceMinor': left,
    'freeMinor': free ?? left,
    'role': role,
    'memberCount': memberCount,
  };
}

Map<String, Object?> overviewJson({
  String from = '2026-08-01',
  String to = '2026-08-31',
  int income = 0,
  int allocated = 0,
  int spent = 0,
  int pool = 0,
  List<Map<String, Object?>> envelopes = const [],
}) => {
  'from': from,
  'to': to,
  'incomeMinor': income,
  'allocatedMinor': allocated,
  'spentMinor': spent,
  'poolMinor': pool,
  'envelopes': envelopes,
};

Map<String, Object?> monthSummaryJson(
  String from,
  String to, {
  int income = 0,
  int allocated = 0,
  int spent = 0,
}) => {
  'from': from,
  'to': to,
  'incomeMinor': income,
  'allocatedMinor': allocated,
  'spentMinor': spent,
};

Map<String, Object?> allocationJson(
  String id,
  String envelopeId,
  int amountMinor, {
  String madeOn = '2026-08-02',
  String? note,
}) => {
  'id': id,
  'envelopeId': envelopeId,
  'userId': 'u1',
  'amountMinor': amountMinor,
  'madeOn': madeOn,
  'note': note,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> incomeJson(
  String id,
  int amountMinor, {
  String receivedOn = '2026-08-01',
  String? note,
}) => {
  'id': id,
  'userId': 'u1',
  'amountMinor': amountMinor,
  'receivedOn': receivedOn,
  'note': note,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> expenseJson(
  String id,
  String envelopeId,
  int amountMinor, {
  String spentAt = '2026-08-03T10:30:00.000Z',
  String? note,
  String? recurringId,
}) => {
  'id': id,
  'envelopeId': envelopeId,
  'createdBy': 'u1',
  'amountMinor': amountMinor,
  'spentAt': spentAt,
  'note': note,
  'recurringId': recurringId,
  'createdAt': '2026-08-03T10:30:00.000Z',
  'updatedAt': '2026-08-03T10:30:00.000Z',
};

Map<String, Object?> ruleJson(
  String id,
  String envelopeId,
  int amountMinor, {
  String frequency = 'monthly',
  String? note,
  bool active = true,
}) => {
  'id': id,
  'userId': 'u1',
  'envelopeId': envelopeId,
  'amountMinor': amountMinor,
  'frequency': frequency,
  'note': note,
  'active': active,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> memberJson(
  String userId,
  String email, {
  String? name,
  String role = 'member',
}) => {
  'userId': userId,
  'email': email,
  'name': name,
  'role': role,
  'joinedAt': _stamp,
};

Map<String, Object?> contributionJson(
  String envelopeId,
  String userId,
  int amountMinor,
) => {'envelopeId': envelopeId, 'userId': userId, 'amountMinor': amountMinor};

Map<String, Object?> invitationJson(
  String id,
  String envelopeId,
  String email, {
  String envelopeName = 'Home',
  String status = 'invited',
  String role = 'member',
  String? invitedBy = 'ann@example.com',
}) => {
  'id': id,
  'envelopeId': envelopeId,
  'envelopeName': envelopeName,
  'email': email,
  'role': role,
  'status': status,
  'invitedBy': invitedBy == null ? null : {'email': invitedBy, 'name': null},
  'acceptedBy': null,
  'expiresAt': '2026-11-01T00:00:00.000Z',
  'createdAt': _stamp,
};

Map<String, Object?> recurringIncomeJson(
  String id,
  int amountMinor,
  int dayOfMonth, {
  String? note,
  bool active = true,
}) => {
  'id': id,
  'userId': 'u1',
  'amountMinor': amountMinor,
  'dayOfMonth': dayOfMonth,
  'note': note,
  'active': active,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> allocationRuleJson(
  String id,
  String envelopeId,
  int amountMinor,
  int dayOfMonth, {
  String? note,
  bool active = true,
}) => {
  'id': id,
  'userId': 'u1',
  'envelopeId': envelopeId,
  'amountMinor': amountMinor,
  'dayOfMonth': dayOfMonth,
  'note': note,
  'active': active,
  'createdAt': _stamp,
  'updatedAt': _stamp,
};

Map<String, Object?> userJson(String email) => {
  'id': '019845e1-682f-4b02-a706-3b2422d13aec',
  'email': email,
  'name': null,
  'createdAt': '2026-01-01T00:00:00Z',
};
