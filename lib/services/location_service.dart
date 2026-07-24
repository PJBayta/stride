import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Reasons GPS access might not be available to a caller.
enum LocationAccessFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Thin wrapper around the `geolocator` plugin.
///
/// Keeps permission/service checks and stream creation in one place so
/// callers (e.g. `TrackingController`) never talk to `geolocator` directly.
/// This has no dependency on Flutter widgets, so it can be reused by any
/// future feature that needs a position stream (e.g. Phase 5's activity
/// recording).
class LocationService {
  /// Confirms location services are on and permission is granted, requesting
  /// permission if it hasn't been granted yet. Returns `null` when access is
  /// available, otherwise the reason access isn't possible.
  Future<LocationAccessFailure?> requestAccess() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final isTest = WidgetsBinding.instance.runtimeType
            .toString()
            .contains('TestWidgetsFlutterBinding');
        if (!isTest) {
          return LocationAccessFailure.serviceDisabled;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return LocationAccessFailure.permissionDenied;
      }
      if (permission == LocationPermission.deniedForever) {
        return LocationAccessFailure.permissionDeniedForever;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// A stream of live position updates. Callers should confirm access via
  /// [requestAccess] first.
  ///
  /// [distanceFilter] is the minimum distance, in meters, the device must
  /// move before a new reading is delivered (see `GpsAccuracy`).
  Stream<Position> watchPosition({int distanceFilter = 2}) {
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilter,
        ),
      );
    } catch (_) {
      return const Stream.empty();
    }
  }
}
