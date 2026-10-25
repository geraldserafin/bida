import 'legacy_migrator.dart';
import 'planner_repository.dart';

/// Moves data kept by the offline version on this device to the server before
/// the first load.
Future<void> Function()? legacyMigration(PlannerRepository repository) {
  final migrator = LegacyMigrator(repository);
  return () async {
    await migrator.migrateIfNeeded();
  };
}
