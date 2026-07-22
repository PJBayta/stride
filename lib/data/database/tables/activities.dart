import 'package:drift/drift.dart';

/// A single recorded activity (run, walk, ride, ...).
///
/// Mirrors the `Activities` entity described in `docs/database.md`. GPS points
/// and settings live in their own tables and are added in later phases.
class Activities extends Table {
  /// Primary key. Maps to `ActivityID`.
  IntColumn get id => integer().autoIncrement()();

  /// The kind of activity, e.g. `run`, `walk`, `ride`.
  TextColumn get activityType => text().withLength(min: 1, max: 50)();

  /// When the activity started.
  DateTimeColumn get startTime => dateTime()();

  /// When the activity finished.
  DateTimeColumn get endTime => dateTime()();

  /// Total elapsed time in seconds.
  IntColumn get durationSeconds => integer()();

  /// Total distance covered, in meters.
  RealColumn get distanceMeters => real()();

  /// Average speed, in meters per second.
  RealColumn get avgSpeed => real()();

  /// Average pace, in seconds per kilometer.
  RealColumn get avgPace => real()();

  /// Estimated energy burned, in kilocalories.
  IntColumn get calories => integer()();

  /// Row creation timestamp. Defaults to insertion time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
