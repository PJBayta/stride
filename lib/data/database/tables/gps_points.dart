import 'package:drift/drift.dart';

import 'activities.dart';

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
