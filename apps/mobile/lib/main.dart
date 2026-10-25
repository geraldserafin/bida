import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/api_client.dart';
import 'data/active_space.dart';
import 'data/auth_repository.dart';
import 'data/google_sign_in.dart';
import 'data/legacy_migration.dart';
import 'data/planner_repository.dart';
import 'data/session_store.dart';
import 'data/sharing_repository.dart';
import 'state/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale data so DateFormat('pl') works for names of months/days.
  await initializeDateFormatting('pl');

  final settings = AppSettings();
  await settings.load();

  await initGoogleSignIn();

  final session = SessionStore();
  final activeSpace = ActiveSpace();
  final dio = createDio(session: session, space: activeSpace);
  final repository = PlannerRepository(dio);

  runApp(
    MoneyPlannerApp(
      settings: settings,
      repository: repository,
      auth: AuthRepository(dio, session),
      sharing: SharingRepository(dio),
      activeSpace: activeSpace,
      // Data kept on the device by the offline version moves to the server.
      beforeLoad: legacyMigration(repository),
      // The browser app opened from the link in the sign-in e-mail.
      linkToken: Uri.base.queryParameters['login_token'],
    ),
  );
}
