import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/login/login_screen.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:provider/provider.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late AuthState auth;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend();
    auth = AuthState(AuthRepository(backend.dio(), SessionStore()));
  });

  tearDown(() => auth.dispose());

  Future<void> open(WidgetTester tester) => tester.pumpWidget(
    ChangeNotifierProvider<AuthState>.value(
      value: auth,
      child: const MaterialApp(
        locale: Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    ),
  );

  testWidgets('asks for the address, then for the code, then signs in', (
    tester,
  ) async {
    backend.on('POST /auth/magic-link', (_) => const Reply(null, status: 204));
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply({'user': userJson('ann@example.com'), 'token': 'secret'}),
    );
    await open(tester);

    // a malformed address is not sent
    await tester.enterText(find.byType(TextFormField), 'ann');
    await tester.tap(find.text('Wyślij kod'));
    await tester.pump();
    expect(find.text('Podaj poprawny adres e-mail'), findsOneWidget);
    expect(backend.requests, isEmpty);

    await tester.enterText(find.byType(TextFormField), ' ann@example.com ');
    await tester.runAsync(() async {
      await tester.tap(find.text('Wyślij kod'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.textContaining('ann@example.com'), findsOneWidget);
    expect(backend.sent('POST /auth/magic-link').single.body, {
      'email': 'ann@example.com',
    });

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.runAsync(() async {
      await tester.tap(find.text('Zaloguj'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(auth.isSignedIn, isTrue);
  });

  testWidgets('says when the code is wrong', (tester) async {
    backend.on('POST /auth/magic-link', (_) => const Reply(null, status: 204));
    backend.on(
      'POST /auth/magic-link/code',
      (_) => Reply.error(401, 'InvalidLogin'),
    );
    await open(tester);
    await tester.enterText(find.byType(TextFormField), 'ann@example.com');
    await tester.runAsync(() async {
      await tester.tap(find.text('Wyślij kod'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.runAsync(() async {
      await tester.tap(find.text('Zaloguj'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('Kod jest zły albo wygasł.'), findsOneWidget);
    expect(auth.isSignedIn, isFalse);
  });
}
