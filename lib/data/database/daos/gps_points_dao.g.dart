// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_points_dao.dart';

// ignore_for_file: type=lint
mixin _$GpsPointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ActivitiesTable get activities => attachedDatabase.activities;
  $GpsPointsTable get gpsPoints => attachedDatabase.gpsPoints;
  GpsPointsDaoManager get managers => GpsPointsDaoManager(this);
}

class GpsPointsDaoManager {
  final _$GpsPointsDaoMixin _db;
  GpsPointsDaoManager(this._db);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db.attachedDatabase, _db.activities);
  $$GpsPointsTableTableManager get gpsPoints =>
      $$GpsPointsTableTableManager(_db.attachedDatabase, _db.gpsPoints);
}
