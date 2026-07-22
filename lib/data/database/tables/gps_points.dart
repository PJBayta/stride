import 'package:drift/drift.dart';

import 'activities.dart';

/// A single GPS sample belonging to an [Activities] row.
///
/// Mirrors the `GPSPoints` entity in `docs/database.md`. Many points belong
/// to one activity; deleting the activity cascades to its points.
class GpsPoints extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get activityId =>
      integer().references(Activities, #id, onDelete: KeyAction.cascade)();

  RealColumn get latitude => real()();

  RealColumn get longitude => real()();

  /// Altitude in meters. Not all GPS providers report this.
  RealColumn get altitude => real().nullable()();

  DateTimeColumn get timestamp => dateTime()();
}
