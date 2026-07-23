import 'package:drift/drift.dart';

import '../../models/finished_session.dart';
import '../database/app_database.dart';

/// Persists a [FinishedSession] as an [Activity] row plus its recorded
/// [GpsPoint] rows, as a single unit.
///
/// This is the only place that knows how to turn a finished tracking session
/// into database rows — [ActivitiesDao] and [GpsPointsDao] stay generic.
class ActivityRepository {
  ActivityRepository(this._database);

  final AppDatabase _database;

  /// Saves [session] and returns the persisted [Activity] row.
  Future<Activity> saveSession(FinishedSession session) {
    return _database.transaction(() async {
      final activityId = await _database.activitiesDao.insertActivity(
        ActivitiesCompanion.insert(
          activityType: session.activityType.dbValue,
          startTime: session.startTime,
          endTime: session.endTime,
          durationSeconds: session.duration.inSeconds,
          distanceMeters: session.distanceMeters,
          avgSpeed: session.avgSpeedMps,
          avgPace: session.avgPaceSecondsPerKm,
          calories: session.calories,
        ),
      );

      if (session.positions.isNotEmpty) {
        await _database.gpsPointsDao.insertPoints([
          for (final position in session.positions)
            GpsPointsCompanion.insert(
              activityId: activityId,
              latitude: position.latitude,
              longitude: position.longitude,
              altitude: Value(position.altitude),
              timestamp: position.timestamp,
            ),
        ]);
      }

      final saved = await _database.activitiesDao.getActivityById(activityId);
      return saved!;
    });
  }
}
