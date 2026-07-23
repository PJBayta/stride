import 'package:geolocator/geolocator.dart' hide ActivityType;

import 'activity_type.dart';

/// A completed tracking session's final metrics and recorded route.
///
/// This is the hand-off point between GPS tracking ([TrackingController],
/// which knows nothing about persistence) and the data layer (which knows
/// nothing about GPS streams).
class FinishedSession {
  const FinishedSession({
    required this.activityType,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceMeters,
    required this.avgSpeedMps,
    required this.avgPaceSecondsPerKm,
    required this.calories,
    required this.positions,
  });

  final ActivityType activityType;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceMeters;
  final double avgSpeedMps;
  final double avgPaceSecondsPerKm;
  final int calories;
  final List<Position> positions;
}
