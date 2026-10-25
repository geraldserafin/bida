import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/api_client.dart';
import 'data/legacy_migrator.dart';
import 'data/planner_repository.dart';
import 'state/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale data so DateFormat('pl') works for names of months/days.
  await initializeDateFormatting('pl');

  final settings = AppSettings();
  await settings.load();

  final repository = PlannerRepository(createDio());

  runApp(
    MoneyPlannerApp(
      settings: settings,
      repository: repository,
      // Data kept on the device by the offline version moves to the server.
      migrator: LegacyMigrator(repository),
    ),
  );
}
