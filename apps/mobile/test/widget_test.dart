import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/add_expense/add_expense_screen.dart';
import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/state/app_settings.dart';
import 'package:money_planner/state/auth_state.dart';
import 'package:money_planner/state/budget_state.dart';
import 'package:provider/provider.dart';

import 'support/fake_backend.dart';

Widget app(BudgetState state, FakeBackend backend, {Widget? home}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthState>(
          create: (_) =>
              AuthState(AuthRepository(backend.dio(), SessionStore())),
        ),
        ChangeNotifierProvider<BudgetState>.value(value: state),
      ],
      child: MaterialApp(
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home ?? const DashboardScreen(),
      ),
    );

BudgetState stateFor(FakeBackend backend) =>
    BudgetState(repository: backend.repository(), settings: AppSettings());

void main() {
  setUpAll(() => initializeDateFormatting('pl'));
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('a loading indicator before the state loads', (tester) async {
    final backend = FakeBackend();
    await tester.pumpWidget(app(stateFor(backend), backend));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(backend.requests, isEmpty);
  });

  testWidgets('the app start runs first; a retry when it fails', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('POST /sync', (_) => const Reply.unreachable());
    final state = stateFor(backend);
    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pump();
    expect(find.text('Spróbuj ponownie'), findsOneWidget);

    backend.household(walletMinor: 123456);
    await tester.tap(find.text('Spróbuj ponownie'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(state.loadError, isNull);
    expect(backend.requests.where((r) => r.route == 'POST /sync').length, 2);
    // the wallet as of today
    expect(find.textContaining('234,56'), findsWidgets);
    expect(find.text('Dom'), findsOneWidget);
  });

  testWidgets('no household yet: the wizard', (tester) async {
    final backend = FakeBackend()
      ..household()
      ..on('GET /households', (_) => const Reply([]))
      ..on('GET /overview', (_) => Reply(overviewJson(households: false)));
    final state = stateFor(backend);
    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pumpAndSettle();
    expect(find.text('Zaczynamy'), findsWidgets);
  });

  testWidgets('the to-do list has a button per item', (tester) async {
    final backend = FakeBackend()
      ..household(
        todo: [todoJson('t1', 'expense_not_fit', amountMinor: 120000)],
      );
    final state = stateFor(backend);
    await tester.pumpWidget(app(state, backend));
    await tester.runAsync(state.load);
    await tester.pumpAndSettle();
    expect(find.text('Do załatwienia'), findsOneWidget);
    expect(find.textContaining('Czynsz'), findsOneWidget);
    expect(find.text('Dodaj wydatek'), findsWidgets);
  });

  testWidgets('a too small plan: bring money from the wallet and raise it', (
    tester,
  ) async {
    final backend = FakeBackend()..household(walletMinor: 10000);
    backend.on('POST /households/h1/expenses', (r) {
      final body = r.body! as Map;
      if (body['decision'] == null) {
        return Reply.error(409, 'PlanTooSmall', {
          'envelopeId': 'e1',
          'planShortMinor': 2500,
          'freeMinor': 0,
          'balanceMinor': 0,
          'transferMinor': 2500,
        });
      }
      return Reply(expenseResultJson(2500), status: 201);
    });
    final state = stateFor(backend);
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      app(state, backend, home: const AddExpenseScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.enterText(find.byType(TextField).first, '25');
    await tester.tap(find.text('Jedzenie'));
    await tester.pump();
    await tester.tap(find.text('Zapisz wydatek'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Trzeba podnieść plan'), findsOneWidget);
    await tester.tap(find.textContaining('Dołóż'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final sent = backend
        .sent('POST /households/h1/expenses')
        .map((r) => r.body! as Map);
    expect(sent.length, 2);
    expect(sent.last['decision'], {
      'raisePlan': true,
      'transferMinor': 2500,
      'allowNegativeWallet': false,
    });
  });
}
