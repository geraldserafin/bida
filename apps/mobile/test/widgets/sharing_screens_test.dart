import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/active_space.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/data/sharing_repository.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/onboarding/first_run_prompt.dart';
import 'package:money_planner/screens/spaces/space_detail_screen.dart';
import 'package:money_planner/screens/spaces/spaces_screen.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:money_planner/state/spaces_state.dart';
import 'package:provider/provider.dart';

import '../support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late SpacesState spaces;
  late AuthState auth;

  setUpAll(() => initializeDateFormatting('pl'));

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend();
    spaces = SpacesState(SharingRepository(backend.dio()), ActiveSpace());
    auth = AuthState(AuthRepository(backend.dio(), SessionStore()));
  });

  tearDown(() {
    spaces.dispose();
    auth.dispose();
  });

  Widget host(Widget home) => MultiProvider(
    providers: [
      Provider.value(value: SharingRepository(backend.dio())),
      ChangeNotifierProvider<SpacesState>.value(value: spaces),
      ChangeNotifierProvider<AuthState>.value(value: auth),
    ],
    child: MaterialApp(
      locale: const Locale('pl'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  /// Loads the budgets the fake server lists, then waits for the screen.
  Future<void> load(WidgetTester tester) async {
    await tester.runAsync(spaces.load);
    await tester.pump();
  }

  testWidgets('lists the budgets and answers an invitation', (tester) async {
    backend.on(
      'GET /spaces',
      (_) => Reply([
        mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
        mySpaceJson('s2', 'Dom', role: 'member', memberCount: 2),
      ]),
    );
    backend.on(
      'GET /invitations',
      (_) => Reply([invitationJson('i1', spaceName: 'Wakacje')]),
    );
    backend.on(
      'POST /invitations/i1/accept',
      (_) => Reply(invitationJson('i1', status: 'accepted')),
    );
    backend.on('GET /spaces/s2/members', (_) => Reply([]));
    await tester.pumpWidget(host(const SpacesScreen()));
    await load(tester);

    expect(find.text('Mój budżet'), findsOneWidget);
    expect(find.text('Dom'), findsOneWidget);
    expect(find.textContaining('Wakacje'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Przyjmij'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(backend.sent('POST /invitations/i1/accept'), hasLength(1));
    expect(find.textContaining('Wakacje'), findsNothing);
    expect(
      find.text(
        'Przyjęto. Właściciel musi jeszcze zatwierdzić Twoje dołączenie.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an owner sees the invitations and can approve one', (
    tester,
  ) async {
    backend.on(
      'GET /spaces',
      (_) => Reply([
        mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
        mySpaceJson('s2', 'Dom', memberCount: 2),
      ]),
    );
    backend.on('GET /invitations', (_) => Reply([]));
    backend.on(
      'GET /spaces/s2/members',
      (_) => Reply([
        memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
        memberJson('u2', 'bob@example.com'),
      ]),
    );
    backend.on(
      'GET /spaces/s2/invitations',
      (_) => Reply([
        invitationJson('i1', status: 'accepted', email: 'cat@example.com'),
      ]),
    );
    backend.on(
      'POST /spaces/s2/invitations/i1/approve',
      (_) => Reply(memberJson('u3', 'cat@example.com')),
    );
    await tester.pumpWidget(host(const SpaceDetailScreen(spaceId: 's2')));
    await load(tester);
    await tester.pumpAndSettle();

    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('bob@example.com'), findsWidgets);
    expect(find.text('cat@example.com'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Zatwierdź'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(
      backend.sent('POST /spaces/s2/invitations/i1/approve'),
      hasLength(1),
    );
  });

  testWidgets('a member can leave but not manage the budget', (tester) async {
    backend.on(
      'GET /spaces',
      (_) => Reply([
        mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
        mySpaceJson('s2', 'Dom', role: 'member', memberCount: 2),
      ]),
    );
    backend.on('GET /invitations', (_) => Reply([]));
    backend.on(
      'GET /spaces/s2/members',
      (_) => Reply([
        memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
        memberJson('u2', 'bob@example.com'),
      ]),
    );
    await tester.pumpWidget(host(const SpaceDetailScreen(spaceId: 's2')));
    await load(tester);
    await tester.pumpAndSettle();

    expect(find.text('Opuść budżet'), findsOneWidget);
    expect(find.text('Usuń budżet'), findsNothing);
    expect(find.byIcon(Icons.person_add_alt_1_outlined), findsNothing);
    expect(find.byType(PopupMenuButton<Object>), findsNothing);
    // members do not even ask for the invitations of the budget
    expect(backend.sent('GET /spaces/s2/invitations'), isEmpty);
  });

  testWidgets('asks a new user once what they want to use', (tester) async {
    backend.on(
      'GET /spaces',
      (_) => Reply([mySpaceJson('s1', 'Mój budżet', kind: 'personal')]),
    );
    backend.on('GET /invitations', (_) => Reply([]));
    await tester.pumpWidget(
      host(const FirstRunPrompt(child: Scaffold(body: Text('dashboard')))),
    );
    await load(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Czego chcesz używać?'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Tylko mojego budżetu'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Czego chcesz używać?'), findsNothing);

    // and not again
    await tester.pumpWidget(
      host(const FirstRunPrompt(child: Scaffold(body: Text('dashboard')))),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Czego chcesz używać?'), findsNothing);
  });

  testWidgets('does not ask somebody who already has a shared budget', (
    tester,
  ) async {
    backend.on(
      'GET /spaces',
      (_) => Reply([
        mySpaceJson('s1', 'Mój budżet', kind: 'personal'),
        mySpaceJson('s2', 'Dom', role: 'member'),
      ]),
    );
    backend.on('GET /invitations', (_) => Reply([]));
    backend.on('GET /spaces/s2/members', (_) => Reply([]));
    await tester.pumpWidget(
      host(const FirstRunPrompt(child: Scaffold(body: Text('dashboard')))),
    );
    await load(tester);
    await tester.pump();

    expect(find.text('Czego chcesz używać?'), findsNothing);
  });
}
