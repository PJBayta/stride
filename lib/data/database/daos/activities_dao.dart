import 'package:drift/drift.dart';

import '../../../models/activity_stats.dart';
import '../app_database.dart';
import '../tables/activities.dart';

part 'activities_dao.g.dart';

@DriftAccessor(tables: [Activities])
class ActivitiesDao extends DatabaseAccessor<AppDatabase>
    with _$ActivitiesDaoMixin {
  ActivitiesDao(super.db);

  /// Aggregate stats across all recorded activities, recomputed from the
  /// table on every change rather than stored. Pass [since] to scope the
  /// aggregate to activities starting on or after that time (e.g. "this
  /// month").
  Stream<ActivityStats> watchStats({DateTime? since}) {
    final totalCount = countAll();
    final totalDistance = activities.distanceMeters.sum();
    final totalDuration = activities.durationSeconds.sum();
    final totalCalories = activities.calories.sum();

    final query = selectOnly(activities)
      ..addColumns([totalCount, totalDistance, totalDuration, totalCalories]);
    if (since != null) {
      query.where(activities.startTime.isBiggerOrEqualValue(since));
    }

    return query.watchSingle().map(
      (row) => ActivityStats(
        totalActivities: row.read(totalCount) ?? 0,
        totalDistanceMeters: row.read(totalDistance) ?? 0,
        totalDurationSeconds: row.read(totalDuration) ?? 0,
        totalCalories: row.read(totalCalories) ?? 0,
      ),
    );
  }

  Future<int> insertActivity(ActivitiesCompanion entry) =>
      into(activities).insert(entry);

  Future<List<Activity>> getAllActivities() => (select(
    activities,
  )..orderBy([(t) => OrderingTerm.desc(t.startTime)])).get();

  Stream<List<Activity>> watchAllActivities() => (select(
    activities,
  )..orderBy([(t) => OrderingTerm.desc(t.startTime)])).watch();

  Future<Activity?> getActivityById(int id) =>
      (select(activities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteActivity(int id) =>
      (delete(activities)..where((t) => t.id.equals(id))).go();
}
