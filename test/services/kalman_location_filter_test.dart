import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stride/services/kalman_location_filter.dart';

void main() {
  group('KalmanLocationFilter Tests', () {
    late KalmanLocationFilter filter;

    setUp(() {
      filter = KalmanLocationFilter();
    });

    test('initial position is accepted as baseline', () {
      final now = DateTime.now();
      final pos = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 2.0,
        speedAccuracy: 1.0,
        isMocked: false,
      );

      final result = filter.process(pos);
      expect(result, isNotNull);
      expect(result!.latitude, equals(37.7749));
      expect(result.longitude, equals(-122.4194));
    });

    test('outliers with extreme accuracy error are rejected', () {
      final now = DateTime.now();
      final badPos = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
        accuracy: 150.0, // Exceeds maxAcceptableAccuracyMeters threshold (50.0m)
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 2.0,
        speedAccuracy: 1.0,
        isMocked: false,
      );

      final result = filter.process(badPos);
      expect(result, isNull);
    });

    test('outliers with impossible speed jumps are rejected', () {
      final now = DateTime.now();
      final baseline = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: now,
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 2.0,
        speedAccuracy: 1.0,
        isMocked: false,
      );

      filter.process(baseline);

      // Jump ~100 km in 1 second
      final teleporterPos = Position(
        latitude: 38.7749,
        longitude: -122.4194,
        timestamp: now.add(const Duration(seconds: 1)),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 200.0,
        speedAccuracy: 1.0,
        isMocked: false,
      );

      final result = filter.process(teleporterPos);
      expect(result, isNull);
    });

    test('stationary micro-movements are filtered to prevent drift', () {
      final now = DateTime.now();
      final pos1 = Position(
        latitude: 37.774900,
        longitude: -122.419400,
        timestamp: now,
        accuracy: 3.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      filter.process(pos1);

      // Micro movement (less than 30 cm displacement)
      final pos2 = Position(
        latitude: 37.774901,
        longitude: -122.419401,
        timestamp: now.add(const Duration(seconds: 1)),
        accuracy: 3.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.1,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      final result = filter.process(pos2);
      expect(result, isNotNull);
      expect(result!.speed, equals(0.0));
    });
  });
}
