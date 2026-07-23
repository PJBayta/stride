import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/activities_dao.dart';
import 'daos/gps_points_dao.dart';
import 'daos/settings_dao.dart';
import 'tables/activities.dart';
import 'tables/gps_points.dart';
import 'tables/settings.dart';

part 'app_database.g.dart';

/// The application's local Drift (SQLite) database.
///
/// Opened lazily via [driftDatabase], which stores the database file in the
/// platform's application-documents directory and bundles the native SQLite
/// libraries through `sqlite3_flutter_libs`.
@DriftDatabase(
  tables: [Activities, GpsPoints, Settings],
  daos: [ActivitiesDao, GpsPointsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test/advanced constructor allowing a custom executor (e.g. in-memory).
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // SQLite doesn't enforce foreign keys per-connection unless asked;
          // without this, GpsPoints' onDelete: KeyAction.cascade is a no-op.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'stride');
}

AppDatabase? _appDatabaseInstance;

/// The single [AppDatabase] instance used by the app. Drift doesn't support
/// multiple instances safely writing to the same underlying SQLite file, so
/// callers should always go through this rather than calling `AppDatabase()`
/// directly.
AppDatabase get appDatabase => _appDatabaseInstance ??= AppDatabase();
