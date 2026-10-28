import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:money_planner/state/planner_state.dart';
import 'package:provider/provider.dart';

import 'support/fake_backend.dart';

Widget app(PlannerState state, FakeBackend backend) => MultiProvider(
  providers: [
    Provider.value(value: backend.repository()),
    // nobody signed in: the header only needs it for the avatar
    ChangeNotifierProvider<AuthState>(
      create: (_) => AuthState(AuthRepository(backend.dio(), SessionStore())),
    ),
    ChangeNotifierProvider<PlannerState>.value(value: state),
  ],
  child: const MaterialApp(
    locale: Locale('pl'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DashboardScreen(),
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('pl'));
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Dashboard shows a loading indicator before state loads', (
    tester,
  ) async {
    final backend = FakeBackend();
    // A fresh PlannerState starts in the loading state (load() not called),
    // so nothing is requested during the test.
    await tester.pumpWidget(
      app(PlannerState(repository: backend.repository()), backend),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('Dashboard offers a retry when the server cannot be reached', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET /envelopes', (_) => const Reply.unreachable())
      ..on('GET /recurring-rules', (_) => const Reply.unreachable())
      ..on('GET /invitations', (_) => const Reply.unreachable())
      ..on('GET /recurring-incomes', (_) => const Reply.unreachable())
      ..on('GET /allocation-rules', (_) => const Reply.unreachable())
      ..on('GET /overview', (_) => const Reply.unreachable());
    final state = PlannerState(repository: backend.repository());

    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();

    expect(find.text('Nie udało się wczytać danych'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);

    // the server comes back: retrying shows the app
    backend
      ..on('GET /envelopes', (_) => const Reply([]))
      ..noRules()
      ..on('GET /overview', (_) => Reply(overviewJson()));
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();

    expect(find.text('Nie udało się wczytać danych'), findsNothing);
    expect(state.loadError, isNull);
  });

  testWidgets('Dashboard of a new user leads into the set-up wizard', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET /envelopes', (_) => const Reply([]))
      ..noRules()
      ..on('GET /overview', (_) => Reply(overviewJson()));
    final state = PlannerState(repository: backend.repository());

    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();

    expect(find.text('Zaczynamy'), findsOneWidget);
  });

  testWidgets('Dashboard shows the month, the pool and the envelopes', (
    tester,
  ) async {
    // tall enough that the list builds every envelope
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend()
      ..on(
        'GET /envelopes',
        (_) => Reply([envelopeJson('e1', 'Food'), envelopeJson('e2', 'Rent')]),
      )
      ..noRules()
      ..on(
        'GET /overview',
        (_) => Reply(
          overviewJson(
            income: 500000,
            allocated: 300000,
            spent: 4599,
            pool: 200000,
            envelopes: [
              figuresJson('e1', allocated: 100000, spent: 4599),
              figuresJson('e2', allocated: 200000),
            ],
          ),
        ),
      );
    final state = PlannerState(
      repository: backend.repository(),
      clock: () => DateTime(2026, 8, 15),
    );

    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();

    expect(find.text('Sierpień 2026'), findsOneWidget);
    expect(find.text('Nierozdzielone na koperty'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Rent'), findsWidgets);
    expect(find.text('+ Wydatek'), findsOneWidget);
  });

  testWidgets(
    'Dashboard offers the recurring rules that are due and applies them',
    (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = FakeBackend()
        ..noRules()
        ..on('GET /envelopes', (_) => Reply([envelopeJson('e1', 'Food')]))
        ..on(
          'GET /overview',
          (_) => Reply(
            overviewJson(envelopes: [figuresJson('e1', allocated: 10000)]),
          ),
        )
        ..on(
          'GET /recurring-rules/pending',
          (_) => const Reply({
            'incomes': 1,
            'allocations': 2,
            'expenses': 0,
            'skipped': 0,
          }),
        )
        ..on(
          'POST /recurring-rules/apply',
          (_) => const Reply({
            'incomes': 1,
            'allocations': 2,
            'expenses': 0,
            'skipped': 0,
          }),
        );
      final state = PlannerState(
        repository: backend.repository(),
        clock: () => DateTime(2026, 8, 15),
      );

      await tester.pumpWidget(app(state, backend));
      await tester.runAsync(state.load);
      await tester.pump();

      expect(
        find.text('Do dodania w tym miesiącu: 1 wpływ, 2 przydziały'),
        findsOneWidget,
      );

      backend.on(
        'GET /recurring-rules/pending',
        (_) => const Reply({
          'incomes': 0,
          'allocations': 0,
          'expenses': 0,
          'skipped': 0,
        }),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Dodaj').first);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(backend.sent('POST /recurring-rules/apply'), hasLength(1));
      expect(find.textContaining('Do dodania w tym miesiącu'), findsNothing);
      expect(find.text('Dodano: 1 wpływ, 2 przydziały.'), findsOneWidget);
    },
  );
}
