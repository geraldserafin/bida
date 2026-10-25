import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_client.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/google_credential.dart';
import 'package:money_planner/data/session_store.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late SessionStore session;
  late AuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend();
    session = SessionStore();
    repository = AuthRepository(backend.dio(), session);
  });

  test('asks for a link by e-mail', () async {
    backend.on('POST /auth/magic-link', (_) => const Reply(null, status: 204));

    await repository.requestLink('ann@example.com');

    expect(backend.sent('POST /auth/magic-link').single.body, {
      'email': 'ann@example.com',
    });
  });

  test('a code signs in and the token is kept', () async {
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );

    final email = await repository.signInWithCode('ann@example.com', '123456');

    expect(email, 'ann@example.com');
    expect(await session.token(), 'secret');
    expect(backend.sent('POST /auth/magic-link/code').single.body, {
      'email': 'ann@example.com',
      'code': '123456',
      'transport': 'token',
    });
  });

  test('a Google ID token signs in and the token is kept', () async {
    backend.on(
      'POST /auth/google',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );

    final email = await repository.signInWithGoogle(GoogleIdToken('g' * 30));

    expect(email, 'ann@example.com');
    expect(await session.token(), 'secret');
    expect(backend.sent('POST /auth/google').single.body, {
      'idToken': 'g' * 30,
      'transport': 'token',
    });
  });

  test('a browser signs in with the access token from Google', () async {
    backend.on(
      'POST /auth/google/access-token',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );

    final email = await repository.signInWithGoogle(
      GoogleAccessToken('a' * 30),
    );

    expect(email, 'ann@example.com');
    expect(backend.sent('POST /auth/google/access-token').single.body, {
      'accessToken': 'a' * 30,
      'transport': 'token',
    });
  });

  test('a wrong code is a failed sign-in with its tag', () async {
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply.error(401, 'InvalidLogin'),
    );

    await expectLater(
      repository.signInWithCode('ann@example.com', '000000'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.failure, 'failure', ApiFailure.unauthorized)
            .having((e) => e.tag, 'tag', 'InvalidLogin'),
      ),
    );
    expect(await session.token(), isNull);
  });

  test('a browser asks for the cookie and keeps no token', () async {
    final browser = SessionStore(web: true);
    backend.on(
      'POST /auth/magic-link/token',
      (_) => Reply({'user': userJson('ann@example.com')}),
    );

    final email = await AuthRepository(
      backend.dio(),
      browser,
      transport: api.Transport.cookie,
    ).signInWithLinkToken('x' * 30);

    expect(email, 'ann@example.com');
    expect(await browser.token(), isNull);
    expect(
      (backend.sent('POST /auth/magic-link/token').single.body
          as Map)['transport'],
      'cookie',
    );
  });

  group('who is signed in', () {
    test('the e-mail of the user', () async {
      backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));

      expect(await repository.currentUser(), 'ann@example.com');
    });

    test('nobody when the server says so', () async {
      backend.on('GET /auth/me', (_) => Reply.error(401, 'Unauthorized'));

      expect(await repository.currentUser(), isNull);
    });

    test('an unreachable server is an error, not a sign-out', () async {
      backend.on('GET /auth/me', (_) => const Reply.unreachable());

      await expectLater(
        repository.currentUser(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.unreachable,
          ),
        ),
      );
    });
  });

  test('signing out forgets the token even if the server is gone', () async {
    await session.save('secret');
    backend.on('POST /auth/logout', (_) => const Reply.unreachable());

    await repository.signOut();

    expect(await session.token(), isNull);
  });

  group('the HTTP client', () {
    test('sends the token on every request', () async {
      await session.save('secret');
      backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));
      final dio = createDio(baseUrl: 'http://fake', session: session)
        ..httpClientAdapter = backend;

      await dio.get<Object?>('/auth/me');

      expect(
        backend.sent('GET /auth/me').single.headers['Authorization'],
        'Bearer secret',
      );
    });

    test('tells the session when the server refuses it', () async {
      backend.on('GET /categories', (_) => Reply.error(401, 'Unauthorized'));
      final dio = createDio(baseUrl: 'http://fake', session: session)
        ..httpClientAdapter = backend;
      var expired = 0;
      session.onExpired.listen((_) => expired++);

      await expectLater(dio.get<Object?>('/categories'), throwsA(anything));
      await Future<void>.delayed(Duration.zero);

      expect(expired, 1);
    });

    test('a wrong code does not end the session', () async {
      backend.on(
        'POST /auth/magic-link/code',
        (_) => Reply.error(401, 'InvalidLogin'),
      );
      final dio = createDio(baseUrl: 'http://fake', session: session)
        ..httpClientAdapter = backend;
      var expired = 0;
      session.onExpired.listen((_) => expired++);

      await expectLater(
        dio.post<Object?>('/auth/magic-link/code', data: {}),
        throwsA(anything),
      );
      await Future<void>.delayed(Duration.zero);

      expect(expired, 0);
    });
  });
}
