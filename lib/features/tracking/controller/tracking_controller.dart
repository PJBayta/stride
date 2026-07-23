import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import '../../../models/activity_type.dart';
import '../../../models/finished_session.dart';
import '../../../services/location_service.dart';

enum TrackingStatus { idle, tracking, error }

/// Assumed body weight used for a rough calorie estimate, in kilograms.
/// Replace with a real per-user value once Settings/Profile exposes one.
const _assumedWeightKg = 70.0;

/// Owns GPS tracking state for a single live session: permission/service
/// checks, the position stream, an elapsed-time stopwatch, and the in-memory
/// route recorded so far.
///
/// Deliberately holds no reference to Flutter widgets, BuildContext, or the
/// database — it produces a plain [FinishedSession] on [finish], leaving
/// persistence to the data layer (see `ActivityRepository`).
class TrackingController extends ChangeNotifier {
  TrackingController({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStart;
  DateTime? _sessionStartedAt;
  ActivityType? _activityType;
  int _distanceFilter = 2;

  final List<Position> _recordedPositions = [];
  double _totalDistanceMeters = 0;

  TrackingStatus status = TrackingStatus.idle;
  Position? currentPosition;
  bool isPaused = false;
  String? errorMessage;

  bool get isTracking => status == TrackingStatus.tracking;

  /// Total distance covered so far, in meters.
  double get distanceMeters => _totalDistanceMeters;

  /// Total time spent tracking, excluding any paused duration.
  Duration get elapsed => _segmentStart == null
      ? _accumulated
      : _accumulated + DateTime.now().difference(_segmentStart!);

  /// Requests location access and, if granted, starts listening to the GPS
  /// stream and the elapsed timer. On failure, sets [status] to
  /// [TrackingStatus.error] and [errorMessage] with a user-facing reason.
  ///
  /// [distanceFilter] comes from the user's GPS accuracy setting; see
  /// `GpsAccuracy`.
  Future<void> start({
    required ActivityType activityType,
    int distanceFilter = 2,
  }) async {
    if (status == TrackingStatus.tracking) return;

    final failure = await _locationService.requestAccess();
    if (failure != null) {
      status = TrackingStatus.error;
      errorMessage = switch (failure) {
        LocationAccessFailure.serviceDisabled =>
          'Location services are turned off.',
        LocationAccessFailure.permissionDenied =>
          'Location permission was denied.',
        LocationAccessFailure.permissionDeniedForever =>
          'Location permission is permanently denied. Enable it in system settings.',
      };
      notifyListeners();
      return;
    }

    _activityType = activityType;
    _distanceFilter = distanceFilter;
    _sessionStartedAt = DateTime.now();
    _accumulated = Duration.zero;
    _segmentStart = _sessionStartedAt;
    _recordedPositions.clear();
    _totalDistanceMeters = 0;
    isPaused = false;
    errorMessage = null;
    status = TrackingStatus.tracking;
    _startListening();
    notifyListeners();
  }

  /// Pauses the GPS stream and timer without losing elapsed time or the
  /// route recorded so far.
  void pause() {
    if (status != TrackingStatus.tracking || isPaused) return;
    _accumulated += DateTime.now().difference(_segmentStart!);
    _segmentStart = null;
    isPaused = true;
    _stopListening();
    notifyListeners();
  }

  /// Resumes the GPS stream and timer after [pause].
  void resume() {
    if (status != TrackingStatus.tracking || !isPaused) return;
    _segmentStart = DateTime.now();
    isPaused = false;
    _startListening();
    notifyListeners();
  }

  /// Stops listening to the GPS stream and timer, keeping recorded data for
  /// [finish] to read.
  void stop() {
    if (!isPaused && _segmentStart != null) {
      _accumulated += DateTime.now().difference(_segmentStart!);
      _segmentStart = null;
    }
    _stopListening();
    status = TrackingStatus.idle;
    isPaused = false;
    notifyListeners();
  }

  /// Stops tracking and returns a snapshot of the recorded session, or
  /// `null` if no GPS fix was ever received (nothing worth saving).
  FinishedSession? finish() {
    stop();
    if (_recordedPositions.isEmpty || _sessionStartedAt == null) return null;

    final totalSeconds = elapsed.inSeconds;
    final distanceKm = _totalDistanceMeters / 1000;
    final avgSpeedMps = totalSeconds > 0
        ? _totalDistanceMeters / totalSeconds
        : 0.0;
    final avgPaceSecondsPerKm = distanceKm > 0
        ? totalSeconds / distanceKm
        : 0.0;
    final hours = totalSeconds / 3600;
    final calories = (_activityType!.met * _assumedWeightKg * hours).round();

    return FinishedSession(
      activityType: _activityType!,
      startTime: _sessionStartedAt!,
      endTime: DateTime.now(),
      duration: Duration(seconds: totalSeconds),
      distanceMeters: _totalDistanceMeters,
      avgSpeedMps: avgSpeedMps,
      avgPaceSecondsPerKm: avgPaceSecondsPerKm,
      calories: calories,
      positions: List.unmodifiable(_recordedPositions),
    );
  }

  /// Stops tracking and discards all in-memory recording data. Use this when
  /// the user cancels instead of finishing an activity.
  void cancel() {
    stop();
    _recordedPositions.clear();
    _totalDistanceMeters = 0;
    _sessionStartedAt = null;
  }

  void _startListening() {
    _positionSubscription = _locationService
        .watchPosition(distanceFilter: _distanceFilter)
        .listen(
          (position) {
            if (currentPosition != null) {
              _totalDistanceMeters += Geolocator.distanceBetween(
                currentPosition!.latitude,
                currentPosition!.longitude,
                position.latitude,
                position.longitude,
              );
            }
            currentPosition = position;
            _recordedPositions.add(position);
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = 'GPS error: $error';
            notifyListeners();
          },
        );
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  void _stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
