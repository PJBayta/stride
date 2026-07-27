import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import '../../../core/format.dart';
import '../../../models/activity_type.dart';
import '../../../models/finished_session.dart';
import '../../../models/measurement_unit.dart';
import '../../../services/kalman_location_filter.dart';
import '../../../services/location_service.dart';
import '../../../services/met_calculator.dart';
import '../../../services/step_counter_service.dart';
import '../../../services/tracking_notification_service.dart';
import '../../settings/controller/settings_controller.dart';

enum TrackingStatus { idle, tracking, error }

/// Default body weight in kg used for calorie estimation.
/// Replace with a real per-user value once Settings/Profile exposes one.
const _defaultWeightKg = 70.0;

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
  final KalmanLocationFilter _kalmanFilter = KalmanLocationFilter();
  final StepCounterService _stepCounterService = StepCounterService();

  // Initialised in start() once the activity type is known.
  late MetCalculator _metCalculator;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStart;
  DateTime? _sessionStartedAt;

  // Timestamp of the last accepted GPS fix, used to compute per-interval
  // elapsed time for incremental calorie accumulation.
  DateTime? _lastPositionTime;

  ActivityType? _activityType;
  int _distanceFilter = 2;

  final List<Position> _recordedPositions = [];
  double _totalDistanceMeters = 0;

  TrackingStatus status = TrackingStatus.idle;
  Position? currentPosition;
  bool isPaused = false;
  String? errorMessage;

  bool get isTracking => status == TrackingStatus.tracking;

  /// The active activity type being tracked, or null if idle.
  ActivityType? get activityType => _activityType;

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
    _lastPositionTime = null;
    _kalmanFilter.reset();

    // Initialise a fresh MetCalculator for this session.
    _metCalculator = MetCalculator(
      activityType: activityType,
      weightKg: _defaultWeightKg,
    );

    isPaused = false;
    errorMessage = null;
    status = TrackingStatus.tracking;

    // Only count steps for foot-based activities (run, walk).
    // Bike sessions produce no footsteps, so we skip the sensor entirely.
    if (_activityType != ActivityType.bike) {
      _stepCounterService.startListening();
    }

    _startListening();
    TrackingNotificationService.start(activityType);
    _updateNotification();
    notifyListeners();
  }

  /// Pauses the GPS stream and timer without losing elapsed time or the
  /// route recorded so far.
  void pause() {
    if (status != TrackingStatus.tracking || isPaused) return;
    _accumulated += DateTime.now().difference(_segmentStart!);
    _segmentStart = null;
    _lastPositionTime = null; // Reset interval timer — no GPS while paused.
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
    TrackingNotificationService.stop();
    _kalmanFilter.reset();
    status = TrackingStatus.idle;
    isPaused = false;
    notifyListeners();
  }

  /// Stops tracking and returns a snapshot of the recorded session, or
  /// `null` if no GPS fix was ever received (nothing worth saving).
  FinishedSession? finish() {
    // Bike activities don't involve footsteps — return 0 and skip sensor.
    final int steps = _activityType == ActivityType.bike
        ? 0
        : _stepCounterService.stopAndCalculateSteps(
            totalDistanceMeters: _totalDistanceMeters,
          );

    // Capture accumulated calories before stop() clears session state.
    final int calories = _metCalculator.calories;

    stop();
    if (_recordedPositions.isEmpty || _sessionStartedAt == null) return null;

    final int totalSeconds = elapsed.inSeconds;
    final double distanceKm = _totalDistanceMeters / 1000.0;
    final double avgSpeedMps = totalSeconds > 0
        ? _totalDistanceMeters / totalSeconds.toDouble()
        : 0.0;
    final double avgPaceSecondsPerKm = distanceKm > 0
        ? totalSeconds.toDouble() / distanceKm
        : 0.0;

    return FinishedSession(
      activityType: _activityType!,
      startTime: _sessionStartedAt!,
      endTime: DateTime.now(),
      duration: Duration(seconds: totalSeconds),
      distanceMeters: _totalDistanceMeters,
      avgSpeedMps: avgSpeedMps,
      avgPaceSecondsPerKm: avgPaceSecondsPerKm,
      calories: calories,
      steps: steps,
      positions: List.unmodifiable(_recordedPositions),
    );
  }

  /// Stops tracking and discards all in-memory recording data. Use this when
  /// the user cancels instead of finishing an activity.
  void cancel() {
    if (_activityType != ActivityType.bike) {
      _stepCounterService.stopAndCalculateSteps(totalDistanceMeters: 0);
    }
    stop();
    _recordedPositions.clear();
    _totalDistanceMeters = 0;
    _sessionStartedAt = null;
    _lastPositionTime = null;
    _kalmanFilter.reset();
    _metCalculator.reset();
  }

  void _updateNotification() {
    if (_activityType == null) return;
    final MeasurementUnit units = settingsController.measurementUnit;
    final double distVal = units.distanceFromMeters(_totalDistanceMeters);
    final String distText =
        '${distVal.toStringAsFixed(2)} ${units.distanceLabel}';
    final String durText = formatDuration(elapsed);

    final double speedMps = currentPosition?.speed ?? 0.0;
    final double speedVal = units.speedFromMetersPerSecond(speedMps);
    final String speedText =
        '${speedVal.toStringAsFixed(1)} ${units.speedLabel}';

    TrackingNotificationService.update(
      activityType: _activityType!,
      durationText: durText,
      distanceText: distText,
      speedOrPaceText: speedText,
    );
  }

  void _startListening() {
    _positionSubscription = _locationService
        .watchPosition(distanceFilter: _distanceFilter)
        .listen(
          (rawPosition) {
            final position = _kalmanFilter.process(rawPosition);
            if (position == null) return; // Outlier discarded

            if (currentPosition != null) {
              _totalDistanceMeters += Geolocator.distanceBetween(
                currentPosition!.latitude,
                currentPosition!.longitude,
                position.latitude,
                position.longitude,
              );
            }

            // Accumulate speed-based calories for this GPS interval.
            final now = DateTime.now();
            final double intervalSeconds = _lastPositionTime != null
                ? now.difference(_lastPositionTime!).inMilliseconds / 1000.0
                : 0.0;
            _lastPositionTime = now;

            _metCalculator.update(
              rawSpeedMps: position.speed.clamp(0.0, double.infinity),
              intervalSeconds: intervalSeconds,
            );

            currentPosition = position;
            _recordedPositions.add(position);
            _updateNotification();
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = 'GPS error: $error';
            notifyListeners();
          },
        );
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateNotification();
        notifyListeners();
      },
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

TrackingController? _trackingControllerInstance;

/// The single [TrackingController] instance used by the app.
TrackingController get trackingController =>
    _trackingControllerInstance ??= TrackingController();
