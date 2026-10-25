import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

    expect(find.text('PLNing'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('Dashboard offers a retry when the server cannot be reached', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('GET /categories', (_) => const Reply.unreachable())
      ..on('GET /recurring-rules', (_) => const Reply.unreachable())
      ..on('GET /periods', (_) => const Reply.unreachable());
    final state = PlannerState(repository: backend.repository());

    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();

    expect(find.text('Nie udało się wczytać danych'), findsOneWidget);
    expect(find.text('Spróbuj ponownie'), findsOneWidget);

    // the server comes back: retrying shows the app
    backend
      ..on('GET /categories', (_) => const Reply([]))
      ..on('GET /recurring-rules', (_) => const Reply([]))
      ..on('GET /periods', (_) => const Reply([]));
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.pumpAndSettle();

    expect(find.text('Nie udało się wczytać danych'), findsNothing);
    expect(state.loadError, isNull);
  });
}
