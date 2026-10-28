import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/screens/sharing/members_screen.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:money_planner/state/planner_state.dart';
import 'package:provider/provider.dart';

import '../support/fake_backend.dart';

Widget app(
  PlannerState state,
  AuthState auth,
  FakeBackend backend,
  Widget home,
) => MultiProvider(
  providers: [
    Provider.value(value: backend.repository()),
    ChangeNotifierProvider<AuthState>.value(value: auth),
    ChangeNotifierProvider<PlannerState>.value(value: state),
  ],
  child: MaterialApp(
    locale: const Locale('pl'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  late FakeBackend backend;
  late AuthState auth;

  setUpAll(() => initializeDateFormatting('pl'));

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    backend = FakeBackend()
      ..on('GET /auth/me', (_) => Reply(userJson('ann@example.com')))
      ..noRules()
      ..on(
        'GET /envelopes',
        (_) => Reply([envelopeJson('e1', 'Home'), envelopeJson('e2', 'Food')]),
      )
      ..on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            envelopes: [
              figuresJson('e1', allocated: 10000, memberCount: 2),
              figuresJson('e2', allocated: 5000),
            ],
          ),
        ),
      );
    auth = AuthState(AuthRepository(backend.dio(), SessionStore()));
    await auth.restore();
  });

  tearDown(() => auth.dispose());

  PlannerState newState() => PlannerState(
    repository: backend.repository(),
    clock: () => DateTime(2026, 8, 15),
  );

  testWidgets(
    'the dashboard offers the invitations and marks shared envelopes',
    (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      backend
        ..on(
          'GET /invitations',
          (_) => Reply([invitationJson('i1', 'e9', 'ann@example.com')]),
        )
        ..on(
          'POST /invitations/i1/accept',
          (_) => Reply(
            invitationJson('i1', 'e9', 'ann@example.com', status: 'accepted'),
          ),
        );
      final state = newState();

      await tester.pumpWidget(
        app(state, auth, backend, const DashboardScreen()),
      );
      await tester.runAsync(state.load);
      await tester.pump();

      expect(
        find.text('ann@example.com zaprasza Cię do koperty „Home”'),
        findsOneWidget,
      );
      expect(find.text('Home · 2 osoby'), findsOneWidget);

      backend.on('GET /invitations', (_) => const Reply([]));
      await tester.runAsync(() async {
        await tester.tap(find.text('Przyjmij'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();

      expect(backend.sent('POST /invitations/i1/accept'), hasLength(1));
      expect(find.text('Przyjmij'), findsNothing);
    },
  );

  testWidgets('an owner sees the members, the invitations and the ways to act', (
    tester,
  ) async {
    backend
      ..on('GET /invitations', (_) => const Reply([]))
      ..on(
        'GET /envelopes/e1/members',
        (_) => Reply([
          memberJson('u1', 'ann@example.com', name: 'Ann', role: 'owner'),
          memberJson('u2', 'bob@example.com'),
        ]),
      )
      ..on(
        'GET /envelopes/e1/invitations',
        (_) => Reply([
          invitationJson('i1', 'e1', 'cid@example.com', status: 'accepted'),
        ]),
      );
    final state = newState();
    await tester.runAsync(state.load);

    // the screen asks the server when it is built, which has to happen in real time
    await tester.runAsync(() async {
      await tester.pumpWidget(
        app(state, auth, backend, const MembersScreen(envelopeId: 'e1')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Ann (Ty)'), findsOneWidget);
    expect(find.text('bob@example.com'), findsOneWidget);
    expect(find.text('Właściciel'), findsOneWidget);
    expect(find.text('Członek'), findsOneWidget);
    expect(find.text('cid@example.com'), findsOneWidget);
    expect(find.text('Przyjęte, czeka na zatwierdzenie'), findsOneWidget);
    expect(find.byTooltip('Zatwierdź'), findsOneWidget);
    expect(find.text('Zaproś'), findsOneWidget);
    expect(find.text('Opuść kopertę'), findsOneWidget);
  });

  testWidgets('a member cannot invite or manage anybody', (tester) async {
    backend
      ..on('GET /invitations', (_) => const Reply([]))
      ..on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            envelopes: [
              figuresJson(
                'e1',
                allocated: 10000,
                role: 'member',
                memberCount: 2,
              ),
            ],
          ),
        ),
      )
      ..on(
        'GET /envelopes/e1/members',
        (_) => Reply([
          memberJson('u1', 'bob@example.com', role: 'owner'),
          memberJson('u2', 'ann@example.com'),
        ]),
      );
    final state = newState();
    await tester.runAsync(state.load);

    // the screen asks the server when it is built, which has to happen in real time
    await tester.runAsync(() async {
      await tester.pumpWidget(
        app(state, auth, backend, const MembersScreen(envelopeId: 'e1')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Zaproś'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.text('Opuść kopertę'), findsOneWidget);
    expect(backend.sent('GET /envelopes/e1/invitations'), isEmpty);
  });
}
