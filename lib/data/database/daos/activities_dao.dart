import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/activities.dart';

part 'activities_dao.g.dart';

@DriftAccessor(tables: [Activities])
class ActivitiesDao extends DatabaseAccessor<AppDatabase>
    with _$ActivitiesDaoMixin {
  ActivitiesDao(super.db);

  Future<int> insertActivity(ActivitiesCompanion entry) =>
      into(activities).insert(entry);

  Future<List<Activity>> getAllActivities() =>
      (select(activities)..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .get();

  Stream<List<Activity>> watchAllActivities() =>
      (select(activities)..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
          .watch();

  Future<Activity?> getActivityById(int id) =>
      (select(activities)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteActivity(int id) =>
      (delete(activities)..where((t) => t.id.equals(id))).go();
}
