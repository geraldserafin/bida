import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/active_space.dart';
import 'data/auth_repository.dart';
import 'data/planner_repository.dart';
import 'data/sharing_repository.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/lock/lock_gate.dart';
import 'screens/login/auth_gate.dart';
import 'state/app_settings.dart';
import 'state/auth_state.dart';
import 'state/planner_state.dart';
import 'state/spaces_state.dart';
import 'theme/app_theme.dart';
import 'widgets/phone_frame.dart';

/// Root widget: provides app-wide state and wires up theming, localization
/// (Polish by default) and the home screen.
class MoneyPlannerApp extends StatefulWidget {
  const MoneyPlannerApp({
    super.key,
    required this.settings,
    required this.repository,
    required this.auth,
    required this.sharing,
    required this.activeSpace,
    this.beforeLoad,
    this.linkToken,
  });

  final AppSettings settings;
  final PlannerRepository repository;
  final AuthRepository auth;
  final SharingRepository sharing;
  final ActiveSpace activeSpace;

  /// Runs before the first load, e.g. to move data from an older version.
  final Future<void> Function()? beforeLoad;

  /// The token of the sign-in link the browser app was opened from, if any.
  final String? linkToken;

  @override
  State<MoneyPlannerApp> createState() => _MoneyPlannerAppState();
}

class _MoneyPlannerAppState extends State<MoneyPlannerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthState _auth = AuthState(widget.auth);

  @override
  void initState() {
    super.initState();
    _auth.addListener(_closeScreensWhenSignedOut);
    _auth.restore(linkToken: widget.linkToken);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  /// Screens opened on top of the home screen would hide the sign-in screen.
  void _closeScreensWhenSignedOut() {
    if (_auth.status == AuthStatus.signedOut) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

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
        ChangeNotifierProvider.value(value: _auth),
        Provider.value(value: widget.sharing),
        // the user's budgets, once somebody is signed in
        ChangeNotifierProxyProvider<AuthState, SpacesState>(
          create: (_) => SpacesState(widget.sharing, widget.activeSpace),
          update: (_, auth, spaces) => spaces!..bind(signedIn: auth.isSignedIn),
        ),
        // the data of the budget in use; forgotten when it changes
        ChangeNotifierProxyProvider<SpacesState, PlannerState>(
          create: (_) => PlannerState(
            repository: widget.repository,
            beforeLoad: widget.beforeLoad,
          ),
          update: (_, spaces, planner) =>
              planner!..useSpace(spaces.current?.id),
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
            builder: kIsWeb
                ? (context, child) => PhoneFrame(child: child!)
                : null,
            locale: const Locale('pl'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LockGate(child: AuthGate(child: DashboardScreen())),
          ),
        ),
      ),
    );
  }
}
