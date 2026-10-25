import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/active_space.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/data/sharing_repository.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/contributions/contributions_screen.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:money_planner/state/planner_state.dart';
import 'package:money_planner/state/spaces_state.dart';
import 'package:provider/provider.dart';

import '../support/fake_backend.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pl'));
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('shows who paid how much, and adds a payment', (tester) async {
    final backend = FakeBackend()
      ..on('GET /categories', (_) => Reply([categoryJson('c1', 'Food')]))
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on('GET /periods', (_) => Reply([periodJson('p1', 'July')]))
      ..on(
        'GET /periods/p1/progress',
        (_) => Reply({...progressJson('p1', []), 'contributedMinor': 350000}),
      )
      ..on(
        'GET /spaces',
        (_) => Reply([mySpaceJson('s2', 'Dom', memberCount: 2)]),
      )
      ..on('GET /invitations', (_) => Reply([]))
      ..on(
        'GET /spaces/s2/members',
        (_) => Reply([
          memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
          memberJson('u2', 'bob@example.com', name: 'Bob'),
        ]),
      )
      ..on(
        'GET /periods/p1/contributions',
        (_) => Reply([
          contributionJson('k1', 200000, userId: 'u1'),
          contributionJson('k2', 100000, userId: 'u2'),
          contributionJson('k3', 50000),
        ]),
      )
      ..on(
        'POST /periods/p1/contributions',
        (_) => Reply(contributionJson('k4', 12000, userId: 'u1'), status: 201),
      );
    final planner = PlannerState(repository: backend.repository());
    final spaces = SpacesState(SharingRepository(backend.dio()), ActiveSpace());
    final auth = AuthState(AuthRepository(backend.dio(), SessionStore()));
    addTearDown(() {
      spaces.dispose();
      auth.dispose();
    });

    await tester.runAsync(() async {
      await planner.load();
      await spaces.load();
      await spaces.reloadMembers();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: SharingRepository(backend.dio())),
          ChangeNotifierProvider<PlannerState>.value(value: planner),
          ChangeNotifierProvider<SpacesState>.value(value: spaces),
          ChangeNotifierProvider<AuthState>.value(value: auth),
        ],
        child: const MaterialApp(
          locale: Locale('pl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ContributionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // totals per person, and the money from outside
    expect(find.text('Ann'), findsWidgets);
    expect(find.text('Bob'), findsWidgets);
    expect(find.text('Z zewnątrz'), findsWidgets);

    await tester.tap(find.text('Dodaj wpłatę'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '120,50');
    await tester.runAsync(() async {
      await tester.tap(find.text('Zapisz'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final body =
        backend.sent('POST /periods/p1/contributions').single.body as Map;
    expect(body['amountMinor'], 12050);
    expect(body.containsKey('external'), isFalse);
  });
}
