import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/api_exception.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/state/auth_state.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late SessionStore session;
  late AuthState auth;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend();
    session = SessionStore();
    auth = AuthState(AuthRepository(backend.dio(), session));
  });

  tearDown(() => auth.dispose());

  test('starts out not knowing, then learns it is signed in', () async {
    backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));
    expect(auth.status, AuthStatus.unknown);

    await auth.restore();

    expect(auth.status, AuthStatus.signedIn);
    expect(auth.email, 'ann@example.com');
  });

  test('or that it is not', () async {
    backend.on('GET /auth/me', (_) => Reply.error(401, 'Unauthorized'));

    await auth.restore();

    expect(auth.status, AuthStatus.signedOut);
  });

  test('an unreachable server leaves the question open', () async {
    backend.on('GET /auth/me', (_) => const Reply.unreachable());

    await auth.restore();

    expect(auth.status, AuthStatus.unknown);
    expect(auth.restoreError?.failure, ApiFailure.unreachable);

    backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));
    await auth.restore();
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.restoreError, isNull);
  });

  test('the token of an e-mailed link signs in', () async {
    backend.on(
      'POST /auth/magic-link/token',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );

    await auth.restore(linkToken: 'x' * 30);

    expect(auth.status, AuthStatus.signedIn);
    expect(backend.sent('GET /auth/me'), isEmpty);
  });

  test('a used link falls back to the session that may exist', () async {
    backend.on(
      'POST /auth/magic-link/token',
      (_) => Reply.error(401, 'InvalidLogin'),
    );
    backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));

    await auth.restore(linkToken: 'x' * 30);

    expect(auth.status, AuthStatus.signedIn);
  });

  test('a code signs in, signing out ends it', () async {
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );
    backend.on('POST /auth/logout', (_) => const Reply(null, status: 204));

    await auth.signInWithCode('ann@example.com', '123456');
    expect(auth.isSignedIn, isTrue);
    expect(await session.token(), 'secret');

    await auth.signOut();
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.email, isNull);
    expect(await session.token(), isNull);
  });

  test('a Google ID token signs in', () async {
    backend.on(
      'POST /auth/google',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );

    await auth.signInWithGoogle('g' * 30);

    expect(auth.isSignedIn, isTrue);
    expect(auth.email, 'ann@example.com');
  });

  test('a wrong code throws and stays signed out', () async {
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply.error(401, 'InvalidLogin'),
    );

    await expectLater(
      auth.signInWithCode('ann@example.com', '000000'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.isSignedIn, isFalse);
  });

  test('a session the server ended signs the user out', () async {
    backend.on('GET /auth/me', (_) => Reply(userJson('ann@example.com')));
    await auth.restore();

    session.expire();
    await Future<void>.delayed(Duration.zero);

    expect(auth.status, AuthStatus.signedOut);
  });
}
