import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/location_service.dart';

enum TrackingStatus { idle, tracking, error }

/// Owns GPS tracking state for a single live session: permission/service
/// checks, the position stream, and an elapsed-time stopwatch.
///
/// Deliberately holds no reference to Flutter widgets or BuildContext, and
/// has no dependency on activity persistence, so Phase 5's activity
/// recording can reuse it unchanged.
class TrackingController extends ChangeNotifier {
  TrackingController({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  Duration _accumulated = Duration.zero;
  DateTime? _segmentStart;

  TrackingStatus status = TrackingStatus.idle;
  Position? currentPosition;
  bool isPaused = false;
  String? errorMessage;

  bool get isTracking => status == TrackingStatus.tracking;

  /// Total time spent tracking, excluding any paused duration.
  Duration get elapsed => _segmentStart == null
      ? _accumulated
      : _accumulated + DateTime.now().difference(_segmentStart!);

  /// Requests location access and, if granted, starts listening to the GPS
  /// stream and the elapsed timer. On failure, sets [status] to
  /// [TrackingStatus.error] and [errorMessage] with a user-facing reason.
  Future<void> start() async {
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

    _accumulated = Duration.zero;
    _segmentStart = DateTime.now();
    isPaused = false;
    errorMessage = null;
    status = TrackingStatus.tracking;
    _startListening();
    notifyListeners();
  }

  /// Pauses the GPS stream and timer without losing elapsed time so far.
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

  /// Stops listening to the GPS stream and timer for good.
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

  void _startListening() {
    _positionSubscription = _locationService.watchPosition().listen(
      (position) {
        currentPosition = position;
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
