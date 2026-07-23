import 'package:flutter/material.dart';

/// The kinds of activity Stride can track.
///
/// [dbValue] is the canonical string stored in the `activities.activity_type`
/// column; it must stay stable even if [label] wording changes later.
enum ActivityType {
  run('Run', Icons.directions_run, Icons.terrain_outlined, met: 9.8),
  walk('Walk', Icons.directions_walk, Icons.park_outlined, met: 3.8),
  bike('Bike', Icons.directions_bike, Icons.route_outlined, met: 7.5);

  const ActivityType(
    this.label,
    this.icon,
    this.placeholderIcon, {
    required this.met,
  });

  final String label;
  final IconData icon;

  /// Shown in place of a real route thumbnail, since route rendering isn't
  /// implemented yet.
  final IconData placeholderIcon;

  /// Metabolic equivalent for this activity, used for a rough calorie
  /// estimate. Not a substitute for a real per-user calorie model (which
  /// would need body weight from a future Settings/Profile feature).
  final double met;

  String get dbValue => name;

  static ActivityType fromDbValue(String value) => ActivityType.values.firstWhere(
        (type) => type.dbValue == value,
        orElse: () => ActivityType.run,
      );
}
