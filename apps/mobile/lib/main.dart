import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/database_helper.dart';
import 'state/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale data so DateFormat('pl') works for names of months/days.
  await initializeDateFormatting('pl');

  // Open (and create on first run) the local SQLite database up front so the
  // first screen doesn't pay the initialisation cost.
  await DatabaseHelper.instance.database;

  final settings = AppSettings();
  await settings.load();

  runApp(MoneyPlannerApp(settings: settings));
}
