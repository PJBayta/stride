import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/gps_points.dart';

part 'gps_points_dao.g.dart';

@DriftAccessor(tables: [GpsPoints])
class GpsPointsDao extends DatabaseAccessor<AppDatabase>
    with _$GpsPointsDaoMixin {
  GpsPointsDao(super.db);

  Future<int> insertPoint(GpsPointsCompanion entry) =>
      into(gpsPoints).insert(entry);

  Future<void> insertPoints(List<GpsPointsCompanion> entries) =>
      batch((b) => b.insertAll(gpsPoints, entries));

  Future<List<GpsPoint>> getPointsForActivity(int activityId) =>
      (select(gpsPoints)
            ..where((t) => t.activityId.equals(activityId))
            ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
          .get();

  Future<int> deletePointsForActivity(int activityId) =>
      (delete(gpsPoints)..where((t) => t.activityId.equals(activityId))).go();
}
