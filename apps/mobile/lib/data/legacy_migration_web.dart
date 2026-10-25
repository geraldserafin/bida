import 'planner_repository.dart';

/// A browser has no database from the offline version, so there is nothing to
/// move to the server.
Future<void> Function()? legacyMigration(PlannerRepository repository) => null;
