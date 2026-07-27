import 'package:flutter/material.dart';

/// The kinds of activity Stride can track.
///
/// [dbValue] is the canonical string stored in the `activities.activity_type`
/// column; it must stay stable even if [label] wording changes later.
enum ActivityType {
  run('Run', Icons.directions_run, Icons.terrain_outlined),
  walk('Walk', Icons.directions_walk, Icons.park_outlined),
  bike('Bike', Icons.directions_bike, Icons.route_outlined);

  const ActivityType(
    this.label,
    this.icon,
    this.placeholderIcon
    );

  final String label;
  final IconData icon;
  final IconData placeholderIcon;

  String get dbValue => name;

  static ActivityType fromDbValue(String value) => ActivityType.values.firstWhere(
        (type) => type.dbValue == value,
        orElse: () => ActivityType.run,
      );
}
