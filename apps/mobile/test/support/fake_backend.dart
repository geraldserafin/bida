import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:money_planner/data/budget_repository.dart';

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

  /// Answers what every load asks for with a signed-in user with one
  /// household "Dom", an empty to-do list and no invitations.
  void household({int walletMinor = 0, List<Object?> todo = const []}) {
    on('POST /sync', (_) => Reply(syncJson()));
    on('GET /households', (_) => Reply([householdJson()]));
    on('GET /overview', (_) => Reply(overviewJson(walletMinor: walletMinor)));
    on('GET /todo', (_) => Reply(todo));
    on('GET /invitations', (_) => const Reply([]));
    on('GET /periods/p1', (_) => Reply(summaryJson()));
    on(
      'GET /households/h1/envelopes',
      (_) => Reply([envelopeJson('e1', 'Jedzenie')]),
    );
    on(
      'GET /households/h1/members',
      (_) => Reply([memberJson('u1', 'ann@example.com')]),
    );
  }

  /// Registers a route, e.g. `on('GET /envelopes', (_) => Reply([...]))`.
  void on(String route, Handler handler) => routes[route] = handler;

  Dio dio() =>
      Dio(BaseOptions(baseUrl: 'http://fake'))..httpClientAdapter = this;

  BudgetRepository repository() => BudgetRepository(dio());

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

Map<String, Object?> periodJson({
  String id = 'p1',
  String status = 'current',
  String startsOn = '2026-07-01',
  String endsOn = '2026-07-31',
}) => {
  'id': id,
  'householdId': 'h1',
  'startsOn': startsOn,
  'endsOn': endsOn,
  'status': status,
};

Map<String, Object?> householdJson({int balanceMinor = 0}) => {
  'id': 'h1',
  'name': 'Dom',
  'timeZone': 'Europe/Warsaw',
  'cycle': {'kind': 'monthly', 'day': 1, 'weeks': null, 'anchorOn': null},
  'role': 'owner',
  'frozen': false,
  'memberCount': 1,
  'current': periodJson(),
  'next': null,
  'balanceMinor': balanceMinor,
  'createdAt': _stamp,
};

Map<String, Object?> walletJson({int balanceMinor = 0, int unconfirmed = 0}) =>
    {'balanceMinor': balanceMinor, 'unconfirmedMinor': unconfirmed};

Map<String, Object?> overviewJson({
  int walletMinor = 0,
  bool households = true,
}) => {
  'wallet': walletJson(balanceMinor: walletMinor),
  'households': [
    if (households)
      {
        'id': 'h1',
        'name': 'Dom',
        'current': periodJson(),
        'balanceMinor': 0,
        'freeMinor': 0,
        'spentMinor': 0,
      },
  ],
  'todo': 0,
};

Map<String, Object?> syncJson({List<Object?> summaries = const []}) => {
  'closedPeriods': 0,
  'openedPeriods': 0,
  'incomes': 0,
  'transfers': 0,
  'expenses': 0,
  'todo': 0,
  'summaries': summaries,
};

Map<String, Object?> envelopeJson(String id, String name) => {
  'id': id,
  'householdId': 'h1',
  'name': name,
  'color': '#22C55E',
  'icon': null,
  'position': 0,
  'archived': false,
};

Map<String, Object?> figuresJson(
  String id,
  String name, {
  int plan = 0,
  int spent = 0,
}) => {
  'envelopeId': id,
  'name': name,
  'color': '#22C55E',
  'icon': null,
  'archived': false,
  'planMinor': plan,
  'manualMinor': plan,
  'recurringMinor': 0,
  'spentMinor': spent,
  'leftMinor': plan - spent,
  'sharePercent': 0,
  'previousSpentMinor': null,
};

Map<String, Object?> summaryJson({
  int balanceMinor = 0,
  List<Object?>? envelopes,
}) => {
  'period': periodJson(),
  'transfersMinor': balanceMinor,
  'withdrawalsMinor': 0,
  'carryInMinor': 0,
  'spentMinor': 0,
  'estimatedSpentMinor': 0,
  'balanceMinor': balanceMinor,
  'plansTotalMinor': 0,
  'remainingPlansMinor': 0,
  'freeMinor': balanceMinor,
  'plansExceedBalance': false,
  'carryOutMinor': null,
  'nobodyMinor': 0,
  'nobodyLeftMinor': 0,
  'envelopes': envelopes ?? [figuresJson('e1', 'Jedzenie')],
  'shares': [
    {
      'userId': 'u1',
      'name': 'ann@example.com',
      'member': true,
      'transfersMinor': balanceMinor,
      'withdrawalsMinor': 0,
      'forfeitedMinor': 0,
      'spentMinor': 0,
      'fromNobodyMinor': 0,
      'shareMinor': balanceMinor,
    },
  ],
  'forecast': null,
};

Map<String, Object?> memberJson(String id, String email) => {
  'userId': id,
  'email': email,
  'name': null,
  'role': 'owner',
  'frozen': false,
  'joinedAt': _stamp,
  'shareMinor': 0,
};

Map<String, Object?> expenseResultJson(int amountMinor) => {
  'expense': {
    'id': 'x1',
    'householdId': 'h1',
    'periodId': 'p1',
    'envelopeId': 'e1',
    'createdBy': 'u1',
    'authorName': 'ann@example.com',
    'amountMinor': amountMinor,
    'spentAt': _stamp,
    'title': null,
    'forWhom': null,
    'forWhomUserId': null,
    'forWhomName': null,
    'estimated': false,
    'ruleId': null,
    'createdAt': _stamp,
    'updatedAt': _stamp,
  },
  'transferredMinor': 0,
  'raisedPlanMinor': 0,
  'plansExceedBalance': false,
};

Map<String, Object?> todoJson(
  String id,
  String kind, {
  int amountMinor = 1000,
}) => {
  'id': id,
  'kind': kind,
  'householdId': kind.startsWith('expense') ? 'h1' : null,
  'householdName': kind.startsWith('expense') ? 'Dom' : null,
  'periodId': 'p1',
  'ruleId': 'r1',
  'refId': null,
  'envelopeId': 'e1',
  'occurrenceOn': '2026-07-05',
  'amountMinor': amountMinor,
  'title': 'Czynsz',
  'createdAt': _stamp,
};

Map<String, Object?> userJson(String email) => {
  'id': '019845e1-682f-4b02-a706-3b2422d13aec',
  'email': email,
  'name': null,
  'createdAt': '2026-01-01T00:00:00Z',
};
