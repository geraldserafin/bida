import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/state/planner_state.dart';
import 'package:provider/provider.dart';

import 'support/fake_backend.dart';

Widget app(PlannerState state, FakeBackend backend) => MultiProvider(
  providers: [
    Provider.value(value: backend.repository()),
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

  testWidgets('Dashboard shows a loading indicator before state loads', (
    tester,
  ) async {
    final backend = FakeBackend();
    // A fresh PlannerState starts in the loading state (load() not called),
    // so nothing is requested during the test.
    await tester.pumpWidget(
      app(PlannerState(repository: backend.repository()), backend),
    );

    expect(find.text('PLNing'), findsOneWidget);
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
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on('GET /invitations', (_) => const Reply([]))
      ..on('GET /overview', (_) => Reply(overviewJson()));
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();

    expect(find.text('Nie udało się wczytać danych'), findsNothing);
    expect(state.loadError, isNull);
  });

  testWidgets('Dashboard of a new user asks for the first income', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET /envelopes', (_) => const Reply([]))
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on('GET /invitations', (_) => const Reply([]))
      ..on('GET /overview', (_) => Reply(overviewJson()));
    final state = PlannerState(repository: backend.repository());

    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();

    expect(find.text('Dodaj wpływ'), findsOneWidget);
    expect(find.text('Dodaj kopertę'), findsOneWidget);
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
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on('GET /invitations', (_) => const Reply([]))
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
    expect(find.text('Nieprzydzielone'), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(find.text('Rent'), findsWidgets);
    expect(find.text('Dodaj wydatek'), findsOneWidget);
  });
}
