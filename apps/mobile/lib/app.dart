import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/planner_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/lock/lock_gate.dart';
import 'state/app_settings.dart';
import 'state/planner_state.dart';
import 'theme/app_theme.dart';

/// Root widget: provides app-wide state and wires up theming, localization
/// (Polish by default) and the home screen.
class MoneyPlannerApp extends StatefulWidget {
  const MoneyPlannerApp({
    super.key,
    required this.settings,
    required this.repository,
    this.beforeLoad,
  });

  final AppSettings settings;
  final PlannerRepository repository;

  /// Runs before the first load, e.g. to move data from an older version.
  final Future<void> Function()? beforeLoad;

  @override
  State<MoneyPlannerApp> createState() => _MoneyPlannerAppState();
}

class _MoneyPlannerAppState extends State<MoneyPlannerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  // Desktop mice send back/forward as extra pointer buttons; Flutter doesn't
  // pop on them by default, so wire the back button to Navigator.maybePop.
  // On phones the OS back button/gesture already works.
  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == kBackMouseButton) {
      _navigatorKey.currentState?.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.repository),
        ChangeNotifierProvider(
          create: (_) => PlannerState(
            repository: widget.repository,
            beforeLoad: widget.beforeLoad,
          )..load(),
        ),
        ChangeNotifierProvider.value(value: widget.settings),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) => Listener(
          onPointerDown: _onPointerDown,
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            locale: const Locale('pl'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LockGate(child: DashboardScreen()),
          ),
        ),
      ),
    );
  }
}
