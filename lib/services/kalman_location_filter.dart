import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// A 2D Kalman Filter designed for smoothing noisy mobile GPS coordinates.
///
/// Filters out high-variance GPS fixes, prevents stationary distance drift,
/// eliminates erratic speed spikes, and produces a clean trajectory.
class KalmanLocationFilter {
  KalmanLocationFilter({
    this.processNoiseQ = 3.0,
    this.maxAcceptableAccuracyMeters = 50.0,
    this.maxAcceptableSpeedMps = 50.0,
  });

  /// Process noise factor (acceleration/movement uncertainty scale).
  final double processNoiseQ;

  /// Max acceptable raw GPS accuracy in meters. Worse fixes are rejected as noise.
  final double maxAcceptableAccuracyMeters;

  /// Max reasonable speed for human activities in m/s (~180 km/h). Fast jumps are rejected.
  final double maxAcceptableSpeedMps;

  double? _lat;
  double? _lng;
  double _varianceLat = -1.0;
  double _varianceLng = -1.0;
  DateTime? _lastTimestamp;

  /// Clears filter state for a new tracking session.
  void reset() {
    _lat = null;
    _lng = null;
    _varianceLat = -1.0;
    _varianceLng = -1.0;
    _lastTimestamp = null;
  }

  /// Processes a [rawPosition] through the Kalman filter.
  ///
  /// Returns a smoothed [Position] or `null` if [rawPosition] is rejected
  /// as an extreme GPS noise outlier.
  Position? process(Position rawPosition) {
    // 1. Reject invalid or extreme accuracy readings
    if (rawPosition.accuracy <= 0 ||
        rawPosition.accuracy > maxAcceptableAccuracyMeters) {
      return null;
    }

    final now = rawPosition.timestamp;

    // 2. Initialization on first GPS fix
    if (_lat == null || _lng == null || _lastTimestamp == null) {
      _lat = rawPosition.latitude;
      _lng = rawPosition.longitude;
      _varianceLat = rawPosition.accuracy * rawPosition.accuracy;
      _varianceLng = rawPosition.accuracy * rawPosition.accuracy;
      _lastTimestamp = now;
      return rawPosition;
    }

    final deltaSeconds =
        now.difference(_lastTimestamp!).inMilliseconds / 1000.0;
    if (deltaSeconds <= 0) {
      // Duplicate or out-of-order timestamp, keep previous state
      return _buildPosition(rawPosition, _lat!, _lng!, rawPosition.speed);
    }

    // 3. Speed sanity check to discard teleportation/GPS jump outliers
    final rawDisplacement = Geolocator.distanceBetween(
      _lat!,
      _lng!,
      rawPosition.latitude,
      rawPosition.longitude,
    );
    final rawSpeed = rawDisplacement / deltaSeconds;
    if (rawSpeed > maxAcceptableSpeedMps) {
      // Discard extreme outlier
      return null;
    }

    // 4. Kalman Filter algorithm
    // R is measurement noise variance derived from sensor accuracy
    final r = math.max(rawPosition.accuracy * rawPosition.accuracy, 1.0);

    // Predict step: increase error covariance with time delta
    _varianceLat += deltaSeconds * processNoiseQ;
    _varianceLng += deltaSeconds * processNoiseQ;

    // Update step: calculate Kalman gain K for lat and lng
    final kLat = _varianceLat / (_varianceLat + r);
    final kLng = _varianceLng / (_varianceLng + r);

    // Estimate new state
    final newLat = _lat! + kLat * (rawPosition.latitude - _lat!);
    final newLng = _lng! + kLng * (rawPosition.longitude - _lng!);

    // Update error covariance
    _varianceLat = (1.0 - kLat) * _varianceLat;
    _varianceLng = (1.0 - kLng) * _varianceLng;

    // Calculate filtered displacement & speed
    final filteredDisplacement = Geolocator.distanceBetween(
      _lat!,
      _lng!,
      newLat,
      newLng,
    );

    // Filter stationary noise drift (displacement < 0.3 meters)
    final double filteredSpeed;
    if (filteredDisplacement < 0.3) {
      filteredSpeed = 0.0;
    } else {
      filteredSpeed = filteredDisplacement / deltaSeconds;
      _lat = newLat;
      _lng = newLng;
    }

    _lastTimestamp = now;

    return _buildPosition(
      rawPosition,
      _lat!,
      _lng!,
      rawPosition.speed > 0 ? math.min(rawPosition.speed, filteredSpeed) : filteredSpeed,
    );
  }

  Position _buildPosition(
    Position raw,
    double lat,
    double lng,
    double speed,
  ) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: raw.timestamp,
      accuracy: math.sqrt(math.max(_varianceLat, 1.0)),
      altitude: raw.altitude,
      altitudeAccuracy: raw.altitudeAccuracy,
      heading: raw.heading,
      headingAccuracy: raw.headingAccuracy,
      speed: math.max(0.0, speed),
      speedAccuracy: raw.speedAccuracy,
      isMocked: raw.isMocked,
    );
  }
}
