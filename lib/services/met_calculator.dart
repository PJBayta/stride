import '../models/activity_type.dart';

/// Converts real-time GPS speed into a MET value and accumulates
/// calorie burn over the course of a tracking session.
///
/// ## How it works
/// 1. Every GPS update calls [update] with the raw speed and the
///    elapsed seconds since the previous update.
/// 2. The raw speed is smoothed by a lightweight moving average
///    over the last [_windowSize] samples to suppress GPS spikes.
/// 3. The smoothed speed selects a MET from a speed→MET lookup
///    table that differs by [ActivityType].
/// 4. Calories for the interval are accumulated:
///      calories += MET × weightKg × (intervalSeconds / 3600)
///
/// ## Extending later
/// Swap [_smoothedSpeedKph] with a Kalman-filtered value by
/// replacing the `_speedSamples` moving-average block — the rest
/// of the class is unaffected.
class MetCalculator {
  MetCalculator({
    required this.activityType,
    this.weightKg = 70.0,
  });

  final ActivityType activityType;
  final double weightKg;

  // Moving average window — 5 samples balances responsiveness
  // against GPS noise without adding noticeable lag.
  static const int _windowSize = 5;
  final List<double> _speedSamples = [];

  double _accumulatedCalories = 0.0;

  /// Total calories burned so far, rounded to the nearest kcal.
  int get calories => _accumulatedCalories.round();

  /// Feed a new GPS update into the calculator.
  ///
  /// [rawSpeedMps] — speed reported by geolocator, in m/s.
  /// [intervalSeconds] — seconds elapsed since the previous call.
  void update({
    required double rawSpeedMps,
    required double intervalSeconds,
  }) {
    if (intervalSeconds <= 0) return;

    // --- Speed smoothing (moving average) ---
    final rawKph = rawSpeedMps * 3.6;
    _speedSamples.add(rawKph);
    if (_speedSamples.length > _windowSize) {
      _speedSamples.removeAt(0);
    }
    final smoothedKph =
        _speedSamples.reduce((a, b) => a + b) / _speedSamples.length;

    // --- MET lookup ---
    final met = _metForSpeed(smoothedKph);

    // --- Calorie accumulation ---
    // Calories = MET × weight(kg) × duration(hours)
    _accumulatedCalories += met * weightKg * (intervalSeconds / 3600.0);
  }

  /// Resets the calculator for a new session.
  void reset() {
    _speedSamples.clear();
    _accumulatedCalories = 0.0;
  }

  /// Returns the MET value for the given smoothed speed (km/h)
  /// using the activity-specific lookup table.
  double _metForSpeed(double kph) {
    switch (activityType) {
      case ActivityType.bike:
        if (kph < 16.0) return 4.0;
        if (kph < 19.0) return 6.8;
        if (kph < 22.5) return 8.0;
        return 10.0;

      case ActivityType.run:
      case ActivityType.walk:
        if (kph < 4.0) return 2.8;
        if (kph < 5.5) return 3.5;
        if (kph < 6.5) return 4.3;
        if (kph < 8.0) return 6.0;
        if (kph < 10.0) return 8.3;
        return 9.8;
    }
  }
}