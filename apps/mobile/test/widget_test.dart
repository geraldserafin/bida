import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_planner/data/auth_repository.dart';
import 'package:money_planner/data/session_store.dart';
import 'package:money_planner/l10n/app_localizations.dart';
import 'package:money_planner/screens/add_expense/add_expense_screen.dart';
import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/screens/household/household_screen.dart';
import 'package:money_planner/screens/household/plan_editor_screen.dart';
import 'package:money_planner/screens/login/login_screen.dart';
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

  testWidgets('the next period opens only after asking', (tester) async {
    final backend = FakeBackend()..household();
    backend
      ..on(
        'POST /households/h1/periods/next',
        (_) => Reply(
          periodJson(
            id: 'p2',
            status: 'next',
            startsOn: '2026-08-01',
            endsOn: '2026-08-31',
          ),
          status: 201,
        ),
      )
      ..on('GET /periods/p2', (_) => Reply(summaryJson()));
    final state = stateFor(backend);
    await tester.runAsync(state.load);
    await tester.pumpWidget(app(state, backend, home: const HouseholdScreen()));
    await tester.pumpAndSettle();

    // ( < ) ( 1.07 – 31.07 ) ( + ): no period before, the next one not open
    expect(find.text('1.07 – 31.07'), findsOneWidget);
    await tester.tap(find.byTooltip('Otwórz następny okres'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1.08.2026'), findsOneWidget);
    expect(backend.sent('POST /households/h1/periods/next'), isEmpty);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Otwórz następny okres'),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(backend.sent('POST /households/h1/periods/next').length, 1);
  });

  testWidgets('tapping an envelope adds an expense to it', (tester) async {
    final backend = FakeBackend()..household();
    final state = stateFor(backend);
    await tester.runAsync(state.load);
    await tester.pumpWidget(app(state, backend, home: const HouseholdScreen()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-card')), findsOneWidget);
    await tester.ensureVisible(find.text('Jedzenie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jedzenie'));
    await tester.pumpAndSettle();
    final screen = tester.widget<AddExpenseScreen>(
      find.byType(AddExpenseScreen),
    );
    expect(screen.initialEnvelopeId, 'e1');
  });

  testWidgets('the plan editor starts empty and counts the free money', (
    tester,
  ) async {
    final backend = FakeBackend()..household();
    backend
      ..on('GET /periods/p1', (_) => Reply(summaryJson(balanceMinor: 50000)))
      ..on(
        'PUT /periods/p1/plans/e1',
        (_) => Reply(summaryJson(balanceMinor: 50000)),
      );
    final state = stateFor(backend);
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      app(state, backend, home: PlanEditorScreen(summary: state.summary!)),
    );
    await tester.pump();

    final field = find.byKey(PlanEditorScreen.fieldKey('e1'));
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.textContaining('500,00'), findsWidgets);
    await tester.enterText(field, '300');
    await tester.pump();
    expect(find.textContaining('200,00'), findsOneWidget);

    await tester.tap(find.text('Zapisz plan'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    final sent = backend.sent('PUT /periods/p1/plans/e1').toList();
    expect(sent.length, 1);
    expect((sent.single.body! as Map)['amountMinor'], 30000);
  });

  testWidgets('the address can be changed after the code was sent', (
    tester,
  ) async {
    final backend = FakeBackend()
      ..on('POST /auth/magic-link', (_) => const Reply(null, status: 204));
    final state = stateFor(backend);
    await tester.pumpWidget(app(state, backend, home: const LoginScreen()));
    await tester.enterText(
      find.byKey(LoginScreen.emailFieldKey),
      'ann@example.com',
    );
    await tester.tap(find.byKey(LoginScreen.consentKey));
    await tester.tap(find.text('Wyślij kod'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LoginScreen.codeFieldKey), findsOneWidget);

    await tester.enterText(
      find.byKey(LoginScreen.emailFieldKey),
      'anna@example.com',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(LoginScreen.codeFieldKey), findsNothing);
    expect(find.text('Wyślij kod'), findsOneWidget);
  });
}
